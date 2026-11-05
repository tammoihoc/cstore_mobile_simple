package com.cstore.app.controller;

import com.cstore.app.dto.AuthDtos;
import com.cstore.app.dto.VerifiedSocialIdentity;
import com.cstore.app.security.FacebookIdentityVerifier;
import com.cstore.app.security.GoogleIdentityVerifier;
import com.cstore.app.service.AccountService;
import com.cstore.app.service.SocialAccounts;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class SocialAuthController {
  private final GoogleIdentityVerifier google;
  private final FacebookIdentityVerifier facebook;
  private final SocialAccounts accounts;
  private final AccountService sessions;

  public SocialAuthController(
      GoogleIdentityVerifier google,
      FacebookIdentityVerifier facebook,
      SocialAccounts accounts,
      AccountService sessions) {
    this.google = google;
    this.facebook = facebook;
    this.accounts = accounts;
    this.sessions = sessions;
  }

  public record SocialLogin(
      @NotBlank @Pattern(regexp = "google|facebook") String provider,
      @NotBlank @Size(max = 16384) String token) {
    @Override
    public String toString() {
      return "SocialLogin[provider=" + provider + ", token=[redacted]]";
    }
  }

  @GetMapping("/providers")
  public Map<String, Boolean> providers() {
    return Map.of("google", google.enabled(), "facebook", facebook.enabled());
  }

  @PostMapping("/social")
  public AuthDtos.Session login(@Valid @RequestBody SocialLogin input) {
    VerifiedSocialIdentity identity =
        input.provider().equals("google")
            ? google.verify(input.token())
            : facebook.verify(input.token());
    return sessions.session(accounts.resolve(input.provider(), identity));
  }
}
