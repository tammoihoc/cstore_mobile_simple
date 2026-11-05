package com.cstore.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

/** Liên kết một danh tính mạng xã hội với tài khoản nội bộ. */
@Entity
@Table(
    name = "social_identities",
    uniqueConstraints =
        @UniqueConstraint(
            name = "uk_social_provider_subject",
            columnNames = {"provider", "provider_subject"}))
public class SocialIdentity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  public Long id;

  @Column(nullable = false, length = 16)
  public String provider;

  @Column(name = "provider_subject", nullable = false, length = 255)
  public String subject;

  @ManyToOne(optional = false)
  public AppUser user;

  protected SocialIdentity() {}

  public SocialIdentity(String provider, String subject, AppUser user) {
    this.provider = provider;
    this.subject = subject;
    this.user = user;
  }
}
