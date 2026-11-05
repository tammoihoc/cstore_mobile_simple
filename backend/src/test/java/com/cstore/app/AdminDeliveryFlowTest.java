package com.cstore.app;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;

import com.cstore.app.entity.AppUser;
import com.cstore.app.entity.CustomerOrder;
import com.cstore.app.entity.Role;
import com.cstore.app.entity.Store;
import com.cstore.app.repository.Orders;
import com.cstore.app.repository.Stores;
import com.cstore.app.repository.Users;
import com.fasterxml.jackson.databind.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.time.Instant;
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
      "spring.datasource.url=jdbc:h2:mem:admin-delivery-test;MODE=MySQL;DB_CLOSE_DELAY=-1",
      "spring.datasource.username=sa",
      "spring.datasource.password=",
      "spring.jpa.hibernate.ddl-auto=create-drop",
      "JWT_SECRET=admin-delivery-test-signing-key-thirty-two-characters",
      "ADMIN_EMAIL=",
      "ADMIN_PASSWORD=",
      "UPLOAD_DIR=/tmp/cstore-admin-test-uploads"
    })
@AutoConfigureMockMvc
class AdminDeliveryFlowTest {
  @Autowired MockMvc mvc;
  @Autowired ObjectMapper json;
  @Autowired Users users;
  @Autowired Stores stores;
  @Autowired Orders orders;
  @Autowired PasswordEncoder passwords;

  record Actor(String token, Long id, String email) {}

  Actor actor(Role role) throws Exception {
    String email = UUID.randomUUID() + "@admin-flow.local";
    AppUser user =
        users.save(
            new AppUser(email, passwords.encode("Testing-password-123"), "QA " + role, role));
    String token =
        call(
                post("/api/auth/login"),
                null,
                Map.of("email", email, "password", "Testing-password-123"),
                200)
            .get("token")
            .asText();
    return new Actor(token, user.id, email);
  }

  JsonNode call(MockHttpServletRequestBuilder request, String token, Object body, int expected)
      throws Exception {
    if (token != null) request.header("Authorization", "Bearer " + token);
    if (body != null)
      request.contentType("application/json").content(json.writeValueAsString(body));
    var response = mvc.perform(request).andReturn().getResponse();
    assertEquals(expected, response.getStatus(), response.getContentAsString());
    return response.getContentAsString().isEmpty()
        ? json.nullNode()
        : json.readTree(response.getContentAsString());
  }

  Map<String, Object> store(String brand) {
    var in = new HashMap<String, Object>();
    in.put("brand", brand);
    in.put("address", "45 Nguyễn Huệ");
    in.put("latitude", 10.7731);
    in.put("longitude", 106.703);
    in.put("pinConfirmed", true);
    in.put("email", UUID.randomUUID() + "@branch.local");
    in.put("fullName", "QA owner");
    in.put("password", "Testing-password-123");
    return in;
  }

  @Test
  void confirmedLocationPersistsPerCustomerAndRejectsInvalidPins() throws Exception {
    var buyer = actor(Role.CUSTOMER);
    var other = actor(Role.CUSTOMER);
    var shipper = actor(Role.SHIPPER);
    assertTrue(call(get("/api/customer/location"), buyer.token, null, 200).isNull());
    var location =
        new HashMap<String, Object>(
            Map.of(
                "address",
                "  45 Nguyễn Huệ, TP Hồ Chí Minh  ",
                "latitude",
                10.7732,
                "longitude",
                106.7032,
                "pinConfirmed",
                true));
    call(put("/api/customer/location"), buyer.token, location, 200);
    String newSession =
        call(
                post("/api/auth/login"),
                null,
                Map.of("email", buyer.email, "password", "Testing-password-123"),
                200)
            .get("token")
            .asText();
    var saved = call(get("/api/customer/location"), newSession, null, 200);
    assertEquals("45 Nguyễn Huệ, TP Hồ Chí Minh", saved.get("address").asText());
    assertEquals(10.7732, saved.get("latitude").asDouble());
    assertTrue(saved.get("pinConfirmed").asBoolean());
    assertTrue(call(get("/api/customer/location"), other.token, null, 200).isNull());
    call(put("/api/customer/location"), shipper.token, location, 403);
    location.put("latitude", 91);
    call(put("/api/customer/location"), buyer.token, location, 400);
    location.put("latitude", 10.7732);
    location.put("pinConfirmed", false);
    call(put("/api/customer/location"), buyer.token, location, 400);
    assertEquals(
        10.7732,
        call(get("/api/customer/location"), buyer.token, null, 200).get("latitude").asDouble());
  }

  @Test
  void adminCreatesLocksAndSoftDeletesAccountsAndRevokesExistingToken() throws Exception {
    var admin = actor(Role.ADMIN);
    var customer = actor(Role.CUSTOMER);
    var in =
        new HashMap<String, Object>(
            Map.of(
                "email",
                UUID.randomUUID() + "@created.local",
                "fullName",
                "New shipper",
                "password",
                "Testing-password-123",
                "role",
                "SHIPPER"));
    call(post("/api/admin/accounts"), customer.token, in, 403);
    var created = call(post("/api/admin/accounts"), admin.token, in, 201);
    long id = created.get("id").asLong();
    assertFalse(created.has("password"));
    assertFalse(created.get("blocked").asBoolean());
    String token =
        call(
                post("/api/auth/login"),
                null,
                Map.of("email", in.get("email"), "password", in.get("password")),
                200)
            .get("token")
            .asText();
    call(put("/api/admin/accounts/" + id + "/status"), admin.token, Map.of("blocked", true), 200);
    call(get("/api/auth/me"), token, null, 401);
    call(
        post("/api/auth/login"),
        null,
        Map.of("email", in.get("email"), "password", in.get("password")),
        403);
    call(put("/api/admin/accounts/" + id + "/status"), admin.token, Map.of("blocked", false), 200);
    call(get("/api/auth/me"), token, null, 200);
    call(
        put("/api/admin/accounts/" + admin.id + "/status"),
        admin.token,
        Map.of("blocked", true),
        400);
    call(delete("/api/admin/accounts/" + admin.id), admin.token, null, 400);
    call(delete("/api/admin/accounts/" + id), admin.token, null, 204);
    assertTrue(users.findById(id).orElseThrow().deleted);
    call(get("/api/auth/me"), token, null, 401);
    for (var a : call(get("/api/admin/accounts"), admin.token, null, 200))
      assertNotEquals(id, a.get("id").asLong());
    call(put("/api/admin/accounts/" + id + "/status"), admin.token, Map.of("blocked", false), 404);
    in.put("email", UUID.randomUUID() + "@store-created.local");
    in.put("role", "STORE");
    call(post("/api/admin/accounts"), admin.token, in, 400);
  }

