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
import com.cstore.app.support.BrandNames;
import com.fasterxml.jackson.databind.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

@SpringBootTest(
    properties = {
      "spring.datasource.url=jdbc:h2:mem:brand-admin-test;MODE=MySQL;DB_CLOSE_DELAY=-1",
      "spring.datasource.username=sa",
      "spring.datasource.password=",
      "spring.jpa.hibernate.ddl-auto=create-drop",
      "JWT_SECRET=brand-admin-test-signing-key-thirty-two-characters",
      "ADMIN_EMAIL=",
      "ADMIN_PASSWORD="
    })
@AutoConfigureMockMvc
class BrandAdminFlowTest {
  @Autowired MockMvc mvc;
  @Autowired ObjectMapper json;
  @Autowired Users users;
  @Autowired Stores stores;
  @Autowired Orders orders;
  @Autowired PasswordEncoder passwords;

  record Actor(Long id, String email, String token) {}

  Actor actor(Role role) throws Exception {
    var u =
        users.save(
            new AppUser(
                UUID.randomUUID() + "@brand-test.local",
                passwords.encode("Test-password-123"),
                "QA brand",
                role));
    var session =
        call(
            post("/api/auth/login"),
            null,
            Map.of("email", u.email, "password", "Test-password-123"),
            200);
    return new Actor(u.id, u.email, session.get("token").asText());
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

  Map<String, Object> input(String brand, String branch) {
    var body = new HashMap<String, Object>();
    body.put("brand", brand);
    if (branch != null) body.put("branchName", branch);
    body.put("address", "QA address");
    body.put("latitude", 10.7731);
    body.put("longitude", 106.703);
    body.put("pinConfirmed", true);
    body.put("email", UUID.randomUUID() + "@shop-test.local");
    body.put("fullName", "QA owner");
    body.put("password", "Test-password-123");
    return body;
  }

  JsonNode create(Actor admin, String brand, String branch) throws Exception {
    return call(post("/api/admin/stores"), admin.token, input(brand, branch), 201);
  }

  void order(Store store, String status, boolean paid, int amount) {
    var o = new CustomerOrder(store.owner, store);
    o.status = status;
    o.total = BigDecimal.valueOf(amount);
    o.fee = BigDecimal.valueOf(30000);
    if (paid) o.paidAt = Instant.now();
    orders.save(o);
  }

  JsonNode row(JsonNode rows, String field, String value) {
    for (var r : rows) if (r.get(field).asText().equals(value)) return r;
    fail("Expected brand row absent");
    return null;
  }

  @Test
  void revenueGroupsBrandBranchesRanksAndCountsSeparately() throws Exception {
    var admin = actor(Role.ADMIN);
    String a = "Brand A " + UUID.randomUUID(), b = "Brand B " + UUID.randomUUID();
    var first = create(admin, a, null);
    var second = create(admin, "  " + a.toUpperCase(Locale.ROOT) + "  ", "Chi nhánh 2");
    var other = create(admin, b, null);
    var s1 = stores.findById(first.get("storeId").asLong()).orElseThrow();
    var s2 = stores.findById(second.get("storeId").asLong()).orElseThrow();
    var s3 = stores.findById(other.get("storeId").asLong()).orElseThrow();
    order(s1, "DELIVERED", true, 1000000);
    order(s2, "DELIVERED", true, 500000);
    order(s1, "DELIVERED", false, 8000000);
    order(s2, "CANCELLED", true, 9000000);
    order(s3, "DELIVERED", true, 900000);
    var summary = call(get("/api/admin/revenue"), admin.token, null, 200);
    var brand = row(summary.get("brands"), "key", BrandNames.normalize(a));
    assertEquals(2, brand.get("branchCount").asInt());
    assertEquals(2, brand.get("branches").size());
    assertEquals(1500000, brand.get("grossSales").asInt());
    assertEquals(225000, brand.get("platformRevenue").asInt());
    assertEquals(BrandNames.normalize(a), summary.get("topBrand").get("key").asText());
    assertTrue(summary.get("branchCount").asInt() > summary.get("brandCount").asInt());
    var brands = call(get("/api/admin/brands"), admin.token, null, 200);
    assertEquals(2, row(brands, "key", BrandNames.normalize(a)).get("branchCount").asInt());
  }

  @Test
  void deletingOwnerHidesBranchAndLastBrandButPreservesRevenueAndCanCreateFreshBrand()
      throws Exception {
    var admin = actor(Role.ADMIN);
    String brand = "Deleted " + UUID.randomUUID();
    var first = create(admin, brand, null);
    var second = create(admin, brand, "Hai");
    long firstId = first.get("storeId").asLong(), secondId = second.get("storeId").asLong();
    order(stores.findById(firstId).orElseThrow(), "DELIVERED", true, 100000);
    call(delete("/api/admin/accounts/" + first.get("id").asLong()), admin.token, null, 204);
    for (var branch : call(get("/api/branches"), null, null, 200))
      assertNotEquals(firstId, branch.get("id").asLong());
    assertEquals(
        1,
        row(
                call(get("/api/admin/brands"), admin.token, null, 200),
                "key",
                BrandNames.normalize(brand))
            .get("branchCount")
            .asInt());
    var staffBody =
        new HashMap<String, Object>(
            Map.of(
                "email",
                UUID.randomUUID() + "@staff.local",
                "fullName",
                "QA",
                "password",
                "Test-password-123",
                "role",
                "STORE",
                "storeId",
                firstId));
    call(post("/api/admin/accounts"), admin.token, staffBody, 400);
    call(delete("/api/admin/accounts/" + second.get("id").asLong()), admin.token, null, 204);
    for (var value : call(get("/api/admin/brands"), admin.token, null, 200))
      assertNotEquals(BrandNames.normalize(brand), value.get("key").asText());
    var historical =
        row(
            call(get("/api/admin/revenue"), admin.token, null, 200).get("brands"),
            "key",
            BrandNames.normalize(brand));
    assertFalse(historical.get("active").asBoolean());
    assertEquals(100000, historical.get("grossSales").asInt());
    assertEquals(0, historical.get("branchCount").asInt());
    var recreated = create(admin, brand, null);
    assertNotEquals(firstId, recreated.get("storeId").asLong());
    assertNotEquals(secondId, recreated.get("storeId").asLong());
  }

  @Test
  void deletingStaffKeepsBranchAndDeletingOwnerWithOpenOrdersIsBlocked() throws Exception {
    var admin = actor(Role.ADMIN);
    String brand = "Staff " + UUID.randomUUID();
    var owner = create(admin, brand, null);
    long storeId = owner.get("storeId").asLong();
    var staff =
        call(
            post("/api/admin/accounts"),
            admin.token,
            Map.of(
                "email",
                UUID.randomUUID() + "@staff.local",
                "fullName",
                "QA staff",
                "password",
                "Test-password-123",
                "role",
                "STORE",
                "storeId",
                storeId),
            201);
    assertFalse(staff.get("storeOwner").asBoolean());
    assertTrue(owner.get("storeOwner").asBoolean());
    call(delete("/api/admin/accounts/" + staff.get("id").asLong()), admin.token, null, 204);
    assertEquals(
        1,
        row(
                call(get("/api/admin/brands"), admin.token, null, 200),
                "key",
                BrandNames.normalize(brand))
            .get("branchCount")
            .asInt());
    order(stores.findById(storeId).orElseThrow(), "PENDING", false, 20000);
    call(delete("/api/admin/accounts/" + owner.get("id").asLong()), admin.token, null, 409);
    assertFalse(users.findById(owner.get("id").asLong()).orElseThrow().deleted);
  }

  @Test
  void previouslyDeletedOwnerIsExcludedFromCatalogAndBrandCreationOptions() throws Exception {
    var admin = actor(Role.ADMIN);
    String brand = "Legacy deleted " + UUID.randomUUID();
    var owner = actor(Role.STORE);
    var user = users.findById(owner.id).orElseThrow();
    user.deleted = true;
    user.blocked = true;
    users.save(user);
    var old = new Store(brand, user);
    old.brand = brand;
    old.brandKey = BrandNames.normalize(brand);
    old.branchKey = old.brandKey;
    old.latitude = 10.7731;
    old.longitude = 106.703;
    old.address = "Legacy";
    stores.save(old);
    for (var value : call(get("/api/admin/brands"), admin.token, null, 200))
      assertNotEquals(BrandNames.normalize(brand), value.get("key").asText());
    for (var value : call(get("/api/branches"), null, null, 200))
      assertNotEquals(old.id, value.get("id").asLong());
    var fresh = create(admin, brand, null);
    assertNotEquals(old.id, fresh.get("storeId").asLong());
  }
}
