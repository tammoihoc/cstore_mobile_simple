package com.cstore.app;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.cstore.app.entity.AppUser;
import com.cstore.app.entity.Role;
import com.cstore.app.repository.Users;
import com.fasterxml.jackson.databind.*;
import java.util.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest(
    properties = {
      "spring.datasource.url=jdbc:h2:mem:account-test;MODE=MySQL;DB_CLOSE_DELAY=-1",
      "spring.datasource.username=sa",
      "spring.datasource.password=",
      "spring.jpa.hibernate.ddl-auto=create-drop",
      "JWT_SECRET=test-only-signing-key-at-least-thirty-two-characters",
      "ADMIN_EMAIL=",
      "ADMIN_PASSWORD="
    })
@AutoConfigureMockMvc
class AccountFlowTest {
  @Autowired MockMvc mvc;
  @Autowired ObjectMapper json;
  @Autowired Users users;
  @Autowired PasswordEncoder encoder;

  String login(Role role) throws Exception {
    String email = UUID.randomUUID() + "@test.local";
    users.save(new AppUser(email, encoder.encode("Test-pass-123"), "Tester", role));
    String body =
        mvc.perform(
                post("/api/auth/login")
                    .contentType("application/json")
                    .content(
                        json.writeValueAsString(
                            Map.of("email", email, "password", "Test-pass-123"))))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.user.role").value(role.name()))
            .andReturn()
            .getResponse()
            .getContentAsString();
    return json.readTree(body).get("token").asText();
  }

  Map<String, Object> store() {
    var body = new HashMap<String, Object>();
    body.put("name", "Chi nhánh A");
    body.put("address", "45 Nguyễn Huệ");
    body.put("latitude", 10.7731);
    body.put("longitude", 106.703);
    body.put("pinConfirmed", true);
    body.put("brand", "C-Store");
    body.put("email", UUID.randomUUID() + "@partner.local");
    body.put("fullName", "Đối tác");
    body.put("password", "Partner-pass-123");
    return body;
  }

  @Test
  void rejectsInvalidCredentialsAndPublicPrivilegedRegistration() throws Exception {
    mvc.perform(
            post("/api/auth/login")
                .contentType("application/json")
                .content("{\"email\":\"missing@test.local\",\"password\":\"wrong\"}"))
        .andExpect(status().isUnauthorized());
    for (String role : List.of("ADMIN", "STORE", "MERCHANT"))
      mvc.perform(
              post("/api/auth/register")
                  .contentType("application/json")
                  .content(
                      json.writeValueAsString(
                          Map.of(
                              "email",
                              UUID.randomUUID() + "@test.local",
                              "password",
                              "Long-pass-123",
                              "fullName",
                              "Test",
                              "role",
                              role))))
          .andExpect(status().isBadRequest());
  }

  @Test
  void onlyAdminCanProvisionPinnedStoreAndLoginResolvesAssignment() throws Exception {
    var body = store();
    String customer = login(Role.CUSTOMER);
    mvc.perform(
            post("/api/admin/stores")
                .header("Authorization", "Bearer " + customer)
                .contentType("application/json")
                .content(json.writeValueAsString(body)))
        .andExpect(status().isForbidden());
    String admin = login(Role.ADMIN);
    body.put("pinConfirmed", false);
    mvc.perform(
            post("/api/admin/stores")
                .header("Authorization", "Bearer " + admin)
                .contentType("application/json")
                .content(json.writeValueAsString(body)))
        .andExpect(status().isBadRequest());
    body.put("pinConfirmed", true);
    body.put("latitude", 91);
    mvc.perform(
            post("/api/admin/stores")
                .header("Authorization", "Bearer " + admin)
                .contentType("application/json")
                .content(json.writeValueAsString(body)))
        .andExpect(status().isBadRequest());
    body.put("latitude", 10.7731);
    String result =
        mvc.perform(
                post("/api/admin/stores")
                    .header("Authorization", "Bearer " + admin)
                    .contentType("application/json")
                    .content(json.writeValueAsString(body)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.role").value("STORE"))
            .andExpect(jsonPath("$.storeId").isNumber())
            .andExpect(jsonPath("$.password").doesNotExist())
            .andReturn()
            .getResponse()
            .getContentAsString();
    long branchId = json.readTree(result).get("storeId").asLong();
    mvc.perform(
            post("/api/auth/login")
                .contentType("application/json")
                .content(
                    json.writeValueAsString(
                        Map.of("email", body.get("email"), "password", body.get("password")))))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.user.storeId").value(branchId));
    AppUser user = users.findByEmailIgnoreCase(body.get("email").toString()).orElseThrow();
    assertNotEquals(body.get("password"), user.passwordHash);
    assertTrue(encoder.matches(body.get("password").toString(), user.passwordHash));
    body.put("existingStoreId", branchId);
    body.put("email", UUID.randomUUID() + "@staff.local");
    mvc.perform(
            post("/api/admin/stores")
                .header("Authorization", "Bearer " + admin)
                .contentType("application/json")
                .content(json.writeValueAsString(body)))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.storeId").value(branchId));
  }
}
