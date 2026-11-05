package com.cstore.app;

import static org.junit.jupiter.api.Assertions.*;

import com.cstore.app.service.RoutingService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

class RoutingServiceTest {
  final ObjectMapper json = new ObjectMapper();

  String route(double distance, double duration) {
    return "{\"distance\":"
        + distance
        + ",\"duration\":"
        + duration
        + ",\"geometry\":{\"coordinates\":[[106.703,10.7731],[106.704,10.774]]},\"legs\":[{\"steps\":[{\"name\":\"Nguyễn"
        + " Huệ\",\"distance\":120,\"duration\":18,\"maneuver\":{\"type\":\"turn\",\"modifier\":\"right\",\"location\":[106.703,10.7731]}}]}]}";
  }

  @Test
  void choosesShortestReturnedRoadInsteadOfFastestAndPreservesGeometryAndSteps() throws Exception {
    var service = new RoutingService(json, "https://routing.invalid");
    var result =
        service.parse(
            json.readTree(
                "{\"code\":\"Ok\",\"routes\":["
                    + route(4200, 180)
                    + ","
                    + route(3100, 240)
                    + "]}"));
    assertEquals(3.1, result.distanceKm());
    assertEquals(240, result.durationSeconds());
    assertEquals(106.703, result.coordinates().get(0).get(0));
    assertEquals(10.7731, result.coordinates().get(0).get(1));
    assertEquals("Nguyễn Huệ", result.steps().get(0).name());
    assertEquals("right", result.steps().get(0).modifier());
    assertEquals("SHORTEST_AVAILABLE", result.selection());
  }

  @Test
  void noRouteAndMalformedResponsesNeverBecomeZeroOrStraightLine() throws Exception {
    var service = new RoutingService(json, "https://routing.invalid");
    assertEquals(
        400,
        assertThrows(
                ResponseStatusException.class,
                () -> service.parse(json.readTree("{\"code\":\"NoRoute\"}")))
            .getStatusCode()
            .value());
    for (String body :
        new String[] {
          "{\"code\":\"Ok\",\"routes\":[]}",
          "{\"code\":\"Ok\",\"routes\":[{\"distance\":500,\"duration\":60,\"geometry\":{\"coordinates\":[]}}]}"
        }) {
      assertEquals(
          503,
          assertThrows(ResponseStatusException.class, () -> service.parse(json.readTree(body)))
              .getStatusCode()
              .value());
    }
  }

  @Test
  void networkRequestsUseLngLatAndCacheRepeatedRoute() throws Exception {
    var requests = new AtomicInteger();
    var server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
    server.createContext(
        "/route/v1/driving/",
        exchange -> {
          requests.incrementAndGet();
          assertEquals(
              "/route/v1/driving/106.703000,10.773100;106.704000,10.774000",
              exchange.getRequestURI().getPath());
          assertTrue(exchange.getRequestURI().getQuery().contains("geometries=geojson"));
          byte[] bytes =
              ("{\"code\":\"Ok\",\"routes\":[" + route(3100, 240) + "]}")
                  .getBytes(java.nio.charset.StandardCharsets.UTF_8);
          exchange.sendResponseHeaders(200, bytes.length);
          exchange.getResponseBody().write(bytes);
          exchange.close();
        });
    server.start();
    try {
      var service = new RoutingService(json, "http://127.0.0.1:" + server.getAddress().getPort());
      assertEquals(3.1, service.route(10.7731, 106.703, 10.774, 106.704).distanceKm());
      assertEquals(3.1, service.route(10.7731, 106.703, 10.774, 106.704).distanceKm());
      assertEquals(1, requests.get());
    } finally {
      server.stop(0);
    }
  }

  @Test
  void providerFailureRemainsUnavailable() throws Exception {
    var server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
    server.createContext(
        "/",
        exchange -> {
          exchange.sendResponseHeaders(503, -1);
          exchange.close();
        });
    server.start();
    try {
      var service = new RoutingService(json, "http://127.0.0.1:" + server.getAddress().getPort());
      assertEquals(
          503,
          assertThrows(
                  ResponseStatusException.class,
                  () -> service.route(10.7731, 106.703, 10.774, 106.704))
              .getStatusCode()
              .value());
    } finally {
      server.stop(0);
    }
  }
}
