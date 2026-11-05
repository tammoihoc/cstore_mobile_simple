package com.cstore.app.dto;

import com.cstore.app.service.RoutingService;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

/**
 * Dữ liệu nhận/gửi JSON cho nhóm Delivery. Record chỉ mang dữ liệu, không phải bảng cơ sở dữ liệu.
 */
public final class DeliveryDtos {
  private DeliveryDtos() {}

  public record PositionInput(
      boolean online,
      @NotNull @DecimalMin("-90") @DecimalMax("90") Double latitude,
      @NotNull @DecimalMin("-180") @DecimalMax("180") Double longitude,
      boolean preserveSimulation) {}

  public record ShipperState(
      boolean online, Double latitude, Double longitude, boolean simulated) {}

  public record DeliveryLocation(
      @NotBlank String address,
      @NotNull @DecimalMin("-90") @DecimalMax("90") Double latitude,
      @NotNull @DecimalMin("-180") @DecimalMax("180") Double longitude,
      @AssertTrue boolean pinConfirmed) {}

  public record QuoteInput(
      @NotNull Long storeId,
      @NotNull @DecimalMin("-90") @DecimalMax("90") Double latitude,
      @NotNull @DecimalMin("-180") @DecimalMax("180") Double longitude) {}

  public record DeliveryQuote(
      Long storeId,
      double distanceKm,
      double durationSeconds,
      BigDecimal fee,
      RoutingService.RoadRoute route) {}

  public record NearbyBranch(
      Long storeId, double distanceKm, double durationSeconds, BigDecimal fee) {}

  public record ShipperNavigation(
      String stage,
      boolean simulated,
      double shipperLatitude,
      double shipperLongitude,
      double storeLatitude,
      double storeLongitude,
      double customerLatitude,
      double customerLongitude,
      RoutingService.RoadRoute pickupRoute,
      RoutingService.RoadRoute deliveryRoute,
      RoutingService.RoadRoute activeRoute) {}
}
