package com.cstore.app.controller;

import static com.cstore.app.mapper.CommerceViews.view;
import static com.cstore.app.service.CommerceSupport.bad;

import com.cstore.app.dto.OrderDtos.OrderInput;
import com.cstore.app.dto.OrderDtos.OrderItemInput;
import com.cstore.app.dto.OrderDtos.OrderView;
import com.cstore.app.dto.OrderDtos.StatusInput;
import com.cstore.app.entity.CustomerOrder;
import com.cstore.app.entity.OrderLine;
import com.cstore.app.entity.Role;
import com.cstore.app.entity.StatusEvent;
import com.cstore.app.entity.Store;
import com.cstore.app.mapper.CommerceViews;
import com.cstore.app.repository.Orders;
import com.cstore.app.repository.Products;
import com.cstore.app.repository.Stores;
import com.cstore.app.service.CommerceSupport;
import com.cstore.app.service.DeliveryService;
import jakarta.validation.Valid;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
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

/** Tạo, xem, chấp nhận, hủy và xác nhận thanh toán đơn hàng. */
@RestController
@RequestMapping("/api")
@Transactional(readOnly = true)
public class OrderController {
  private final CommerceSupport support;
  private final Stores stores;
  private final Products products;
  private final Orders orders;
  private final DeliveryService delivery;

  public OrderController(
      CommerceSupport support,
      Stores stores,
      Products products,
      Orders orders,
      DeliveryService delivery) {
    this.support = support;
    this.stores = stores;
    this.products = products;
    this.orders = orders;
    this.delivery = delivery;
  }

  @PostMapping("/customer/orders")
  @Transactional
  public OrderView checkout(Authentication authentication, @Valid @RequestBody OrderInput input) {
    var store =
        stores
            .findById(input.storeId())
            .filter(Store::isActive)
            .orElseThrow(() -> bad("Cửa hàng đã ngừng hoạt động hoặc không tồn tại"));
    if (store.latitude == null || store.longitude == null) {
      throw bad("Chi nhánh chưa ghim vị trí");
    }
    // Phí lấy từ tuyến đường thực tế trước khi bắt đầu trừ tồn kho.
    var quote = delivery.quote(store, input.latitude(), input.longitude());
    double km = quote.distanceKm();
    var buyer = support.current(authentication);
    buyer.deliveryAddress = input.address().trim();
    buyer.deliveryLatitude = input.latitude();
    buyer.deliveryLongitude = input.longitude();
    var order = new CustomerOrder(buyer, store);
    order.recipient = input.recipient().trim();
    order.phone = input.phone();
    order.address = input.address().trim();
    order.latitude = input.latitude();
    order.longitude = input.longitude();
    order.distanceKm = km;
    order.durationSeconds = quote.durationSeconds();
    order.distanceSource = "ROAD";
    order.fee = quote.fee();
    Set<Long> seen = new HashSet<>();
    // Khóa sản phẩm theo cùng thứ tự ID để hai giỏ hàng không chờ khóa chéo nhau.
    // Mọi thay đổi tồn kho và dòng đơn đều nằm trong giao dịch @Transactional này.
    for (var item :
        input.items().stream().sorted(Comparator.comparing(OrderItemInput::productId)).toList()) {
      if (!seen.add(item.productId())) {
        throw bad("Sản phẩm bị trùng");
      }
      var product =
          products.locked(item.productId()).orElseThrow(() -> bad("Sản phẩm không tồn tại"));
      if (!product.store.id.equals(store.id) || !product.active) {
        throw bad("Sản phẩm không thuộc chi nhánh hoặc ngừng bán");
      }
      if (product.stock < item.quantity()) {
        throw new ResponseStatusException(HttpStatus.CONFLICT, "Không đủ tồn kho: " + product.name);
      }
      product.stock -= item.quantity();
      order.lines.add(new OrderLine(order, product, item.quantity(), product.price));
      order.total = order.total.add(product.price.multiply(BigDecimal.valueOf(item.quantity())));
    }
    order.history.add(new StatusEvent("PENDING"));
    return view(orders.save(order));
  }

  @GetMapping("/customer/orders")
  public List<OrderView> customerOrders(Authentication authentication) {
    return orders.findByCustomerIdOrderByIdDesc(support.current(authentication).id).stream()
        .map(CommerceViews::view)
        .toList();
  }

  @GetMapping("/merchant/orders")
  public List<OrderView> merchantOrders(Authentication authentication) {
    return orders.findByStoreIdOrderByIdDesc(support.myStore(authentication).id).stream()
        .map(CommerceViews::view)
        .toList();
  }

  @GetMapping("/shipper/orders")
  public List<OrderView> shipperOrders(Authentication authentication) {
    return orders.findByShipperIdOrderByIdDesc(support.current(authentication).id).stream()
        .map(CommerceViews::view)
        .toList();
  }

  @PutMapping("/merchant/orders/{id}/status")
  @Transactional
  public OrderView storeStatus(
      Authentication authentication, @PathVariable Long id, @Valid @RequestBody StatusInput input) {
    var order = support.lockOrder(id);
    if (!order.store.id.equals(support.myStore(authentication).id)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN);
    }
    if (!order.status.equals("PENDING")
        || !List.of("ACCEPTED", "REJECTED").contains(input.status())) {
      throw bad("Chỉ xử lý đơn đang chờ");
    }
    if (input.status().equals("REJECTED")) {
      if (input.reason() == null || input.reason().isBlank()) {
        throw bad("Cần lý do từ chối");
      }
      support.restore(order);
      order.reason = input.reason().trim();
    }
    support.setStatus(order, input.status());
    return view(order);
  }

  @PutMapping("/customer/orders/{id}/cancel")
  @Transactional
  public OrderView cancel(Authentication authentication, @PathVariable Long id) {
    var order = support.lockOrder(id);
    if (!order.customer.id.equals(support.current(authentication).id)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN);
    }
    if (!order.status.equals("PENDING")) {
      throw bad("Chỉ hủy đơn đang chờ");
    }
    support.restore(order);
    order.reason = "Khách hàng hủy";
    support.setStatus(order, "CANCELLED");
    return view(order);
  }

  @PutMapping({"/merchant/orders/{id}/payment", "/shipper/orders/{id}/payment"})
  @Transactional
  public OrderView payment(Authentication authentication, @PathVariable Long id) {
    var order = support.lockOrder(id);
    var user = support.current(authentication);
    if (order.paidAt != null) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, "Đơn đã được xác nhận thanh toán");
    }
    if (user.role == Role.SHIPPER) {
      support.checkShipper(order, user);
      if (!List.of("PICKED_UP", "DELIVERING").contains(order.status)) {
        throw bad("Chưa được xác nhận thu COD");
      }
    } else {
      if (!order.store.id.equals(support.myStore(authentication).id)) {
        throw new ResponseStatusException(HttpStatus.FORBIDDEN);
      }
      if (List.of("PENDING", "REJECTED", "CANCELLED").contains(order.status)) {
        throw bad("Đơn chưa được chấp nhận");
      }
    }
    // Ghi nhận thu tiền riêng; trạng thái DELIVERED vẫn do luồng giao hàng quyết định.
    order.paidAt = Instant.now();
    order.paidBy = user;
    return view(order);
  }
}
