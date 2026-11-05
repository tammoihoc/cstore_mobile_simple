package com.cstore.app.service;

import com.cstore.app.dto.VerifiedSocialIdentity;
import com.cstore.app.entity.AppUser;
import com.cstore.app.entity.Role;
import com.cstore.app.entity.SocialIdentity;
import com.cstore.app.repository.SocialIdentities;
import com.cstore.app.repository.Users;
import java.util.Locale;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Liên kết danh tính mạng xã hội đã xác minh với tài khoản nội bộ trong một giao dịch. */
@Service
public class SocialAccounts {
  private final Users users;
  private final SocialIdentities identities;

  public SocialAccounts(Users users, SocialIdentities identities) {
    this.users = users;
    this.identities = identities;
  }

  @Transactional
  public AppUser resolve(String provider, VerifiedSocialIdentity identity) {
    var existing = identities.findByProviderAndSubject(provider, identity.subject());
    if (existing.isPresent()) {
      return existing.get().user;
    }
    String email = identity.email().trim().toLowerCase(Locale.ROOT);
    AppUser user =
        users
            .findByEmailIgnoreCase(email)
            .orElseGet(() ->
                users.saveAndFlush(
                    new AppUser(email, "!SOCIAL_LOGIN_ONLY!", identity.name(), Role.CUSTOMER)));
    identities.saveAndFlush(new SocialIdentity(provider, identity.subject(), user));
    return user;
  }
}
