package com.cstore.app;

import static org.hamcrest.Matchers.startsWith;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.*;

import com.cstore.app.security.FacebookIdentityVerifier;
import com.cstore.app.security.GoogleIdentityVerifier;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.source.ImmutableJWKSet;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jose.jws.SignatureAlgorithm;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.server.ResponseStatusException;

class SocialTokenVerificationTest {
  private static final String CLIENT = "web-client.apps.googleusercontent.com";
  private KeyPair key;
  private GoogleIdentityVerifier google;
  private RestTemplate http;
  private MockRestServiceServer server;
  private FacebookIdentityVerifier facebook;

  @BeforeEach
  void setup() throws Exception {
    var generator = KeyPairGenerator.getInstance("RSA");
    generator.initialize(2048);
    key = generator.generateKeyPair();
    google =
        new GoogleIdentityVerifier(
            CLIENT, NimbusJwtDecoder.withPublicKey((RSAPublicKey) key.getPublic()).build());
    http = GoogleIdentityVerifier.http();
    server = MockRestServiceServer.createServer(http);
    facebook = new FacebookIdentityVerifier("12345", "server-only-secret", "v25.0", http);
  }

  private String token(
      KeyPair signingKey, String audience, String issuer, boolean verified, Instant expiry) {
    var rsa =
        new RSAKey.Builder((RSAPublicKey) signingKey.getPublic())
            .privateKey((RSAPrivateKey) signingKey.getPrivate())
            .build();
    var encoder = new NimbusJwtEncoder(new ImmutableJWKSet<>(new JWKSet(rsa)));
    var claims =
        JwtClaimsSet.builder()
            .issuer(issuer)
            .subject("google-stable-subject")
            .audience(List.of(audience))
            .issuedAt(expiry.minusSeconds(300))
            .expiresAt(expiry)
            .claim("email", "verified@example.com")
            .claim("email_verified", verified)
            .claim("name", "Test user")
            .build();
    return encoder
        .encode(JwtEncoderParameters.from(JwsHeader.with(SignatureAlgorithm.RS256).build(), claims))
        .getTokenValue();
  }

  private void unauthorized(Runnable action) {
    assertEquals(
        HttpStatus.UNAUTHORIZED,
        assertThrows(ResponseStatusException.class, action::run).getStatusCode());
  }

  @Test
  void acceptsSignedGoogleIdentityWithMatchingAudience() {
    var user =
        google.verify(
            token(
                key, CLIENT, "https://accounts.google.com", true, Instant.now().plusSeconds(300)));
    assertEquals("google-stable-subject", user.subject());
    assertEquals("verified@example.com", user.email());
  }

  @Test
  void rejectsGoogleWrongAudienceIssuerUnverifiedEmailAndExpiredToken() {
    unauthorized(() ->
        google.verify(
            token(
                key,
                "other-client",
                "https://accounts.google.com",
                true,
                Instant.now().plusSeconds(300))));
    unauthorized(() ->
        google.verify(
            token(key, CLIENT, "https://attacker.example", true, Instant.now().plusSeconds(300))));
    unauthorized(() ->
        google.verify(
            token(
                key,
                CLIENT,
                "https://accounts.google.com",
                false,
                Instant.now().plusSeconds(300))));
    unauthorized(() ->
        google.verify(
            token(
                key,
                CLIENT,
                "https://accounts.google.com",
                true,
                Instant.now().minusSeconds(120))));
  }

  @Test
  void rejectsGoogleInvalidSignatureAndMalformedToken() throws Exception {
    var generator = KeyPairGenerator.getInstance("RSA");
    generator.initialize(2048);
    unauthorized(() ->
        google.verify(
            token(
                generator.generateKeyPair(),
                CLIENT,
                "https://accounts.google.com",
                true,
                Instant.now().plusSeconds(300))));
    unauthorized(() -> google.verify("not-an-id-token"));
  }

  private String debug(
      String appId, String type, String user, long expires, long dataExpires, boolean valid) {
    return "{\"data\":{\"is_valid\":"
        + valid
        + ",\"app_id\":\""
        + appId
        + "\",\"type\":\""
        + type
        + "\",\"user_id\":\""
        + user
        + "\",\"expires_at\":"
        + expires
        + ",\"data_access_expires_at\":"
        + dataExpires
        + "}}";
  }

