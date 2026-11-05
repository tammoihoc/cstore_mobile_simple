package com.cstore.app.controller;

import static com.cstore.app.support.BrandNames.brandName;
import static com.cstore.app.support.BrandNames.logo;
import static com.cstore.app.support.BrandNames.normalize;

import com.cstore.app.dto.AdminDtos.BranchRevenue;
import com.cstore.app.dto.AdminDtos.BrandRevenue;
import com.cstore.app.dto.AdminDtos.BrandView;
import com.cstore.app.dto.AdminDtos.Revenue;
import com.cstore.app.entity.CustomerOrder;
import com.cstore.app.entity.Store;
import com.cstore.app.mapper.BranchViews;
import com.cstore.app.repository.Orders;
import com.cstore.app.repository.Stores;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.TreeMap;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Tổng hợp doanh thu từ đơn đã giao và thu tiền; tách phí nền tảng 15% khỏi phí giao hàng. */
@RestController
@RequestMapping("/api")
@Transactional(readOnly = true)
public class AdminReportController {
  private final Stores stores;
  private final Orders orders;
  private static final BigDecimal COMMISSION_RATE = new BigDecimal("0.15");

  public AdminReportController(Stores stores, Orders orders) {
    this.stores = stores;
    this.orders = orders;
  }

  @GetMapping("/admin/brands")
  @Transactional(readOnly = true)
  public List<BrandView> brands() {
    Map<String, List<Store>> grouped = new TreeMap<>();
    for (var store : stores.findAll()) {
      if (store.isActive()) {
        grouped.computeIfAbsent(normalize(brandName(store)), key -> new ArrayList<>()).add(store);
      }
    }
    return grouped.entrySet().stream()
        .map(entry -> {
          var rows = entry.getValue();
          return new BrandView(
              entry.getKey(),
              brandName(rows.getFirst()),
              logo(rows),
              rows.size(),
              rows.stream().map(BranchViews::view).toList());
        })
        .toList();
  }

  @GetMapping("/admin/revenue")
  @Transactional(readOnly = true)
  public Revenue revenue() {
    // Chỉ đơn DELIVERED và đã thu tiền mới được tính vào doanh thu.
    Map<Long, List<CustomerOrder>> completed = new HashMap<>();
    for (var order : orders.findByStatusOrderByIdDesc("DELIVERED")) {
      if (order.paidAt != null) {
        completed.computeIfAbsent(order.store.id, key -> new ArrayList<>()).add(order);
      }
    }
    var all = stores.findAll();
    var branches =
        all.stream()
            .map(store -> {
              var eligible = completed.getOrDefault(store.id, List.of());
              BigDecimal gross =
                  eligible.stream()
                      .map(order -> order.total)
                      .reduce(BigDecimal.ZERO, BigDecimal::add);
              return new BranchRevenue(
                  store.id,
                  store.name,
                  brandName(store),
                  store.image,
                  eligible.size(),
                  gross,
                  gross.multiply(COMMISSION_RATE),
                  store.isActive());
            })
            .toList();
    Map<String, List<BranchRevenue>> groups = new TreeMap<>();
    for (var branch : branches) {
      groups.computeIfAbsent(normalize(branch.brand()), key -> new ArrayList<>()).add(branch);
    }
    var brands = new ArrayList<BrandRevenue>();
    for (var entry : groups.entrySet()) {
      var rows = entry.getValue();
      long activeCount = rows.stream().filter(BranchRevenue::active).count();
      BigDecimal gross =
          rows.stream().map(BranchRevenue::grossSales).reduce(BigDecimal.ZERO, BigDecimal::add);
      long count = rows.stream().mapToLong(BranchRevenue::completedOrders).sum();
      String image =
          rows.stream()
              .sorted(Comparator.comparing(BranchRevenue::active).reversed())
              .map(BranchRevenue::image)
              .filter(Objects::nonNull)
              .filter(value -> !value.isBlank())
              .findFirst()
              .orElse(null);
      brands.add(
          new BrandRevenue(
              entry.getKey(),
              rows.getFirst().brand(),
              image,
              activeCount,
              rows.size() - activeCount,
              count,
              gross,
              gross.multiply(COMMISSION_RATE),
              activeCount > 0,
              rows));
    }
    brands.sort(
        Comparator.comparing(BrandRevenue::grossSales).reversed().thenComparing(BrandRevenue::key));
    BigDecimal gross =
        branches.stream().map(BranchRevenue::grossSales).reduce(BigDecimal.ZERO, BigDecimal::add);
    long count = branches.stream().mapToLong(BranchRevenue::completedOrders).sum();
    var top =
        brands.stream().filter(branch -> branch.grossSales().signum() > 0).findFirst().orElse(null);
    return new Revenue(
        COMMISSION_RATE,
        count,
        gross,
        gross.multiply(COMMISSION_RATE),
        branches,
        brands.stream().filter(BrandRevenue::active).count(),
        branches.stream().filter(BranchRevenue::active).count(),
        List.copyOf(brands),
        top);
  }
}
