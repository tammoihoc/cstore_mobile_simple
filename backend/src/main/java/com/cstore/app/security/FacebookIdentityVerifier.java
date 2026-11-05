package com.cstore.app.security;

import com.cstore.app.dto.VerifiedSocialIdentity;
import com.fasterxml.jackson.databind.JsonNode;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.HexFormat;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.util.UriComponentsBuilder;

@Component
public class FacebookIdentityVerifier {
  private final String appId, appSecret, version;
  private final RestTemplate http;

  @Autowired
  public FacebookIdentityVerifier(
      @Value("${FACEBOOK_APP_ID:${CSTORE_FACEBOOK_CLIENT_ID:}}") String appId,
      @Value("${FACEBOOK_APP_SECRET:${CSTORE_FACEBOOK_CLIENT_SECRET:}}") String appSecret,
      @Value("${FACEBOOK_GRAPH_VERSION:v25.0}") String version) {
    this(appId, appSecret, version, GoogleIdentityVerifier.http());
  }

  public FacebookIdentityVerifier(
      String appId, String appSecret, String version, RestTemplate http) {
    this.appId = appId.trim();
    this.appSecret = appSecret.trim();
    this.version = version;
    this.http = http;
  }

  public boolean enabled() {
    return appId.matches("[0-9]+") && !appSecret.isBlank() && version.matches("v[0-9]+\\.[0-9]+");
  }

  public VerifiedSocialIdentity verify(String token) {
    if (!enabled()) {
      throw new ResponseStatusException(
          HttpStatus.SERVICE_UNAVAILABLE,
          "Đăng nhập Facebook chưa được cấu hình. Bạn vẫn có thể đăng nhập bằng email.");
    }
    try {
      URI debug =
          endpoint("debug_token")
              .queryParam("input_token", "{token}")
              .encode()
              .buildAndExpand(token)
              .toUri();
      JsonNode result = get(debug, appId + "|" + appSecret);
      JsonNode data = result.path("data");
      long now = Instant.now().getEpochSecond();
      String subject = data.path("user_id").asText("");
      if (!data.path("is_valid").asBoolean(false)
          || !appId.equals(data.path("app_id").asText())
          || !"USER".equals(data.path("type").asText())
          || subject.isBlank()
          || !data.path("expires_at").canConvertToLong()
          || data.path("expires_at").asLong() <= now
          || !data.path("data_access_expires_at").canConvertToLong()
          || data.path("data_access_expires_at").asLong() <= now) {
        throw GoogleIdentityVerifier.invalid();
      }
      URI profile =
          endpoint("me")
              .queryParam("fields", "id,name,email")
              .queryParam("appsecret_proof", proof(token))
              .build()
              .toUri();
      JsonNode user = get(profile, token);
      if (!subject.equals(user.path("id").asText())) {
        throw GoogleIdentityVerifier.invalid();
      }
      String email = user.path("email").asText("");
      if (email.isBlank()) {
        throw new ResponseStatusException(
            HttpStatus.BAD_REQUEST,
            "Facebook chưa chia sẻ email. Hãy cho phép truy cập email hoặc đăng ký bằng email.");
      }
      return GoogleIdentityVerifier.identity(subject, email, user.path("name").asText(""));
    } catch (RestClientException | IllegalArgumentException exception) {
      throw GoogleIdentityVerifier.invalid();
    }
  }

  private UriComponentsBuilder endpoint(String path) {
    return UriComponentsBuilder.fromUriString("https://graph.facebook.com/" + version + "/" + path);
  }

  private JsonNode get(URI uri, String token) {
    HttpHeaders headers = new HttpHeaders();
    headers.setBearerAuth(token);
    JsonNode body =
        http.exchange(uri, HttpMethod.GET, new HttpEntity<>(headers), JsonNode.class).getBody();
    if (body == null || body.has("error")) {
      throw GoogleIdentityVerifier.invalid();
    }
    return body;
  }

  private String proof(String token) {
    try {
      Mac mac = Mac.getInstance("HmacSHA256");
      mac.init(new SecretKeySpec(appSecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
      return HexFormat.of().formatHex(mac.doFinal(token.getBytes(StandardCharsets.UTF_8)));
    } catch (java.security.GeneralSecurityException exception) {
      throw new IllegalStateException("HMAC-SHA256 is unavailable");
    }
  }
}
