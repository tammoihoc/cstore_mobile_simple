package com.cstore.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

/** Một chi nhánh cửa hàng, liên kết với chủ sở hữu và thương hiệu. */
@Entity
@Table(
    name = "stores",
    uniqueConstraints =
        @UniqueConstraint(
            name = "uk_store_brand_branch",
            columnNames = {"brand_key", "branch_key"}))
public class Store {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  public Long id;

  @Column(nullable = false)
  public String name;

  @ManyToOne(optional = false)
  public AppUser owner;

  public String brand;
  public String address;
  public Double latitude;
  public Double longitude;
  public String image;
  public boolean archived = false;

  @Column(name = "brand_key")
  public String brandKey;

  @Column(name = "branch_key")
  public String branchKey;

  protected Store() {}

  public Store(String name, AppUser owner) {
    this.name = name;
    this.owner = owner;
  }

  public boolean isActive() {
    return !archived && owner != null && !owner.deleted;
  }
}
