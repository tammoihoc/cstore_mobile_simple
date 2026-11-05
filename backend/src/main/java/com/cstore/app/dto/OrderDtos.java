package com.cstore.app.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/** Dữ liệu nhận/gửi JSON cho nhóm Order. Record chỉ mang dữ liệu, không phải bảng cơ sở dữ liệu. */
public final class OrderDtos {
  private OrderDtos() {}

  public record OrderItemInput(@NotNull Long productId, @Min(1) int quantity) {}

  public record OrderInput(
      @NotNull Long storeId,
      @NotEmpty List<@Valid OrderItemInput> items,
      @NotBlank String recipient,
      @Pattern(regexp = "0[0-9]{9}") @NotBlank String phone,
      @NotBlank String address,
      @NotNull @DecimalMin("-90") @DecimalMax("90") Double latitude,
      @NotNull @DecimalMin("-180") @DecimalMax("180") Double longitude,
      @AssertTrue boolean pinConfirmed) {}

  public record LineView(
      Long productId, String name, int quantity, BigDecimal unitPrice, String image) {}

  public record EventView(String status, Instant at) {}

  public record OrderView(
      Long id,
      Long storeId,
      Long customerId,
      String status,
      String recipient,
      String phone,
      String address,
      Double latitude,
      Double longitude,
      BigDecimal subtotal,
      BigDecimal fee,
      BigDecimal total,
      Double distanceKm,
      Double durationSeconds,
      String distanceSource,
      String reason,
      Long shipperId,
      String shipperName,
      String shipperPhone,
      String shipperAvatar,
      boolean paid,
      String paidBy,
      Instant paidAt,
      Instant createdAt,
      List<LineView> items,
      List<EventView> history) {}

  public record StatusInput(@NotBlank String status, String reason, boolean simulateArrival) {}
}
