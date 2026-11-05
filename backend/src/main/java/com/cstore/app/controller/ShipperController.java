package com.cstore.app.controller;

import static com.cstore.app.mapper.CommerceViews.view;
import static com.cstore.app.service.CommerceSupport.bad;
import static com.cstore.app.service.CommerceSupport.distance;
import static com.cstore.app.service.CommerceSupport.requireShipperPhoto;

import com.cstore.app.dto.DeliveryDtos.PositionInput;
import com.cstore.app.dto.DeliveryDtos.ShipperNavigation;
import com.cstore.app.dto.DeliveryDtos.ShipperState;
import com.cstore.app.dto.OrderDtos.OrderView;
import com.cstore.app.dto.OrderDtos.StatusInput;
import com.cstore.app.repository.Orders;
import com.cstore.app.repository.Users;
import com.cstore.app.service.CommerceSupport;
import com.cstore.app.service.RoutingService;
import jakarta.validation.Valid;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/** Vị trí shipper, danh sách đơn có thể nhận, nhận đơn và các bước giao hàng. */
@RestController
@RequestMapping("/api")
@Transactional(readOnly = true)
public class ShipperController {
  private final CommerceSupport support;
  private final Users users;
  private final Orders orders;
  private final RoutingService routing;

  public ShipperController(
      CommerceSupport support, Users users, Orders orders, RoutingService routing) {
    this.support = support;
    this.users = users;
    this.orders = orders;
    this.routing = routing;
  }

