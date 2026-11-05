package com.cstore.app;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;

import com.cstore.app.entity.AppUser;
import com.cstore.app.entity.Role;
import com.cstore.app.repository.Products;
import com.cstore.app.repository.Users;
import com.cstore.app.service.RoutingService;
import com.fasterxml.jackson.databind.*;
import java.awt.image.BufferedImage;
import java.io.*;
import java.util.*;
import java.util.concurrent.*;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

@SpringBootTest(
    properties = {
      "spring.datasource.url=jdbc:h2:mem:commerce-test;MODE=MySQL;DB_CLOSE_DELAY=-1",
      "spring.datasource.username=sa",
      "spring.datasource.password=",
      "spring.jpa.hibernate.ddl-auto=create-drop",
      "JWT_SECRET=commerce-test-signing-key-thirty-two-characters-long",
      "ADMIN_EMAIL=",
      "ADMIN_PASSWORD=",
      "UPLOAD_DIR=/tmp/cstore-commerce-test-uploads"
    })
@AutoConfigureMockMvc
class CommerceFlowTest {
  @MockitoBean RoutingService routing;

  @BeforeEach
  void roadRouting() {
    when(routing.route(anyDouble(), anyDouble(), anyDouble(), anyDouble()))
        .thenAnswer(call ->
            new RoutingService.RoadRoute(
                1.25,
                180,
                List.of(
                    List.of(call.getArgument(1), call.getArgument(0)),
                    List.of(call.getArgument(3), call.getArgument(2))),
                List.of(),
                "OSRM",
                "SHORTEST_AVAILABLE"));
  }

  @Autowired MockMvc mvc;
  @Autowired ObjectMapper json;
  @Autowired Users users;
  @Autowired Products products;
  @Autowired PasswordEncoder encoder;

  String token(Role role) throws Exception {
    String email = UUID.randomUUID() + "@test.local";
    var actor = new AppUser(email, encoder.encode("Testing-password-123"), "QA", role);
    if (role == Role.SHIPPER) {
      actor.avatar = "/api/images/test-shipper.png";
      actor.phone = "0901234567";
    }
    users.save(actor);
    return call(
            post("/api/auth/login"),
            null,
            Map.of("email", email, "password", "Testing-password-123"),
            200)
        .get("token")
        .asText();
  }

  JsonNode call(MockHttpServletRequestBuilder request, String token, Object body, int expected)
      throws Exception {
    if (token != null) request.header("Authorization", "Bearer " + token);
    if (body != null)
      request.contentType("application/json").content(json.writeValueAsString(body));
    var response = mvc.perform(request).andReturn().getResponse();
    assertEquals(expected, response.getStatus(), response.getContentAsString());
    return response.getContentAsString().isEmpty()
        ? json.createObjectNode()
        : json.readTree(response.getContentAsString());
  }

  record Fixture(String store, long branch, long product) {}

  Fixture fixture(int stock) throws Exception {
    var admin = token(Role.ADMIN);
    String email = UUID.randomUUID() + "@store.local";
    var created =
        call(
            post("/api/admin/stores"),
            admin,
            Map.of(
                "brand",
                "QA " + UUID.randomUUID(),
                "name",
                "QA branch",
                "address",
                "45 Nguyen Hue",
                "latitude",
                10.7731,
                "longitude",
                106.703,
                "pinConfirmed",
                true,
                "email",
                email,
                "fullName",
                "QA store",
                "password",
                "Store-password-123"),
            201);
    var store =
        call(
                post("/api/auth/login"),
                null,
                Map.of("email", email, "password", "Store-password-123"),
                200)
            .get("token")
            .asText();
    long product =
        call(
                post("/api/merchant/products"),
                store,
                Map.of("name", "QA product", "price", 25000, "stock", stock, "category", "Drink"),
                200)
            .get("id")
            .asLong();
    return new Fixture(store, created.get("storeId").asLong(), product);
  }

  Map<String, Object> order(Fixture f) {
    return Map.of(
        "storeId",
        f.branch,
        "items",
        List.of(Map.of("productId", f.product, "quantity", 1)),
        "recipient",
        "QA buyer",
        "phone",
        "0901234567",
        "address",
        "45 Nguyen Hue",
        "latitude",
        10.7732,
        "longitude",
        106.7032,
        "pinConfirmed",
        true);
  }

