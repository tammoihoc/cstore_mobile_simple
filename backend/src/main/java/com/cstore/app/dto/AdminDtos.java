package com.cstore.app.dto;

import com.cstore.app.dto.AccountDtos.BranchView;
import com.cstore.app.entity.Role;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;

/** Dữ liệu nhận/gửi JSON cho nhóm Admin. Record chỉ mang dữ liệu, không phải bảng cơ sở dữ liệu. */
public final class AdminDtos {
  private AdminDtos() {}

  public record CreateStore(
      String name,
      @NotBlank String address,
      @NotNull @DecimalMin("-90") @DecimalMax("90") Double latitude,
      @NotNull @DecimalMin("-180") @DecimalMax("180") Double longitude,
      @AssertTrue boolean pinConfirmed,
      String brand,
      String branchName,
      Long existingStoreId,
      @Email @NotBlank String email,
      @NotBlank String fullName,
      @NotBlank @Size(min = 8, max = 72) String password) {
    @Override
    public String toString() {
      return "CreateStore[email=" + email + ", password=[redacted]]";
    }
  }

  public record CreateAccount(
      @Email @NotBlank String email,
      @NotBlank String fullName,
      @NotBlank @Size(min = 8, max = 72) String password,
      @NotNull Role role,
      Long storeId) {
    @Override
    public String toString() {
      return "CreateAccount[email=" + email + ", role=" + role + ", password=[redacted]]";
    }
  }

  public record AccessInput(@NotNull Boolean blocked) {}

  public record BranchRevenue(
      Long storeId,
      String name,
      String brand,
      String image,
      long completedOrders,
      BigDecimal grossSales,
      BigDecimal platformRevenue,
      boolean active) {}

  public record BrandView(
      String key, String name, String image, long branchCount, List<BranchView> branches) {}

  public record BrandRevenue(
      String key,
      String name,
      String image,
      long branchCount,
      long archivedBranchCount,
      long completedOrders,
      BigDecimal grossSales,
      BigDecimal platformRevenue,
      boolean active,
      List<BranchRevenue> branches) {}

  public record Revenue(
      BigDecimal commissionRate,
      long completedOrders,
      BigDecimal grossSales,
      BigDecimal platformRevenue,
      List<BranchRevenue> branches,
      long brandCount,
      long branchCount,
      List<BrandRevenue> brands,
      BrandRevenue topBrand) {}
}
