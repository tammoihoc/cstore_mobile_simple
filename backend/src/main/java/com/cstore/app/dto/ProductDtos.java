package com.cstore.app.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

/**
 * Dữ liệu nhận/gửi JSON cho nhóm Product. Record chỉ mang dữ liệu, không phải bảng cơ sở dữ liệu.
 */
public final class ProductDtos {
  private ProductDtos() {}

  public record ProductView(
      Long id,
      String name,
      BigDecimal price,
      int stock,
      String image,
      String category,
      boolean active,
      Long storeId,
      String storeName) {}

  public record ProductInput(
      @NotBlank String name,
      @NotNull @DecimalMin("1") BigDecimal price,
      @Min(0) int stock,
      @NotBlank String category) {}
}
