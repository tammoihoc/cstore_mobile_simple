package com.cstore.app;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;

import com.cstore.app.entity.AppUser;
import com.cstore.app.entity.Role;
import com.cstore.app.entity.Store;
import com.cstore.app.repository.Stores;
import com.cstore.app.repository.Users;
import com.fasterxml.jackson.databind.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.util.*;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

@SpringBootTest(
    properties = {
      "spring.datasource.url=jdbc:h2:mem:profile-test;MODE=MySQL;DB_CLOSE_DELAY=-1",
      "spring.datasource.username=sa",
      "spring.datasource.password=",
      "spring.jpa.hibernate.ddl-auto=create-drop",
      "JWT_SECRET=profile-test-signing-key-thirty-two-characters-long",
      "ADMIN_EMAIL=",
      "ADMIN_PASSWORD=",
      "UPLOAD_DIR=/tmp/cstore-profile-test-uploads"
    })
@AutoConfigureMockMvc
class ProfileFlowTest {
  @Autowired jakarta.persistence.EntityManagerFactory entityManagers;
  @Autowired MockMvc mvc;
  @Autowired ObjectMapper json;
  @Autowired Users users;
  @Autowired Stores stores;
  @Autowired PasswordEncoder passwords;

  record Actor(Long id, String email, String token) {}

  Actor actor(Role role) throws Exception {
    var u =
        users.save(
            new AppUser(
                UUID.randomUUID() + "@profile-test.local",
                passwords.encode("Testing-password-123"),
                "QA profile",
                role));
    return new Actor(
        u.id,
        u.email,
        call(
                post("/api/auth/login"),
                null,
                Map.of("email", u.email, "password", "Testing-password-123"),
                200)
            .get("token")
            .asText());
  }

  JsonNode call(MockHttpServletRequestBuilder req, String token, Object body, int status)
      throws Exception {
    if (token != null) req.header("Authorization", "Bearer " + token);
    if (body != null) req.contentType("application/json").content(json.writeValueAsString(body));
    var response = mvc.perform(req).andReturn().getResponse();
    assertEquals(status, response.getStatus());
    return response.getContentAsString().isEmpty()
        ? json.nullNode()
        : json.readTree(response.getContentAsString());
  }

  byte[] png() throws Exception {
    var bytes = new ByteArrayOutputStream();
    ImageIO.write(new BufferedImage(16, 16, BufferedImage.TYPE_INT_RGB), "png", bytes);
    return bytes.toByteArray();
  }

  @Test
  void customerProfilePersistsAndCannotChangeAnotherAccount() throws Exception {
    var a = actor(Role.CUSTOMER);
    var b = actor(Role.CUSTOMER);
    var initial = call(get("/api/account/profile"), a.token, null, 200);
    assertTrue(initial.get("avatar").isNull());
    assertFalse(initial.get("photoRequired").asBoolean());
    assertNotNull(initial.get("createdAt"));
    assertFalse(initial.get("createdAt").isNull());
    var saved =
        call(
            put("/api/account/profile"),
            a.token,
            Map.of("name", "  Nguyễn QA  ", "phone", "0901234567", "gender", "FEMALE", "id", b.id),
            200);
    assertEquals(initial.get("createdAt"), saved.get("createdAt"));
    assertEquals("Nguyễn QA", saved.get("name").asText());
    assertEquals("FEMALE", saved.get("gender").asText());
    assertEquals("0901234567", saved.get("phone").asText());
    assertEquals(
        "QA profile", call(get("/api/account/profile"), b.token, null, 200).get("name").asText());
    call(put("/api/account/profile"), a.token, Map.of("name", "QA", "gender", "INVALID"), 400);
    call(put("/api/account/profile"), a.token, Map.of("name", "QA", "phone", "not-a-phone"), 400);
  }

  @Test
  void shipperMustUploadPhotoBeforeGoingOnlineAndCustomerCanRemovePhoto() throws Exception {
    var shipper = actor(Role.SHIPPER);
    var location = Map.of("online", true, "latitude", 10.7731, "longitude", 106.703);
    assertTrue(
        call(get("/api/account/profile"), shipper.token, null, 200)
            .get("photoRequired")
            .asBoolean());
    call(put("/api/shipper/location"), shipper.token, location, 400);
    call(
        multipart("/api/account/avatar")
            .file(new MockMultipartFile("file", "bad.svg", "image/svg+xml", "<svg/>".getBytes())),
        shipper.token,
        null,
        400);
    var saved =
        call(
            multipart("/api/account/avatar")
                .file(new MockMultipartFile("file", "portrait.png", "image/png", png())),
            shipper.token,
            null,
            200);
    assertFalse(saved.get("photoRequired").asBoolean());
    assertEquals(
        200, mvc.perform(get(saved.get("avatar").asText())).andReturn().getResponse().getStatus());
    call(put("/api/shipper/location"), shipper.token, location, 200);
    call(delete("/api/account/avatar"), shipper.token, null, 400);
    var customer = actor(Role.CUSTOMER);
    call(
        multipart("/api/account/avatar")
            .file(new MockMultipartFile("file", "portrait.png", "image/png", png())),
        customer.token,
        null,
        200);
    assertTrue(
        call(delete("/api/account/avatar"), customer.token, null, 200).get("avatar").isNull());
  }