  private void expectDebug(String body) {
    server
        .expect(
            requestTo(
                "https://graph.facebook.com/v25.0/debug_token?input_token=facebook-user-token"))
        .andExpect(header("Authorization", "Bearer 12345|server-only-secret"))
        .andRespond(withSuccess(body, MediaType.APPLICATION_JSON));
  }

  @Test
  void verifiesFacebookAppTokenUserAndProfileIdentity() {
    long future = Instant.now().plusSeconds(3600).getEpochSecond();
    expectDebug(debug("12345", "USER", "fb-subject", future, future, true));
    server
        .expect(
            requestTo(
                startsWith(
                    "https://graph.facebook.com/v25.0/me?fields=id,name,email&appsecret_proof=")))
        .andExpect(header("Authorization", "Bearer facebook-user-token"))
        .andRespond(
            withSuccess(
                "{\"id\":\"fb-subject\",\"email\":\"facebook@example.com\",\"name\":\"Facebook"
                    + " user\"}",
                MediaType.APPLICATION_JSON));
    assertEquals("fb-subject", facebook.verify("facebook-user-token").subject());
    server.verify();
  }

  @Test
  void rejectsFacebookTokenFromAnotherAppBeforeReadingProfile() {
    long future = Instant.now().plusSeconds(3600).getEpochSecond();
    expectDebug(debug("other-app", "USER", "fb-subject", future, future, true));
    unauthorized(() -> facebook.verify("facebook-user-token"));
    server.verify();
  }

  @Test
  void rejectsExpiredFacebookDataAccess() {
    expectDebug(
        debug(
            "12345",
            "USER",
            "fb-subject",
            Instant.now().plusSeconds(3600).getEpochSecond(),
            1,
            true));
    unauthorized(() -> facebook.verify("facebook-user-token"));
    server.verify();
  }

  @Test
  void rejectsInvalidFacebookTokenAppTokenAndExpiredAccess() {
    long future = Instant.now().plusSeconds(3600).getEpochSecond();
    for (String response :
        List.of(
            debug("12345", "USER", "fb-subject", future, future, false),
            debug("12345", "APP", "fb-subject", future, future, true),
            debug("12345", "USER", "fb-subject", 1, future, true))) {
      server.reset();
      expectDebug(response);
      unauthorized(() -> facebook.verify("facebook-user-token"));
      server.verify();
    }
  }

  @Test
  void rejectsFacebookProfileSubjectMismatch() {
    long future = Instant.now().plusSeconds(3600).getEpochSecond();
    expectDebug(debug("12345", "USER", "fb-subject", future, future, true));
    server
        .expect(requestTo(startsWith("https://graph.facebook.com/v25.0/me?")))
        .andRespond(
            withSuccess(
                "{\"id\":\"someone-else\",\"email\":\"facebook@example.com\"}",
                MediaType.APPLICATION_JSON));
    unauthorized(() -> facebook.verify("facebook-user-token"));
    server.verify();
  }

  @Test
  void facebookMissingEmailGivesActionableError() {
    long future = Instant.now().plusSeconds(3600).getEpochSecond();
    expectDebug(debug("12345", "USER", "fb-subject", future, future, true));
    server
        .expect(requestTo(startsWith("https://graph.facebook.com/v25.0/me?")))
        .andRespond(
            withSuccess(
                "{\"id\":\"fb-subject\",\"name\":\"No email\"}", MediaType.APPLICATION_JSON));
    assertEquals(
        HttpStatus.BAD_REQUEST,
        assertThrows(ResponseStatusException.class, () -> facebook.verify("facebook-user-token"))
            .getStatusCode());
    server.verify();
  }

  @Test
  void disabledProvidersFailBeforeAnyNetworkRequest() {
    assertEquals(
        HttpStatus.SERVICE_UNAVAILABLE,
        assertThrows(
                ResponseStatusException.class,
                () ->
                    new GoogleIdentityVerifier(
                            "",
                            token -> {
                              throw new AssertionError("Unexpected network");
                            })
                        .verify("token"))
            .getStatusCode());
    assertEquals(
        HttpStatus.SERVICE_UNAVAILABLE,
        assertThrows(
                ResponseStatusException.class,
                () -> new FacebookIdentityVerifier("", "", "v25.0", http).verify("token"))
            .getStatusCode());
    server.verify();
  }
}
