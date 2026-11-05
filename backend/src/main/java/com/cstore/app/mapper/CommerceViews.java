package com.cstore.app.mapper;

import com.cstore.app.dto.OrderDtos.EventView;
import com.cstore.app.dto.OrderDtos.LineView;
import com.cstore.app.dto.OrderDtos.OrderView;
import com.cstore.app.dto.ProductDtos.ProductView;
import com.cstore.app.entity.CustomerOrder;
import com.cstore.app.entity.Product;
import java.math.BigDecimal;

/**
 * Đổi entity sang DTO; chỉ đưa các trường cần thiết ra API, không lộ mật khẩu hay đối tượng JPA.
 */
public final class CommerceViews {
  private CommerceViews() {}

  public static ProductView view(Product product) {
    return new ProductView(
        product.id,
        product.name,
        product.price,
        product.stock,
        product.image,
        product.category == null ? "Khác" : product.category,
        product.active,
        product.store.id,
        product.store.name);
  }

  public static OrderView view(CustomerOrder order) {
    BigDecimal fee = order.fee == null ? BigDecimal.ZERO : order.fee;
    return new OrderView(
        order.id,
        order.store.id,
        order.customer.id,
        order.status,
        order.recipient,
        order.phone,
        order.address,
        order.latitude,
        order.longitude,
        order.total,
        fee,
        order.total.add(fee),
        order.distanceKm,
        order.durationSeconds,
        order.distanceSource,
        order.reason,
        order.shipper == null ? null : order.shipper.id,
        order.shipper == null ? null : order.shipper.fullName,
        order.shipper == null ? null : order.shipper.phone,
        order.shipper == null ? null : order.shipper.avatar,
        order.paidAt != null,
        order.paidBy == null ? null : order.paidBy.fullName,
        order.paidAt,
        order.createdAt,
        order.lines.stream()
            .map(line ->
                new LineView(
                    line.product.id,
                    line.productName == null ? line.product.name : line.productName,
                    line.quantity,
                    line.unitPrice,
                    line.productImage == null ? line.product.image : line.productImage))
            .toList(),
        order.history.stream().map(event -> new EventView(event.status, event.at)).toList());
  }
}