  @Test
  void storeAccountsUseBrandLogoAndAdminCanUploadShipperPortrait() throws Exception {
    var owner = actor(Role.STORE);
    var u = users.findById(owner.id).orElseThrow();
    var store = new Store("Brand", u);
    store.image = "/api/images/brand-logo.png";
    store = stores.save(store);
    u.assignedStore = store;
    users.save(u);
    assertEquals(
        store.image,
        call(get("/api/account/profile"), owner.token, null, 200).get("avatar").asText());
    call(
        multipart("/api/account/avatar")
            .file(new MockMultipartFile("file", "portrait.png", "image/png", png())),
        owner.token,
        null,
        400);
    var shipper = actor(Role.SHIPPER);
    var admin = actor(Role.ADMIN);
    call(
        multipart("/api/admin/accounts/" + shipper.id + "/avatar")
            .file(new MockMultipartFile("file", "portrait.png", "image/png", png())),
        owner.token,
        null,
        403);
    assertFalse(
        call(
                multipart("/api/admin/accounts/" + shipper.id + "/avatar")
                    .file(new MockMultipartFile("file", "portrait.png", "image/png", png())),
                admin.token,
                null,
                200)
            .get("photoRequired")
            .asBoolean());
  }

  @Test
  void passwordChangeVerifiesCurrentAndRevokesOtherSessions() throws Exception {
    var user = actor(Role.CUSTOMER);
    var other = actor(Role.CUSTOMER);
    call(
        put("/api/account/password"),
        user.token,
        Map.of("currentPassword", "wrong-password", "newPassword", "New-testing-password-456"),
        400);
    call(
        put("/api/account/password"),
        user.token,
        Map.of("currentPassword", "Testing-password-123", "newPassword", "Testing-password-123"),
        400);
    call(
        put("/api/account/password"),
        user.token,
        Map.of("currentPassword", "Testing-password-123", "newPassword", "short"),
        400);
    call(
        put("/api/account/password"),
        user.token,
        Map.of("currentPassword", "Testing-password-123", "newPassword", "ế".repeat(30)),
        400);
    var changed =
        call(
            put("/api/account/password"),
            user.token,
            Map.of(
                "currentPassword",
                "Testing-password-123",
                "newPassword",
                "New-testing-password-456"),
            200);
    call(get("/api/account/profile"), user.token, null, 401);
    call(get("/api/account/profile"), changed.get("token").asText(), null, 200);
    call(get("/api/account/profile"), other.token, null, 200);
    call(
        post("/api/auth/login"),
        null,
        Map.of("email", user.email, "password", "Testing-password-123"),
        401);
    call(
        post("/api/auth/login"),
        null,
        Map.of("email", user.email, "password", "New-testing-password-456"),
        200);
  }

  @Test
  void staleLocationUpdateCannotUndoPasswordOrRevocation() throws Exception {
    var user = actor(Role.SHIPPER);
    var stale = entityManagers.createEntityManager();
    try {
      stale.getTransaction().begin();
      var old = stale.find(AppUser.class, user.id);
      var changed =
          call(
              put("/api/account/password"),
              user.token,
              Map.of(
                  "currentPassword",
                  "Testing-password-123",
                  "newPassword",
                  "New-testing-password-456"),
              200);
      old.latitude = 10.7731;
      old.longitude = 106.703;
      stale.getTransaction().commit();
      call(get("/api/account/profile"), user.token, null, 401);
      call(get("/api/account/profile"), changed.get("token").asText(), null, 200);
      call(
          post("/api/auth/login"),
          null,
          Map.of("email", user.email, "password", "Testing-password-123"),
          401);
      call(
          post("/api/auth/login"),
          null,
          Map.of("email", user.email, "password", "New-testing-password-456"),
          200);
    } finally {
      if (stale.getTransaction().isActive()) stale.getTransaction().rollback();
      stale.close();
    }
  }
}
