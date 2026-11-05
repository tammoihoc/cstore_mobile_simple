package com.cstore.app;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.cstore.app.dto.VerifiedSocialIdentity;
import com.cstore.app.entity.AppUser;
import com.cstore.app.entity.Role;
import com.cstore.app.repository.SocialIdentities;
import com.cstore.app.repository.Users;
import com.cstore.app.security.FacebookIdentityVerifier;
import com.cstore.app.security.GoogleIdentityVerifier;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest(
    properties = {
      "spring.datasource.url=jdbc:h2:mem:social-test;MODE=MySQL;DB_CLOSE_DELAY=-1",
      "spring.datasource.username=sa",
      "spring.datasource.password=",
      "spring.jpa.hibernate.ddl-auto=create-drop",
      "JWT_SECRET=test-only-signing-key-at-least-thirty-two-characters",
      "ADMIN_EMAIL=",
      "ADMIN_PASSWORD="
    })
@AutoConfigureMockMvc
class SocialLoginFlowTest {
  @Autowired MockMvc mvc;
  @Autowired ObjectMapper json;
  @Autowired Users users;
  @Autowired SocialIdentities identities;
  @Autowired PasswordEncoder passwords;
  @MockBean GoogleIdentityVerifier google;
  @MockBean FacebookIdentityVerifier facebook;

  @BeforeEach
  void configure() {
    when(google.enabled()).thenReturn(true);
    when(facebook.enabled()).thenReturn(true);
  }

  @Test
  void anonymousConfigurationDoesNotExposeSecrets() throws Exception {
    mvc.perform(get("/api/auth/providers"))
        .andExpect(status().isOk())
        .andExpect(content().json("{\"google\":true,\"facebook\":true}"));
  }

  @Test
  void verifiedIdentityCreatesCustomerAndCannotUseLocalPassword() throws Exception {
    String email = UUID.randomUUID() + "@test.local", subject = UUID.randomUUID().toString();
    when(google.verify("verified-token"))
        .thenReturn(new VerifiedSocialIdentity(subject, email, "Google customer"));
    String result =
        mvc.perform(
                post("/api/auth/social")
                    .contentType("application/json")
                    .content(
                        json.writeValueAsString(
                            Map.of(
                                "provider",
                                "google",
                                "token",
                                "verified-token",
                                "role",
                                "ADMIN",
                                "email",
                                "attacker@test.local"))))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.user.email").value(email))
            .andExpect(jsonPath("$.user.role").value("CUSTOMER"))
            .andExpect(jsonPath("$.token").isString())
            .andReturn()
            .getResponse()
            .getContentAsString();
    String token = json.readTree(result).get("token").asText();
    mvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + token))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.email").value(email));
    mvc.perform(
            post("/api/auth/login")
                .contentType("application/json")
                .content(
                    json.writeValueAsString(
                        Map.of("email", email, "password", "!SOCIAL_LOGIN_ONLY!"))))
        .andExpect(status().isUnauthorized());
    assertEquals(Role.CUSTOMER, users.findByEmailIgnoreCase(email).orElseThrow().role);
  }

  @Test
  void repeatedLoginUsesProviderSubjectEvenWhenProviderEmailChanges() throws Exception {
    String email = UUID.randomUUID() + "@test.local", subject = UUID.randomUUID().toString();
    when(facebook.verify("first-token"))
        .thenReturn(new VerifiedSocialIdentity(subject, email, "Facebook customer"));
    mvc.perform(
            post("/api/auth/social")
                .contentType("application/json")
                .content("{\"provider\":\"facebook\",\"token\":\"first-token\"}"))
        .andExpect(status().isOk());
    Long userId = users.findByEmailIgnoreCase(email).orElseThrow().id;
    when(facebook.verify("second-token"))
        .thenReturn(
            new VerifiedSocialIdentity(subject, UUID.randomUUID() + "@test.local", "Changed name"));
    mvc.perform(
            post("/api/auth/social")
                .contentType("application/json")
                .content("{\"provider\":\"facebook\",\"token\":\"second-token\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.user.id").value(userId))
        .andExpect(jsonPath("$.user.email").value(email));
  }

  @Test
  void existingEmailWithDifferentProviderLinksToSameAccount() throws Exception {
    String email = UUID.randomUUID() + "@test.local";
    String googleSubject = UUID.randomUUID().toString();
    String fbSubject = UUID.randomUUID().toString();
    when(google.verify("google-token"))
        .thenReturn(new VerifiedSocialIdentity(googleSubject, email, "Google customer"));
    when(facebook.verify("fb-token"))
        .thenReturn(new VerifiedSocialIdentity(fbSubject, email, "Facebook customer"));

    String firstResult =
        mvc.perform(
                post("/api/auth/social")
                    .contentType("application/json")
                    .content("{\"provider\":\"google\",\"token\":\"google-token\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.user.email").value(email))
            .andReturn()
            .getResponse()
            .getContentAsString();
    Long userId = json.readTree(firstResult).get("user").get("id").asLong();

    mvc.perform(
            post("/api/auth/social")
                .contentType("application/json")
                .content("{\"provider\":\"facebook\",\"token\":\"fb-token\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.user.id").value(userId))
        .andExpect(jsonPath("$.user.email").value(email));

    assertEquals(
        userId, identities.findByProviderAndSubject("google", googleSubject).orElseThrow().user.id);
    assertEquals(
        userId, identities.findByProviderAndSubject("facebook", fbSubject).orElseThrow().user.id);
  }

  @Test
  void rejectedTokensAndUnknownProvidersCannotCreateAnAccount() throws Exception {
    long before = users.count();
    when(google.verify("forged-token")).thenThrow(GoogleIdentityVerifier.invalid());
    mvc.perform(
            post("/api/auth/social")
                .contentType("application/json")
                .content("{\"provider\":\"google\",\"token\":\"forged-token\"}"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.token").doesNotExist());
    mvc.perform(
            post("/api/auth/social")
                .contentType("application/json")
                .content("{\"provider\":\"unknown\",\"token\":\"forged-token\"}"))
        .andExpect(status().isBadRequest());
    assertEquals(before, users.count());
  }

  @Test
  void blockedSocialAccountCannotCreateANewSession() throws Exception {
    String email = UUID.randomUUID() + "@blocked-social.local",
        subject = UUID.randomUUID().toString();
    AppUser user = new AppUser(email, "!SOCIAL_LOGIN_ONLY!", "Blocked", Role.CUSTOMER);
    user.blocked = true;
    users.save(user);
    when(google.verify("blocked-social-token"))
        .thenReturn(new VerifiedSocialIdentity(subject, email, "Blocked"));
    mvc.perform(
            post("/api/auth/social")
                .contentType("application/json")
                .content("{\"provider\":\"google\",\"token\":\"blocked-social-token\"}"))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.token").doesNotExist());
  }
}
