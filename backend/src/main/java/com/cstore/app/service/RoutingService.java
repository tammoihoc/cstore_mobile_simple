package com.cstore.app.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

/** Lấy tuyến đường thực tế từ OSRM; không thay lỗi mạng bằng khoảng cách đường thẳng. */
@Service
public class RoutingService {
  public record Step(
      String name,
      String type,
      String modifier,
      double distanceMeters,
      double durationSeconds,
      Double latitude,
      Double longitude) {}

  public record RoadRoute(
      double distanceKm,
      double durationSeconds,
      List<List<Double>> coordinates,
      List<Step> steps,
      String provider,
      String selection) {}

  private record Cached(RoadRoute route, long expiresAt) {}

  private final ObjectMapper json;
  private final URI base;
  private final HttpClient client;
  private final Map<String, Cached> cache = new LinkedHashMap<>(32, .75f, true);
  private long lastRequestAt;

  @Autowired
  public RoutingService(
      ObjectMapper json,
      @Value("${ROUTING_BASE_URL:https://router.project-osrm.org}") String base) {
    this(json, base, HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(4)).build());
  }

  public RoutingService(ObjectMapper json, String base, HttpClient client) {
    this.json = json;
    this.base = URI.create(base.replaceAll("/+$", ""));
    this.client = client;
  }

  /** Xử lý lần lượt để giới hạn tần suất; yêu cầu lặp dùng lại tuyến đã lưu trong bộ nhớ. */
  public synchronized RoadRoute route(double fromLat, double fromLng, double toLat, double toLng) {
    validate(fromLat, fromLng);
    validate(toLat, toLng);
    String coordinates =
        String.format(Locale.ROOT, "%.6f,%.6f;%.6f,%.6f", fromLng, fromLat, toLng, toLat);
    var saved = cache.get(coordinates);
    long now = System.currentTimeMillis();
    if (saved != null && saved.expiresAt > now) {
      return saved.route;
    }
    try {
      long wait = 1100 - (now - lastRequestAt);
      if (wait > 0) {
        Thread.sleep(wait);
      }
      lastRequestAt = System.currentTimeMillis();
      URI uri =
          URI.create(
              base
                  + "/route/v1/driving/"
                  + coordinates
                  + "?alternatives=true&steps=true&overview=full&geometries=geojson&continue_straight=false");
      var response =
          client.send(
              HttpRequest.newBuilder(uri)
                  .timeout(Duration.ofSeconds(8))
                  .header("User-Agent", "CStoreRoadRouting/1.0")
                  .GET()
                  .build(),
              HttpResponse.BodyHandlers.ofString());
      var body = json.readTree(response.body());
      if (response.statusCode() != 200 && !"NoRoute".equals(body.path("code").asText())) {
        throw unavailable();
      }
      var result = parse(body);
      if (cache.size() >= 256) {
        cache.remove(cache.keySet().iterator().next());
      }
      cache.put(
          coordinates,
          new Cached(result, System.currentTimeMillis() + Duration.ofMinutes(10).toMillis()));
      return result;
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      throw unavailable();
    } catch (ResponseStatusException e) {
      throw e;
    } catch (Exception e) {
      throw unavailable();
    }
  }

  public RoadRoute parse(JsonNode response) {
    if ("NoRoute".equals(response.path("code").asText())) {
      throw new ResponseStatusException(
          HttpStatus.BAD_REQUEST,
          "Không tìm được đường đi tới điểm đã ghim. Hãy chọn điểm gần đường có thể di chuyển.");
    }
    if (!"Ok".equals(response.path("code").asText()) || !response.path("routes").isArray()) {
      throw unavailable();
    }
    for (var waypoint : response.path("waypoints")) {
      double snapDistance = waypoint.path("distance").asDouble(0);
      if (!Double.isFinite(snapDistance) || snapDistance > 500) {
        throw new ResponseStatusException(
            HttpStatus.BAD_REQUEST,
            "Điểm đã ghim quá xa đường có thể di chuyển. Hãy chọn điểm gần lối vào cửa hàng hoặc"
                + " địa chỉ giao hàng.");
      }
    }
    RoadRoute shortest = null;
    for (var candidate : response.path("routes")) {
      double metres = candidate.path("distance").asDouble(Double.NaN),
          seconds = candidate.path("duration").asDouble(Double.NaN);
      if (!Double.isFinite(metres) || metres < 0 || !Double.isFinite(seconds) || seconds < 0) {
        continue;
      }
      var points = new ArrayList<List<Double>>();
      for (var point : candidate.path("geometry").path("coordinates")) {
        if (!point.isArray() || point.size() < 2) {
          points.clear();
          break;
        }
        double lng = point.get(0).asDouble(Double.NaN), lat = point.get(1).asDouble(Double.NaN);
        if (!valid(lat, lng)) {
          points.clear();
          break;
        }
        points.add(List.of(lng, lat));
      }
      if (points.size() < 2) {
        continue;
      }
      var steps = new ArrayList<Step>();
      for (var leg : candidate.path("legs")) {
        for (var step : leg.path("steps")) {
          var maneuver = step.path("maneuver");
          var location = maneuver.path("location");
          Double lat = null, lng = null;
          if (location.isArray()
              && location.size() >= 2
              && valid(
                  location.get(1).asDouble(Double.NaN), location.get(0).asDouble(Double.NaN))) {
            lat = location.get(1).asDouble();
            lng = location.get(0).asDouble();
          }
          steps.add(
              new Step(
                  step.path("name").asText(""),
                  maneuver.path("type").asText("continue"),
                  maneuver.path("modifier").asText(""),
                  step.path("distance").asDouble(0),
                  step.path("duration").asDouble(0),
                  lat,
                  lng));
        }
      }
      var route =
          new RoadRoute(
              metres / 1000,
              seconds,
              List.copyOf(points),
              List.copyOf(steps),
              "OSRM",
              "SHORTEST_AVAILABLE");
      if (shortest == null || route.distanceKm < shortest.distanceKm) {
        shortest = route;
      }
    }
    if (shortest == null) {
      throw unavailable();
    }
    return shortest;
  }

  private static boolean valid(double lat, double lng) {
    return Double.isFinite(lat)
        && Double.isFinite(lng)
        && lat >= -90
        && lat <= 90
        && lng >= -180
        && lng <= 180;
  }

  private static void validate(double lat, double lng) {
    if (!valid(lat, lng)) {
      throw CommerceSupport.bad("Tọa độ không hợp lệ");
    }
  }

  private static ResponseStatusException unavailable() {
    return new ResponseStatusException(
        HttpStatus.SERVICE_UNAVAILABLE,
        "Chưa lấy được tuyến đường thực tế. Vui lòng thử lại; phí giao hàng chưa được xác định.");
  }
}
