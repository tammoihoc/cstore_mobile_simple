package com.cstore.app.security;

import com.cstore.app.dto.VerifiedSocialIdentity;
import java.time.Instant;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.server.ResponseStatusException;

@Component
public class GoogleIdentityVerifier {
  private final String clientId;
  private final JwtDecoder decoder;

  @Autowired
  public GoogleIdentityVerifier(
      @Value("${GOOGLE_CLIENT_ID:${CSTORE_GOOGLE_CLIENT_ID:}}") String clientId) {
    this(
        clientId,
        NimbusJwtDecoder.withJwkSetUri("https://www.googleapis.com/oauth2/v3/certs")
            .restOperations(http())
            .build());
  }

  public GoogleIdentityVerifier(String clientId, JwtDecoder decoder) {
    this.clientId = clientId.trim();
    this.decoder = decoder;
  }

  public static RestTemplate http() {
    var factory = new SimpleClientHttpRequestFactory();
    factory.setConnectTimeout(5000);
    factory.setReadTimeout(5000);
    return new RestTemplate(factory);
  }

  public boolean enabled() {
    return !clientId.isBlank();
  }

  public VerifiedSocialIdentity verify(String token) {
    if (!enabled()) {
      throw new ResponseStatusException(
          HttpStatus.SERVICE_UNAVAILABLE,
          "Đăng nhập Google chưa được cấu hình. Bạn vẫn có thể đăng nhập bằng email.");
    }
    try {
      // Nimbus kiểm tra chữ ký bằng khóa công khai lấy từ endpoint Google đã cấu hình.
      Jwt jwt = decoder.decode(token);
      String issuer = jwt.getClaimAsString("iss");
      if (!("accounts.google.com".equals(issuer) || "https://accounts.google.com".equals(issuer))
          || jwt.getAudience() == null
          || !jwt.getAudience().contains(clientId)
          || jwt.getExpiresAt() == null
          || !jwt.getExpiresAt().isAfter(Instant.now())
          || jwt.getIssuedAt() == null
          || jwt.getIssuedAt().isAfter(Instant.now().plusSeconds(60))
          || !Boolean.TRUE.equals(jwt.getClaimAsBoolean("email_verified"))) {
        throw invalid();
      }
      return identity(
          jwt.getSubject(), jwt.getClaimAsString("email"), jwt.getClaimAsString("name"));
    } catch (JwtException | IllegalArgumentException exception) {
      // Không đưa chi tiết token/lỗi nhà cung cấp ra phản hồi cho ứng dụng.
      throw invalid();
    }
  }

  public static VerifiedSocialIdentity identity(String subject, String email, String name) {
    if (subject == null
        || subject.isBlank()
        || subject.length() > 255
        || email == null
        || email.length() > 150
        || !email.matches("[^\\s@]+@[^\\s@]+\\.[^\\s@]+")) {
      throw invalid();
    }
    String displayName = name == null || name.isBlank() ? "Khách hàng" : name.trim();
    if (displayName.length() > 255) {
      displayName = displayName.substring(0, 255);
    }
    return new VerifiedSocialIdentity(subject, email, displayName);
  }

  public static ResponseStatusException invalid() {
    return new ResponseStatusException(
        HttpStatus.UNAUTHORIZED,
        "Không xác minh được đăng nhập mạng xã hội. Vui lòng đăng nhập lại.");
  }
}
