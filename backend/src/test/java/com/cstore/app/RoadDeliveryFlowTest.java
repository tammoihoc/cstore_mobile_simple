package com.cstore.app;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;

import com.cstore.app.entity.AppUser;
import com.cstore.app.entity.Product;
import com.cstore.app.entity.Role;
import com.cstore.app.entity.Store;
import com.cstore.app.repository.Products;
import com.cstore.app.repository.Stores;
import com.cstore.app.repository.Users;
import com.cstore.app.service.RoutingService;
import com.fasterxml.jackson.databind.*;
import java.math.BigDecimal;
import java.util.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.web.server.ResponseStatusException;

@SpringBootTest(
    properties = {
      "spring.datasource.url=jdbc:h2:mem:road-flow-test;MODE=MySQL;DB_CLOSE_DELAY=-1",
      "spring.datasource.username=sa",
      "spring.datasource.password=",
      "spring.jpa.hibernate.ddl-auto=create-drop",
      "JWT_SECRET=road-flow-test-signing-key-thirty-two-characters-long",
      "ADMIN_EMAIL=",
      "ADMIN_PASSWORD="
    })
@AutoConfigureMockMvc
class RoadDeliveryFlowTest {
  @Autowired MockMvc mvc;
  @Autowired ObjectMapper json;
  @Autowired Users users;
  @Autowired Stores stores;
  @Autowired Products products;
  @Autowired PasswordEncoder passwords;
  @MockitoBean RoutingService routing;

  record Fixture(
      String owner, String buyer, String shipper, String other, long store, long product) {}

  @BeforeEach
  void roads() {
    when(routing.route(anyDouble(), anyDouble(), anyDouble(), anyDouble()))
        .thenAnswer(
            c -> road(c.getArgument(0), c.getArgument(1), c.getArgument(2), c.getArgument(3), 1.8));
  }

  RoutingService.RoadRoute road(double a, double b, double c, double d, double km) {
    return new RoutingService.RoadRoute(
        km,
        240,
        List.of(List.of(b, a), List.of(d, c)),
        List.of(new RoutingService.Step("Đường Nguyễn Huệ", "depart", "", km * 1000, 240, a, b)),
        "OSRM",
        "SHORTEST_AVAILABLE");
  }

