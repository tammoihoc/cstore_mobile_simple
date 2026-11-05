package com.cstore.app.repository;

import com.cstore.app.entity.SocialIdentity;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

/** Truy vấn liên kết theo cặp nhà cung cấp và mã định danh người dùng. */
public interface SocialIdentities extends JpaRepository<SocialIdentity, Long> {
  public Optional<SocialIdentity> findByProviderAndSubject(String provider, String subject);
}
