package com.cstore.app.service;

import com.cstore.app.dto.AccountDtos.Account;
import com.cstore.app.dto.AuthDtos.Session;
import com.cstore.app.entity.AppUser;
import com.cstore.app.entity.Role;
import com.cstore.app.repository.Stores;
import com.cstore.app.repository.Users;
import java.time.Instant;
import java.util.Locale;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

/**
 * Tạo tài khoản, định dạng hồ sơ an toàn và phát hành phiên JWT sau khi kiểm tra trạng thái tài
 * khoản.
 */
@Service
public class AccountService {
  private final Users users;
  private final Stores stores;
  private final PasswordEncoder passwords;
  private final JwtEncoder jwt;

  public AccountService(Users users, Stores stores, PasswordEncoder passwords, JwtEncoder jwt) {
    this.users = users;
    this.stores = stores;
    this.passwords = passwords;
    this.jwt = jwt;
  }

  public Account account(AppUser user) {
    Long id =
        user.assignedStore == null
            ? stores.findByOwnerId(user.id).map(branch -> branch.id).orElse(null)
            : user.assignedStore.id;
    var store = id == null ? null : stores.findById(id).orElse(null);
    String avatar =
        (user.role == Role.STORE || user.role == Role.MERCHANT)
            ? (store == null ? null : store.image)
            : user.avatar;
    // DTO không bao gồm passwordHash. MERCHANT cũ được hiển thị thành STORE.
    return new Account(
        user.id,
        user.email,
        user.fullName,
        user.role == Role.MERCHANT ? "STORE" : user.role.name(),
        id,
        user.blocked,
        user.deleted,
        store != null && store.owner.id.equals(user.id),
        avatar,
        user.gender == null ? "UNSPECIFIED" : user.gender,
        user.phone,
        user.role == Role.SHIPPER && (user.avatar == null || user.avatar.isBlank()),
        user.passwordHash != null && !user.passwordHash.startsWith("!"),
        user.createdAt);
  }

  public Session session(AppUser user) {
    if (user.blocked || user.deleted) {
      throw new ResponseStatusException(
          HttpStatus.FORBIDDEN, "Tài khoản đã bị khóa hoặc xóa. Vui lòng liên hệ quản trị viên.");
    }
    if ((user.role == Role.STORE || user.role == Role.MERCHANT)
        && user.assignedStore != null
        && !user.assignedStore.isActive()) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chi nhánh đã ngừng hoạt động.");
    }
    // Token có hạn 8 giờ; ver giúp vô hiệu hóa token cũ sau khi đổi mật khẩu.
    var now = Instant.now();
    var claims =
        JwtClaimsSet.builder()
            .subject(user.email)
            .issuedAt(now)
            .expiresAt(now.plusSeconds(28800))
            .claim("role", user.role.name())
            .claim("ver", user.version())
            .build();
    String token =
        jwt.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims))
            .getTokenValue();
    return new Session(token, account(user));
  }

  public AppUser newUser(String inputEmail, String password, String fullName, Role role) {
    String email = inputEmail.trim().toLowerCase(Locale.ROOT);
    if (users.findByEmailIgnoreCase(email).isPresent()) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, "Email đã được sử dụng");
    }
    return users.save(new AppUser(email, passwords.encode(password), fullName.trim(), role));
  }
}
