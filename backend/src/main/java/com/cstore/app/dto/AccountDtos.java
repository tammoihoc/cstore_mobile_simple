package com.cstore.app.dto;

import java.time.Instant;

/**
 * Dữ liệu nhận/gửi JSON cho nhóm Account. Record chỉ mang dữ liệu, không phải bảng cơ sở dữ liệu.
 */
public final class AccountDtos {
  private AccountDtos() {}

  public record Account(
      Long id,
      String email,
      String name,
      String role,
      Long storeId,
      boolean blocked,
      boolean deleted,
      boolean storeOwner,
      String avatar,
      String gender,
      String phone,
      boolean photoRequired,
      boolean passwordEnabled,
      Instant createdAt) {}

  public record BranchView(
      Long id,
      String name,
      String address,
      Double latitude,
      Double longitude,
      String brand,
      String image) {}
}
