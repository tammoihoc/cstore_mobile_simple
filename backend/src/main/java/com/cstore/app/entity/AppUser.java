package com.cstore.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;

/** Tài khoản của mọi vai trò. Không trả trực tiếp entity này ra JSON vì có trường băm mật khẩu. */
@Entity(name = "AppUser")
@Table(name = "app_users")
@org.hibernate.annotations.DynamicUpdate
public class AppUser {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  public Long id;

  @Column(nullable = false, unique = true, length = 150)
  public String email;

  @Column(nullable = false)
  public String passwordHash;

  @Column(nullable = false)
  public String fullName;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false)
  public Role role;

  @ManyToOne public Store assignedStore;
  public boolean online = false;
  public Double latitude;
  public Double longitude;
  public boolean simulated = false;
  public boolean blocked = false;
  public boolean deleted = false;
  public String deliveryAddress;
  public Double deliveryLatitude;
  public Double deliveryLongitude;
  public String avatar;
  public String phone;
  public String gender = "UNSPECIFIED";

  @Column(updatable = false)
  public Instant createdAt = Instant.now();

  public Integer authVersion = 0;

  public int version() {
    return authVersion == null ? 0 : authVersion;
  }

  protected AppUser() {}

  public AppUser(String email, String passwordHash, String fullName, Role role) {
    this.email = email;
    this.passwordHash = passwordHash;
    this.fullName = fullName;
    this.role = role;
  }
}
