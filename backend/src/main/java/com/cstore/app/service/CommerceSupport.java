package com.cstore.app.service;

import com.cstore.app.entity.AppUser;
import com.cstore.app.entity.CustomerOrder;
import com.cstore.app.entity.Product;
import com.cstore.app.entity.Role;
import com.cstore.app.entity.StatusEvent;
import com.cstore.app.entity.Store;
import com.cstore.app.repository.Orders;
import com.cstore.app.repository.Products;
import com.cstore.app.repository.Stores;
import com.cstore.app.repository.Users;
import java.util.Comparator;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

/**
 * Các thao tác dùng chung: tìm tài khoản hiện tại, kiểm tra quyền sở hữu và khóa bản ghi.
 * Controller phải mở giao dịch trước khi gọi các thao tác ghi.
 */
@Service
public class CommerceSupport {
  private final Users users;
  private final Stores stores;
  private final Products products;
  private final Orders orders;

  public CommerceSupport(Users users, Stores stores, Products products, Orders orders) {
    this.users = users;
    this.stores = stores;
    this.products = products;
    this.orders = orders;
  }

  public static ResponseStatusException bad(String message) {
    return new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
  }

  public static void validCoordinates(double latitude, double longitude) {
    if (!Double.isFinite(latitude)
        || !Double.isFinite(longitude)
        || latitude < -90
        || latitude > 90
        || longitude < -180
        || longitude > 180) {
      throw bad("Tọa độ không hợp lệ");
    }
  }

  public static void requireShipperPhoto(AppUser user) {
    if (user.avatar == null || user.avatar.isBlank()) {
      throw bad("Thêm ảnh đại diện của bạn trong Hồ sơ trước khi trực tuyến hoặc nhận đơn mới.");
    }
  }

  public Product ownedProduct(Authentication a, Long id) {
    var p =
        products.locked(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
    if (!p.store.id.equals(myStore(a).id)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN);
    }
    return p;
  }

  public AppUser current(Authentication a) {
    return users
        .findByEmailIgnoreCase(a.getName())
        .filter(u -> !u.blocked && !u.deleted)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
  }

  public Store myStore(Authentication a) {
    var u = current(a);
    if (u.role != Role.STORE && u.role != Role.MERCHANT) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN);
    }
    var store =
        u.assignedStore != null
            ? u.assignedStore
            : stores.findByOwnerId(u.id).orElseThrow(() -> bad("Chưa gán chi nhánh"));
    if (!store.isActive()) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Cửa hàng đã ngừng hoạt động");
    }
    return store;
  }

  public CustomerOrder lockOrder(Long id) {
    return orders.locked(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
  }

  public void checkShipper(CustomerOrder o, AppUser u) {
    if (o.shipper == null || !o.shipper.id.equals(u.id)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN);
    }
  }

  /** Hoàn kho theo thứ tự khóa như lúc đặt hàng, chỉ gọi khi giao dịch đang mở. */
  public void restore(CustomerOrder o) {
    for (var l : o.lines.stream().sorted(Comparator.comparing(l -> l.product.id)).toList()) {
      var p = products.locked(l.product.id).orElseThrow();
      p.stock += l.quantity;
    }
  }

  public void setStatus(CustomerOrder o, String status) {
    o.status = status;
    o.history.add(new StatusEvent(status));
  }

  /** Khoảng cách thẳng Haversine để sàng lọc; không dùng để tính phí giao hàng. */
  public static double distance(double lat1, double lon1, double lat2, double lon2) {
    double a =
        Math.pow(Math.sin(Math.toRadians(lat2 - lat1) / 2), 2)
            + Math.cos(Math.toRadians(lat1))
                * Math.cos(Math.toRadians(lat2))
                * Math.pow(Math.sin(Math.toRadians(lon2 - lon1) / 2), 2);
    return 6371 * 2 * Math.asin(Math.sqrt(Math.min(1, a)));
  }
}