  @Test
  void normalizedBrandRequiresDistinctBranchAndSupportsRealImage() throws Exception {
    var admin = actor(Role.ADMIN);
    String brand = "Fresh " + UUID.randomUUID();
    var first = store(brand);
    long id = call(post("/api/admin/stores"), admin.token, first, 201).get("storeId").asLong();
    assertEquals(brand, stores.findById(id).orElseThrow().name);
    var next = store("  " + brand.toUpperCase(Locale.ROOT) + "  ");
    call(post("/api/admin/stores"), admin.token, next, 409);
    next.put("branchName", "Chi nhánh 2");
    long second = call(post("/api/admin/stores"), admin.token, next, 201).get("storeId").asLong();
    assertNotEquals(id, second);
    next.put("email", UUID.randomUUID() + "@duplicate-branch.local");
    next.put("branchName", "  CHI NHÁNH   2  ");
    call(post("/api/admin/stores"), admin.token, next, 409);
    next.put("brand", "");
    call(post("/api/admin/stores"), admin.token, next, 400);
    var bytes = new ByteArrayOutputStream();
    ImageIO.write(new BufferedImage(12, 12, BufferedImage.TYPE_INT_RGB), "png", bytes);
    var image =
        call(
                multipart("/api/admin/stores/" + id + "/image")
                    .file(
                        new MockMultipartFile(
                            "file", "brand.png", "image/png", bytes.toByteArray())),
                admin.token,
                null,
                200)
            .get("image")
            .asText();
    assertEquals(200, mvc.perform(get(image)).andReturn().getResponse().getStatus());
    assertEquals(image, stores.findById(second).orElseThrow().image);
    var third = store(brand);
    third.put("branchName", "Chi nhánh 3");
    long thirdId = call(post("/api/admin/stores"), admin.token, third, 201).get("storeId").asLong();
    assertEquals(image, stores.findById(thirdId).orElseThrow().image);
    boolean found = false;
    for (var b : call(get("/api/branches"), null, null, 200))
      if (b.get("id").asLong() == id) {
        assertEquals(image, b.get("image").asText());
        found = true;
      }
    assertTrue(found);
    var staff =
        new HashMap<String, Object>(
            Map.of(
                "email",
                UUID.randomUUID() + "@staff.local",
                "fullName",
                "Staff",
                "password",
                "Testing-password-123",
                "role",
                "STORE",
                "storeId",
                id));
    assertEquals(
        id, call(post("/api/admin/accounts"), admin.token, staff, 201).get("storeId").asLong());
  }

  @Test
  void commissionIncludesOnlyDeliveredPaidMerchandiseAndPreservesHistoryAfterAccountDeletion()
      throws Exception {
    var admin = actor(Role.ADMIN);
    var buyer = actor(Role.CUSTOMER);
    var owner = actor(Role.STORE);
    var s =
        stores.save(
            new Store("Revenue " + UUID.randomUUID(), users.findById(owner.id).orElseThrow()));
    s.brand = "Revenue brand";
    s.latitude = 10.7731;
    s.longitude = 106.703;
    stores.save(s);
    seedOrder(buyer.id, s, "DELIVERED", true, 100000);
    seedOrder(buyer.id, s, "DELIVERED", true, 50000);
    seedOrder(buyer.id, s, "DELIVERED", false, 300000);
    seedOrder(buyer.id, s, "ACCEPTED", true, 200000);
    seedOrder(buyer.id, s, "CANCELLED", true, 400000);
    var revenue = call(get("/api/admin/revenue"), admin.token, null, 200);
    JsonNode row = null;
    for (var b : revenue.get("branches")) if (b.get("storeId").asLong() == s.id) row = b;
    assertNotNull(row);
    assertEquals(2, row.get("completedOrders").asInt());
    assertEquals(150000, row.get("grossSales").asInt());
    assertEquals(22500, row.get("platformRevenue").asInt());
    assertEquals(0.15, revenue.get("commissionRate").asDouble());
    call(delete("/api/admin/accounts/" + buyer.id), admin.token, null, 204);
    assertEquals(5, orders.findByCustomerIdOrderByIdDesc(buyer.id).size());
    var after = call(get("/api/admin/revenue"), admin.token, null, 200);
    assertEquals(revenue.get("platformRevenue"), after.get("platformRevenue"));
  }

  void seedOrder(Long buyer, Store store, String status, boolean paid, int subtotal) {
    var o = new CustomerOrder(users.findById(buyer).orElseThrow(), store);
    o.status = status;
    o.total = BigDecimal.valueOf(subtotal);
    o.fee = BigDecimal.valueOf(30000);
    if (paid) o.paidAt = Instant.now();
    orders.save(o);
  }
}
