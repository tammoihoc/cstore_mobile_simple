package com.cstore.app.config;

import com.cstore.app.repository.Users;
import com.nimbusds.jose.jwk.source.ImmutableSecret;
import java.nio.charset.StandardCharsets;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {
  @Bean
  public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
  }

  @Bean
  public SecretKey jwtKey(@Value("${JWT_SECRET}") String secret) {
    if (secret.length() < 32) {
      throw new IllegalArgumentException("JWT_SECRET requires at least 32 characters");
    }
    return new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
  }

  @Bean
  public JwtEncoder jwtEncoder(SecretKey key) {
    return new NimbusJwtEncoder(new ImmutableSecret<>(key));
  }

  @Bean
  public JwtDecoder jwtDecoder(SecretKey key, Users users) {
    var decoder = NimbusJwtDecoder.withSecretKey(key).macAlgorithm(MacAlgorithm.HS256).build();
    OAuth2TokenValidator<Jwt> activeAccount =
        token ->
            users
                .findByEmailIgnoreCase(token.getSubject())
                .filter(u -> !u.blocked && !u.deleted && tokenVersion(token) == u.version())
                .map(u -> OAuth2TokenValidatorResult.success())
                .orElseGet(() ->
                    OAuth2TokenValidatorResult.failure(
                        new OAuth2Error(
                            "invalid_token", "Tài khoản không còn được phép đăng nhập", null)));
    decoder.setJwtValidator(
        new DelegatingOAuth2TokenValidator<>(JwtValidators.createDefault(), activeAccount));
    return decoder;
  }

  public static long tokenVersion(Jwt token) {
    Object value = token.getClaim("ver");
    return value == null ? 0 : value instanceof Number n ? n.longValue() : -1;
  }

  @Bean
  public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    var roles = new JwtGrantedAuthoritiesConverter();
    roles.setAuthoritiesClaimName("role");
    roles.setAuthorityPrefix("ROLE_");
    var converter = new JwtAuthenticationConverter();
    converter.setJwtGrantedAuthoritiesConverter(roles);
    return http.csrf(c -> c.disable())
        .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .authorizeHttpRequests(a ->
            a.requestMatchers(
                    HttpMethod.POST, "/api/auth/login", "/api/auth/register", "/api/auth/social")
                .permitAll()
                .requestMatchers(
                    HttpMethod.GET,
                    "/api/products",
                    "/api/branches",
                    "/api/images/**",
                    "/api/auth/providers")
                .permitAll()
                .requestMatchers("/api/admin/**")
                .hasRole("ADMIN")
                .requestMatchers("/api/merchant/**")
                .hasAnyRole("STORE", "MERCHANT")
                .requestMatchers("/api/customer/**")
                .hasRole("CUSTOMER")
                .requestMatchers("/api/shipper/**")
                .hasRole("SHIPPER")
                .anyRequest()
                .authenticated())
        .oauth2ResourceServer(o -> o.jwt(j -> j.jwtAuthenticationConverter(converter)))
        .build();
  }
}