  String actor(Role role) throws Exception {
    var user =
        users.save(
            new AppUser(
                UUID.randomUUID() + "@roads.local",
                passwords.encode("Testing-password-123"),
                "Road QA",
                role));
    if (role == Role.SHIPPER) {
      user.avatar = "/api/images/test-shipper.png";
      user.phone = "0901234567";
      users.save(user);
    }
    return call(
            post("/api/auth/login"),
            null,
            Map.of("email", user.email, "password", "Testing-password-123"),
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
        ? json.nullNode()
        : json.readTree(response.getContentAsString());
  }

  Fixture fixture() throws Exception {
    String owner = actor(Role.STORE);
    long ownerId = call(get("/api/auth/me"), owner, null, 200).get("id").asLong();
    var store = new Store("Road branch", users.findById(ownerId).orElseThrow());
    store.latitude = 10.7731;
    store.longitude = 106.703;
    store.address = "45 Nguyễn Huệ";
    store = stores.save(store);
    var product =
        products.save(
            new Product(
                store, "Ảnh món", BigDecimal.valueOf(25000), 10, "/api/images/example.png"));
    return new Fixture(
        owner,
        actor(Role.CUSTOMER),
        actor(Role.SHIPPER),
        actor(Role.SHIPPER),
        store.id,
        product.id);
  }

  Map<String, Object> order(Fixture f) {
    return Map.of(
        "storeId",
        f.store,
        "items",
        List.of(Map.of("productId", f.product, "quantity", 1)),
        "recipient",
        "Road buyer",
        "phone",
        "0901234567",
        "address",
        "Điểm giao",
        "latitude",
        10.7736,
        "longitude",
        106.7034,
        "pinConfirmed",
        true);
  }

  @Test
  void quoteAndOrderUseRoadDistanceAndFeeRatherThanShortStraightLine() throws Exception {
    var f = fixture();
    var q =
        call(
            post("/api/customer/delivery-quote"),
            f.buyer,
            Map.of("storeId", f.store, "latitude", 10.7736, "longitude", 106.7034),
            200);
    assertEquals(1.8, q.get("distanceKm").asDouble());
    assertEquals(240, q.get("durationSeconds").asInt());
    assertEquals(20400, q.get("fee").asInt());
    assertEquals("SHORTEST_AVAILABLE", q.get("route").get("selection").asText());
    var nearby =
        call(get("/api/customer/nearby?latitude=10.7736&longitude=106.7034"), f.buyer, null, 200);
    boolean found = false;
    for (var branch : nearby)
      if (branch.get("storeId").asLong() == f.store) {
        assertEquals(1.8, branch.get("distanceKm").asDouble());
        found = true;
      }
    assertTrue(found);
    var placed = call(post("/api/customer/orders"), f.buyer, order(f), 200);
    assertEquals("ROAD", placed.get("distanceSource").asText());
    assertEquals(1.8, placed.get("distanceKm").asDouble());
    assertEquals(20400, placed.get("fee").asInt());
    assertEquals(45400, placed.get("total").asInt());
  }

  @Test
  void routesBeyondTenKmAndUnavailableRoadProviderCannotTakeStockOrChargeFakeFees()
      throws Exception {
    var f = fixture();
    when(routing.route(anyDouble(), anyDouble(), anyDouble(), anyDouble()))
        .thenReturn(road(10.7731, 106.703, 10.7736, 106.7034, 11));
    call(
        post("/api/customer/delivery-quote"),
        f.buyer,
        Map.of("storeId", f.store, "latitude", 10.7736, "longitude", 106.7034),
        400);
    call(post("/api/customer/orders"), f.buyer, order(f), 400);
    assertEquals(10, products.findById(f.product).orElseThrow().stock);
    when(routing.route(anyDouble(), anyDouble(), anyDouble(), anyDouble()))
        .thenThrow(
            new ResponseStatusException(
                HttpStatus.SERVICE_UNAVAILABLE, "Road provider unavailable"));
    call(post("/api/customer/orders"), f.buyer, order(f), 503);
    assertEquals(10, products.findById(f.product).orElseThrow().stock);
  }

  @Test
  void pickupSimulationMovesDriverToStoreSwitchesLegAndRealGpsClearsSimulation() throws Exception {
    var f = fixture();
    long id = call(post("/api/customer/orders"), f.buyer, order(f), 200).get("id").asLong();
    call(put("/api/merchant/orders/" + id + "/status"), f.owner, Map.of("status", "ACCEPTED"), 200);
    for (var driver : List.of(f.shipper, f.other))
      call(
          put("/api/shipper/location"),
          driver,
          Map.of("online", true, "latitude", 10.772, "longitude", 106.702),
          200);
    var before = call(get("/api/shipper/orders/" + id + "/route"), f.shipper, null, 200);
    assertEquals("PICKUP", before.get("stage").asText());
    assertFalse(before.get("simulated").asBoolean());
    assertEquals(2, before.get("pickupRoute").get("coordinates").size());
    assertEquals(2, before.get("deliveryRoute").get("coordinates").size());
    call(post("/api/shipper/orders/" + id + "/claim"), f.shipper, null, 200);
    call(get("/api/shipper/orders/" + id + "/route"), f.other, null, 403);
    call(
        put("/api/shipper/orders/" + id + "/status"),
        f.other,
        Map.of("status", "PICKED_UP", "simulateArrival", true),
        403);
    call(
        put("/api/shipper/orders/" + id + "/status"),
        f.shipper,
        Map.of("status", "PICKED_UP", "simulateArrival", true),
        200);
    var state = call(get("/api/shipper/state"), f.shipper, null, 200);
    assertTrue(state.get("simulated").asBoolean());
    assertEquals(10.7731, state.get("latitude").asDouble());
    assertEquals(106.703, state.get("longitude").asDouble());
    clearInvocations(routing);
    var after = call(get("/api/shipper/orders/" + id + "/route"), f.shipper, null, 200);
    assertEquals("DELIVERY", after.get("stage").asText());
    assertTrue(after.get("pickupRoute").isNull());
    verify(routing, never()).route(anyDouble(), anyDouble(), eq(10.7731), eq(106.703));
    assertTrue(after.get("simulated").asBoolean());
    assertEquals(after.get("deliveryRoute"), after.get("activeRoute"));
    assertEquals(10.7731, after.get("activeRoute").get("coordinates").get(0).get(1).asDouble());
    call(
        put("/api/shipper/orders/" + id + "/status"),
        f.shipper,
        Map.of("status", "DELIVERING", "simulateArrival", true),
        400);
    var offline =
        call(
            put("/api/shipper/location"),
            f.shipper,
            Map.of(
                "online",
                false,
                "latitude",
                10.7731,
                "longitude",
                106.703,
                "preserveSimulation",
                true),
            200);
    assertTrue(offline.get("simulated").asBoolean());
    assertFalse(offline.get("online").asBoolean());
    var real =
        call(
            put("/api/shipper/location"),
            f.shipper,
            Map.of("online", true, "latitude", 10.7734, "longitude", 106.7033),
            200);
    assertFalse(real.get("simulated").asBoolean());
    assertEquals(10.7734, real.get("latitude").asDouble());
  }

  @Test
  void shipperRoadRangeRejectsStoreThatIsNearbyOnlyInStraightLine() throws Exception {
    var f = fixture();
    long id = call(post("/api/customer/orders"), f.buyer, order(f), 200).get("id").asLong();
    call(put("/api/merchant/orders/" + id + "/status"), f.owner, Map.of("status", "ACCEPTED"), 200);
    call(
        put("/api/shipper/location"),
        f.shipper,
        Map.of("online", true, "latitude", 10.772, "longitude", 106.702),
        200);
    when(routing.route(anyDouble(), anyDouble(), anyDouble(), anyDouble()))
        .thenReturn(road(10.772, 106.702, 10.7731, 106.703, 6));
    for (var offer : call(get("/api/shipper/offers"), f.shipper, null, 200))
      assertNotEquals(id, offer.get("id").asLong());
    call(post("/api/shipper/orders/" + id + "/claim"), f.shipper, null, 409);
    call(get("/api/shipper/orders/" + id + "/route"), f.shipper, null, 403);
  }
}
