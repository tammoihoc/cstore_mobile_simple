package com.cstore.app.controller;

import static com.cstore.app.service.CommerceSupport.bad;

import com.cstore.app.dto.AuthDtos.Login;
import com.cstore.app.dto.AuthDtos.Me;
import com.cstore.app.dto.AuthDtos.Register;
import com.cstore.app.dto.AuthDtos.Session;
import com.cstore.app.entity.AppUser;
import com.cstore.app.entity.Role;
import com.cstore.app.repository.Users;
import com.cstore.app.service.AccountService;
import com.cstore.app.service.CommerceSupport;
import jakarta.validation.Valid;
import java.util.Locale;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/** Các điểm vào đăng ký/đăng nhập email và thông tin tài khoản đang đăng nhập. */
@RestController
@RequestMapping("/api")
@Transactional(readOnly = true)
public class AuthController {
  private final Users users;
  private final PasswordEncoder passwords;
  private final AccountService accounts;
  private final CommerceSupport support;

  public AuthController(
      Users users, PasswordEncoder passwords, AccountService accounts, CommerceSupport support) {
    this.users = users;
    this.passwords = passwords;
    this.accounts = accounts;
    this.support = support;
  }

  @PostMapping("/auth/register")
  @Transactional
  public ResponseEntity<Me> register(@Valid @RequestBody Register input) {
    if (input.role() != Role.CUSTOMER && input.role() != Role.SHIPPER) {
      throw bad("Chỉ được đăng ký khách hàng hoặc shipper");
    }
    if (users.findByEmailIgnoreCase(input.email().trim()).isPresent()) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, "Email đã tồn tại");
    }
    var user =
        users.save(
            new AppUser(
                input.email().trim().toLowerCase(Locale.ROOT),
                passwords.encode(input.password()),
                input.fullName().trim(),
                input.role()));
    return ResponseEntity.status(HttpStatus.CREATED)
        .body(new Me(user.id, user.email, user.fullName, user.role));
  }

  @PostMapping("/auth/login")
  @Transactional(readOnly = true)
  public Session login(@Valid @RequestBody Login input) {
    AppUser user =
        users
            .findByEmailIgnoreCase(input.email().trim())
            .orElseThrow(() ->
                new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED, "Email hoặc mật khẩu không đúng"));
    if (user.passwordHash == null
        || user.passwordHash.startsWith("!")
        || !passwords.matches(input.password(), user.passwordHash)) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Email hoặc mật khẩu không đúng");
    }
    return accounts.session(user);
  }

  @GetMapping("/auth/me")
  public Me me(Authentication authentication) {
    var user = support.current(authentication);
    return new Me(user.id, user.email, user.fullName, user.role);
  }
}
