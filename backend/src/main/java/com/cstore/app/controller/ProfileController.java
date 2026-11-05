package com.cstore.app.controller;

import com.cstore.app.dto.AccountDtos;
import com.cstore.app.dto.AuthDtos;
import com.cstore.app.repository.Users;
import com.cstore.app.service.AccountService;
import com.cstore.app.service.CommerceSupport;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/account")
@Transactional
public class ProfileController {
  private final CommerceSupport api;
  private final AccountService accounts;
  private final Users users;
  private final PasswordEncoder passwords;

  public ProfileController(
      CommerceSupport api, AccountService accounts, Users users, PasswordEncoder passwords) {
    this.api = api;
    this.accounts = accounts;
    this.users = users;
    this.passwords = passwords;
  }

  public record ProfileInput(
      @NotBlank @Size(max = 100) String name,
      @Pattern(regexp = "^$|0[0-9]{9}") String phone,
      @Pattern(regexp = "MALE|FEMALE|UNSPECIFIED") String gender) {}

  public record PasswordInput(
      @NotBlank String currentPassword, @NotBlank @Size(min = 8, max = 72) String newPassword) {
    @Override
    public String toString() {
      return "PasswordInput[currentPassword=[redacted], newPassword=[redacted]]";
    }
  }

  @GetMapping("/profile")
  @Transactional(readOnly = true)
  public AccountDtos.Account profile(Authentication auth) {
    return accounts.account(api.current(auth));
  }

  @PutMapping("/profile")
  public AccountDtos.Account update(Authentication auth, @Valid @RequestBody ProfileInput input) {
    var user = users.locked(auth.getName()).orElseThrow();
    user.fullName = input.name().trim();
    if (input.phone() != null) {
      user.phone = input.phone().isBlank() ? null : input.phone();
    }
    if (input.gender() != null) {
      user.gender = input.gender();
    }
    return accounts.account(user);
  }

  @PutMapping("/password")
  public AuthDtos.Session password(Authentication auth, @Valid @RequestBody PasswordInput input) {
    var user = users.locked(auth.getName()).orElseThrow();
    if (user.passwordHash == null || user.passwordHash.startsWith("!")) {
      throw new ResponseStatusException(
          HttpStatus.BAD_REQUEST,
          "Tài khoản này đăng nhập bằng mạng xã hội. Quản lý mật khẩu tại nhà cung cấp đăng nhập.");
    }
    if (!passwords.matches(input.currentPassword(), user.passwordHash)) {
      throw CommerceSupport.bad("Mật khẩu hiện tại không đúng.");
    }
    if (input.newPassword().getBytes(java.nio.charset.StandardCharsets.UTF_8).length > 72) {
      throw CommerceSupport.bad("Mật khẩu mới quá dài, vui lòng rút ngắn.");
    }
    if (passwords.matches(input.newPassword(), user.passwordHash)) {
      throw CommerceSupport.bad("Chọn mật khẩu mới khác mật khẩu hiện tại.");
    }
    user.passwordHash = passwords.encode(input.newPassword());
    user.authVersion = user.version() + 1;
    return accounts.session(user);
  }
}
