package com.cstore.app.controller;

import static com.cstore.app.mapper.CommerceViews.view;

import com.cstore.app.dto.ProductDtos.ProductInput;
import com.cstore.app.dto.ProductDtos.ProductView;
import com.cstore.app.entity.Product;
import com.cstore.app.mapper.CommerceViews;
import com.cstore.app.repository.Products;
import com.cstore.app.service.CommerceSupport;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Danh mục công khai và các thao tác sản phẩm của tài khoản cửa hàng. */
@RestController
@RequestMapping("/api")
@Transactional(readOnly = true)
public class ProductController {
  private final CommerceSupport support;
  private final Products products;

  public ProductController(CommerceSupport support, Products products) {
    this.support = support;
    this.products = products;
  }

  @GetMapping("/products")
  public List<ProductView> allProducts(@RequestParam(required = false) Long storeId) {
    return (storeId == null ? products.findAll() : products.findByStoreIdOrderByIdDesc(storeId))
        .stream()
            .filter(product -> product.active && product.store.isActive())
            .map(CommerceViews::view)
            .toList();
  }

  @GetMapping("/merchant/products")
  public List<ProductView> merchantProducts(Authentication authentication) {
    return products.findByStoreIdOrderByIdDesc(support.myStore(authentication).id).stream()
        .filter(product -> product.active)
        .map(CommerceViews::view)
        .toList();
  }

  @PostMapping("/merchant/products")
  @Transactional
  public ProductView create(Authentication authentication, @Valid @RequestBody ProductInput input) {
    var product =
        new Product(
            support.myStore(authentication),
            input.name().trim(),
            input.price(),
            input.stock(),
            null);
    product.category = input.category().trim();
    return view(products.save(product));
  }

  @PutMapping("/merchant/products/{id}")
  @Transactional
  public ProductView update(
      Authentication authentication,
      @PathVariable Long id,
      @Valid @RequestBody ProductInput input) {
    var product = support.ownedProduct(authentication, id);
    product.name = input.name().trim();
    product.price = input.price();
    product.stock = input.stock();
    product.category = input.category().trim();
    return view(product);
  }

  @DeleteMapping("/merchant/products/{id}")
  @Transactional
  public void delete(Authentication authentication, @PathVariable Long id) {
    support.ownedProduct(authentication, id).active = false;
  }
}
