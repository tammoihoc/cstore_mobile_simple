package com.cstore.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.math.BigDecimal;

/** Sản phẩm thuộc đúng một chi nhánh; tồn kho chỉ giảm bên trong giao dịch tạo đơn. */
@Entity
@Table(name = "products")
public class Product {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  public Long id;

  @ManyToOne(optional = false)
  public Store store;

  @Column(nullable = false)
  public String name;

  @Column(nullable = false, precision = 13, scale = 0)
  public BigDecimal price;

  @Column(nullable = false)
  public int stock;

  public String image;
  public String category;
  public boolean active = true;

  protected Product() {}

  public Product(Store store, String name, BigDecimal price, int stock, String image) {
    this.store = store;
    this.name = name;
    this.price = price;
    this.stock = stock;
    this.image = image;
  }
}
