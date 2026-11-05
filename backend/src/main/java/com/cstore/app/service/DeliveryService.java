package com.cstore.app.service;

import static com.cstore.app.service.CommerceSupport.bad;
import static com.cstore.app.service.CommerceSupport.distance;
import static com.cstore.app.service.CommerceSupport.validCoordinates;

import com.cstore.app.dto.DeliveryDtos.DeliveryQuote;
import com.cstore.app.entity.Store;
import java.math.BigDecimal;
import org.springframework.stereotype.Service;

/**
 * Tính tuyến đường và phí giao hàng từ chi nhánh tới khách; kiểm tra cả khoảng cách sàng lọc và
 * tuyến đường thực tế.
 */
@Service
public class DeliveryService {
  private final RoutingService routing;

  public DeliveryService(RoutingService routing) {
    this.routing = routing;
  }

  public DeliveryQuote quote(Store store, double latitude, double longitude) {
    validCoordinates(latitude, longitude);
    if (!store.isActive()) {
      throw bad("Cửa hàng đã ngừng hoạt động");
    }
    if (store.latitude == null || store.longitude == null) {
      throw bad("Chi nhánh chưa ghim vị trí");
    }
    if (distance(store.latitude, store.longitude, latitude, longitude) > 10) {
      throw bad("Địa chỉ ngoài phạm vi giao hàng 10 km đường đi");
    }
    // Khoảng cách Haversine chỉ sàng lọc nhanh. Giới hạn và phí dùng đường đi OSRM.
    var route = routing.route(store.latitude, store.longitude, latitude, longitude);
    if (route.distanceKm() > 10) {
      throw bad("Địa chỉ ngoài phạm vi giao hàng 10 km đường đi");
    }
    return new DeliveryQuote(
        store.id,
        route.distanceKm(),
        route.durationSeconds(),
        BigDecimal.valueOf(15000 + (long) Math.ceil(route.distanceKm() * 3000)),
        route);
  }
}