  @GetMapping("/shipper/orders/{id}/route")
  public ShipperNavigation navigation(Authentication authentication, @PathVariable Long id) {
    var shipper = support.current(authentication);
    var order =
        orders.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
    if (shipper.latitude == null || shipper.longitude == null) {
      throw bad("Cập nhật GPS trước khi xem đường đi");
    }
    if (order.shipper != null) {
      support.checkShipper(order, shipper);
    } else {
      if (!shipper.online
          || !order.status.equals("ACCEPTED")
          || order.store.latitude == null
          || order.store.longitude == null
          || distance(
                  shipper.latitude, shipper.longitude, order.store.latitude, order.store.longitude)
              > 5) {
        throw new ResponseStatusException(HttpStatus.FORBIDDEN);
      }
    }
    if (order.store.latitude == null
        || order.store.longitude == null
        || order.latitude == null
        || order.longitude == null) {
      throw bad("Đơn hàng chưa có tọa độ đầy đủ");
    }
    boolean picked = List.of("PICKED_UP", "DELIVERING", "DELIVERED").contains(order.status);
    var pickup =
        picked
            ? null
            : routing.route(
                shipper.latitude, shipper.longitude, order.store.latitude, order.store.longitude);
    if (order.shipper == null && pickup.distanceKm() > 5) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN);
    }
    var delivery =
        routing.route(
            picked ? shipper.latitude : order.store.latitude,
            picked ? shipper.longitude : order.store.longitude,
            order.latitude,
            order.longitude);
    String stage = order.status.equals("DELIVERED") ? "COMPLETED" : picked ? "DELIVERY" : "PICKUP";
    return new ShipperNavigation(
        stage,
        shipper.simulated,
        shipper.latitude,
        shipper.longitude,
        order.store.latitude,
        order.store.longitude,
        order.latitude,
        order.longitude,
        pickup,
        delivery,
        picked ? delivery : pickup);
  }

  @GetMapping("/shipper/state")
  public ShipperState shipperState(Authentication authentication) {
    var shipper = support.current(authentication);
    return new ShipperState(shipper.online, shipper.latitude, shipper.longitude, shipper.simulated);
  }

  @PutMapping("/shipper/location")
  @Transactional
  public ShipperState location(
      Authentication authentication, @Valid @RequestBody PositionInput input) {
    var shipper = users.locked(authentication.getName()).orElseThrow();
    if (input.online()) {
      requireShipperPhoto(shipper);
    }
    boolean keepSimulation =
        input.preserveSimulation()
            && shipper.simulated
            && Objects.equals(shipper.latitude, input.latitude())
            && Objects.equals(shipper.longitude, input.longitude());
    shipper.online = input.online();
    shipper.latitude = input.latitude();
    shipper.longitude = input.longitude();
    shipper.simulated = keepSimulation;
    return new ShipperState(shipper.online, shipper.latitude, shipper.longitude, shipper.simulated);
  }

  @GetMapping("/shipper/offers")
  public List<OrderView> offers(Authentication authentication) {
    var shipper = support.current(authentication);
    if (!shipper.online || shipper.latitude == null || shipper.longitude == null) {
      return List.of();
    }
    var result = new ArrayList<OrderView>();
    for (var order : orders.findByStatusOrderByIdDesc("ACCEPTED")) {
      if (order.shipper == null
          && order.store.isActive()
          && order.store.latitude != null
          && order.store.longitude != null
          && distance(
                  shipper.latitude, shipper.longitude, order.store.latitude, order.store.longitude)
              <= 5) {
        try {
          if (routing
                  .route(
                      shipper.latitude,
                      shipper.longitude,
                      order.store.latitude,
                      order.store.longitude)
                  .distanceKm()
              <= 5) {
            result.add(view(order));
          }
        } catch (ResponseStatusException e) {
          if (e.getStatusCode().value() != 400) {
            throw e;
          }
        }
      }
    }
    return result;
  }

  @PostMapping("/shipper/orders/{id}/claim")
  @Transactional
  public OrderView claim(Authentication authentication, @PathVariable Long id) {
    var shipper = users.locked(authentication.getName()).orElseThrow();
    requireShipperPhoto(shipper);
    var order = support.lockOrder(id);
    if (!order.store.isActive()
        || !shipper.online
        || shipper.latitude == null
        || shipper.longitude == null
        || order.shipper != null
        || !order.status.equals("ACCEPTED")
        || order.store.latitude == null
        || distance(
                shipper.latitude, shipper.longitude, order.store.latitude, order.store.longitude)
            > 5) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, "Không thể nhận đơn này");
    }
    if (routing
            .route(shipper.latitude, shipper.longitude, order.store.latitude, order.store.longitude)
            .distanceKm()
        > 5) {
      throw new ResponseStatusException(
          HttpStatus.CONFLICT, "Cửa hàng ngoài phạm vi 5 km đường đi");
    }
    if (orders.countByShipperIdAndStatusIn(
            shipper.id, List.of("ASSIGNED", "PICKED_UP", "DELIVERING"))
        >= 3) {
      throw bad("Đã đủ 3 đơn đang giao");
    }
    order.shipper = shipper;
    support.setStatus(order, "ASSIGNED");
    return view(order);
  }

  @PutMapping("/shipper/orders/{id}/status")
  @Transactional
  public OrderView deliveryStatus(
      Authentication authentication, @PathVariable Long id, @Valid @RequestBody StatusInput input) {
    var shipper = users.locked(authentication.getName()).orElseThrow();
    var order = support.lockOrder(id);
    support.checkShipper(order, shipper);
    String expected =
        switch (order.status) {
          case "ASSIGNED" -> "PICKED_UP";
          case "PICKED_UP" -> "DELIVERING";
          case "DELIVERING" -> "DELIVERED";
          default -> "";
        };
    if (!input.status().equals(expected)) {
      throw bad("Chuyển trạng thái không đúng thứ tự");
    }
    if (input.simulateArrival()) {
      if (!order.status.equals("ASSIGNED") || !input.status().equals("PICKED_UP")) {
        throw bad("Chỉ mô phỏng GPS tại bước đến cửa hàng nhận hàng");
      }
      shipper.latitude = order.store.latitude;
      shipper.longitude = order.store.longitude;
      shipper.simulated = true;
    }
    if (input.status().equals("DELIVERED") && order.paidAt == null) {
      throw bad("Cần xác nhận đã thu tiền trước khi hoàn thành");
    }
    support.setStatus(order, input.status());
    return view(order);
  }
}
