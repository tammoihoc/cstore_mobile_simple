package com.cstore.app.dto;

import com.cstore.app.dto.AccountDtos.Account;
import com.cstore.app.entity.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Dữ liệu nhận/gửi JSON cho nhóm Auth. Record chỉ mang dữ liệu, không phải bảng cơ sở dữ liệu. */
public final class AuthDtos {
  private AuthDtos() {}

  public record Register(
      @Email @NotBlank String email,
      @NotBlank String fullName,
      @NotBlank @Size(min = 8, max = 72) String password,
      Role role) {
    @Override
    public String toString() {
      return "Register[email=" + email + ", role=" + role + ", password=[redacted]]";
    }
  }

  public record Me(Long id, String email, String name, Role role) {}

  public record Login(@NotBlank String email, @NotBlank String password) {
    @Override
    public String toString() {
      return "Login[email=" + email + ", password=[redacted]]";
    }
  }

  public record Session(String token, Account user) {
    @Override
    public String toString() {
      return "Session[token=[redacted], user=" + user + "]";
    }
  }
}
