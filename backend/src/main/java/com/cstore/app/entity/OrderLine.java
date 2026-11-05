package com.cstore.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.math.BigDecimal;

/** Một dòng hàng. Tên, ảnh và giá được chụp lại lúc đặt để lịch sử không đổi theo sản phẩm. */
@Entity
@Table(name = "order_lines")
public class OrderLine {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  public Long id;

  @ManyToOne(optional = false)
  public CustomerOrder order;

  @ManyToOne(optional = false)
  public Product product;

  @Column(nullable = false)
  public int quantity;

  @Column(nullable = false, precision = 13, scale = 0)
  public BigDecimal unitPrice;

  public String productName;
  public String productImage;

  protected OrderLine() {}

  public OrderLine(CustomerOrder order, Product product, int quantity, BigDecimal unitPrice) {
    this.order = order;
    this.product = product;
    this.quantity = quantity;
    this.unitPrice = unitPrice;
    this.productName = product.name;
    this.productImage = product.image;
  }
}
