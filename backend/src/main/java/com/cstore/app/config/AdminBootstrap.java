package com.cstore.app.config;

import com.cstore.app.entity.AppUser;
import com.cstore.app.entity.Role;
import com.cstore.app.repository.Users;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class AdminBootstrap {
  @Bean
  public CommandLineRunner bootstrap(
      Users users,
      PasswordEncoder encoder,
      @Value("${ADMIN_EMAIL:}") String email,
      @Value("${ADMIN_PASSWORD:}") String password) {
    return args -> {
      if (!email.isBlank() && users.findByEmailIgnoreCase(email.trim()).isEmpty()) {
        if (password.length() < 12 || password.length() > 72) {
          throw new IllegalArgumentException("ADMIN_PASSWORD requires 12-72 characters");
        }
        users.save(
            new AppUser(
                email.trim().toLowerCase(), encoder.encode(password), "Quản trị viên", Role.ADMIN));
      }
    };
  }
}
