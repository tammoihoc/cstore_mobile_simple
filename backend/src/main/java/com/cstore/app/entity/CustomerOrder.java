package com.cstore.app.entity;

import jakarta.persistence.CascadeType;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderColumn;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/** Đơn hàng cùng thông tin giao nhận, thanh toán và lịch sử trạng thái. */
@Entity
@Table(name = "customer_orders")
public class CustomerOrder {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  public Long id;

  @ManyToOne(optional = false)
  public AppUser customer;

  @ManyToOne(optional = false)
  public Store store;

  @Column(nullable = false)
  public Instant createdAt = Instant.now();

  @Column(nullable = false)
  public String status = "PENDING";

  @Column(nullable = false, precision = 13, scale = 0)
  public BigDecimal total = BigDecimal.ZERO;

  @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
  public List<OrderLine> lines = new ArrayList<>();

  public String recipient;
  public String phone;
  public String address;
  public Double latitude;
  public Double longitude;

  @Column(precision = 13, scale = 0)
  public BigDecimal fee = BigDecimal.ZERO;

  public Double distanceKm;
  public Double durationSeconds;
  public String distanceSource;
  public String reason;
  @ManyToOne public AppUser shipper;
  @ManyToOne public AppUser paidBy;
  public Instant paidAt;

  @ElementCollection
  @CollectionTable(name = "order_status_history", joinColumns = @JoinColumn(name = "order_id"))
  @OrderColumn(name = "sequence_number")
  public List<StatusEvent> history = new ArrayList<>();

  protected CustomerOrder() {}

  public CustomerOrder(AppUser customer, Store store) {
    this.customer = customer;
    this.store = store;
  }
}