  @Test
  void realImageStockCancelAndCodLifecycle() throws Exception {
    var f = fixture(4);
    var customer = token(Role.CUSTOMER);
    var shipper = token(Role.SHIPPER);
    var bytes = new ByteArrayOutputStream();
    ImageIO.write(new BufferedImage(12, 12, BufferedImage.TYPE_INT_RGB), "png", bytes);
    var result =
        mvc.perform(
                multipart("/api/merchant/products/" + f.product + "/image")
                    .file(
                        new MockMultipartFile(
                            "file", "image.png", "image/png", bytes.toByteArray()))
                    .header("Authorization", "Bearer " + f.store))
            .andReturn()
            .getResponse();
    assertEquals(200, result.getStatus());
    String image = json.readTree(result.getContentAsString()).get("image").asText();
    assertEquals(200, mvc.perform(get(image)).andReturn().getResponse().getStatus());
    assertEquals(
        400,
        mvc.perform(
                multipart("/api/merchant/products/" + f.product + "/image")
                    .file(
                        new MockMultipartFile(
                            "file", "bad.svg", "image/svg+xml", "<svg/>".getBytes()))
                    .header("Authorization", "Bearer " + f.store))
            .andReturn()
            .getResponse()
            .getStatus());
    var cancelled = call(post("/api/customer/orders"), customer, order(f), 200);
    long cid = cancelled.get("id").asLong();
    call(put("/api/customer/orders/" + cid + "/cancel"), customer, null, 200);
    call(put("/api/customer/orders/" + cid + "/cancel"), customer, null, 400);
    var o = call(post("/api/customer/orders"), customer, order(f), 200);
    long id = o.get("id").asLong();
    assertTrue(o.get("distanceKm").asDouble() > 0);
    assertEquals(
        40000 + Math.ceil(o.get("distanceKm").asDouble() * 3000), o.get("total").asDouble());
    assertEquals(image, o.get("items").get(0).get("image").asText());
    var changed = products.findById(f.product).orElseThrow();
    changed.image = "/api/images/new-product-photo.png";
    products.save(changed);
    assertEquals(
        image,
        call(get("/api/customer/orders"), customer, null, 200)
            .get(0)
            .get("items")
            .get(0)
            .get("image")
            .asText());
    call(put("/api/merchant/orders/" + id + "/status"), f.store, Map.of("status", "ACCEPTED"), 200);
    call(
        put("/api/shipper/location"),
        shipper,
        Map.of("online", true, "latitude", 10.7731, "longitude", 106.703),
        200);
    call(post("/api/shipper/orders/" + id + "/claim"), shipper, null, 200);
    call(post("/api/shipper/orders/" + id + "/claim"), shipper, null, 409);
    call(
        put("/api/shipper/orders/" + id + "/status"), shipper, Map.of("status", "DELIVERING"), 400);
    call(put("/api/shipper/orders/" + id + "/status"), shipper, Map.of("status", "PICKED_UP"), 200);
    call(
        put("/api/shipper/orders/" + id + "/status"), shipper, Map.of("status", "DELIVERING"), 200);
    call(put("/api/shipper/orders/" + id + "/status"), shipper, Map.of("status", "DELIVERED"), 400);
    call(put("/api/shipper/orders/" + id + "/payment"), shipper, null, 200);
    call(put("/api/shipper/orders/" + id + "/payment"), shipper, null, 409);
    var done =
        call(
            put("/api/shipper/orders/" + id + "/status"),
            shipper,
            Map.of("status", "DELIVERED"),
            200);
    assertTrue(done.get("paid").asBoolean());
    assertEquals(6, done.get("history").size());
    assertEquals(
        3, call(get("/api/merchant/products"), f.store, null, 200).get(0).get("stock").asInt());
  }

  @Test
  void concurrentCheckoutDoesNotOversell() throws Exception {
    var f = fixture(1);
    String buyer = token(Role.CUSTOMER);
    try (var pool = Executors.newFixedThreadPool(2)) {
      var gate = new CountDownLatch(1);
      Callable<Integer> place =
          () -> {
            gate.await();
            return mvc.perform(
                    post("/api/customer/orders")
                        .header("Authorization", "Bearer " + buyer)
                        .contentType("application/json")
                        .content(json.writeValueAsString(order(f))))
                .andReturn()
                .getResponse()
                .getStatus();
          };
      var a = pool.submit(place);
      var b = pool.submit(place);
      gate.countDown();
      var codes = new ArrayList<>(List.of(a.get(), b.get()));
      Collections.sort(codes);
      assertEquals(List.of(200, 409), codes);
    }
    assertEquals(
        0, call(get("/api/merchant/products"), f.store, null, 200).get(0).get("stock").asInt());
  }

  @Test
  void branchIsolationRadiusAndThreeDeliveryLimit() throws Exception {
    var a = fixture(10);
    var b = fixture(10);
    var customer = token(Role.CUSTOMER);
    var shipper = token(Role.SHIPPER);
    call(
        put("/api/merchant/products/" + b.product),
        a.store,
        Map.of("name", "Forbidden", "price", 10000, "stock", 10, "category", "QA"),
        403);
    var mixed = new HashMap<String, Object>(order(a));
    mixed.put("items", List.of(Map.of("productId", b.product, "quantity", 1)));
    call(post("/api/customer/orders"), customer, mixed, 400);
    long id = call(post("/api/customer/orders"), customer, order(a), 200).get("id").asLong();
    call(put("/api/merchant/orders/" + id + "/status"), a.store, Map.of("status", "ACCEPTED"), 200);
    call(
        put("/api/shipper/location"),
        shipper,
        Map.of("online", true, "latitude", 0, "longitude", 0),
        200);
    call(post("/api/shipper/orders/" + id + "/claim"), shipper, null, 409);
    call(
        put("/api/shipper/location"),
        shipper,
        Map.of("online", true, "latitude", 10.7731, "longitude", 106.703),
        200);
    call(post("/api/shipper/orders/" + id + "/claim"), shipper, null, 200);
    for (int i = 0; i < 3; i++) {
      long next = call(post("/api/customer/orders"), customer, order(a), 200).get("id").asLong();
      call(
          put("/api/merchant/orders/" + next + "/status"),
          a.store,
          Map.of("status", "ACCEPTED"),
          200);
      call(post("/api/shipper/orders/" + next + "/claim"), shipper, null, i < 2 ? 200 : 400);
    }
  }
}
