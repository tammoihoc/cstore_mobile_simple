package com.cstore.app.controller;

import static com.cstore.app.support.BrandNames.normalize;
import static com.cstore.app.support.BrandNames.safeBrand;

import com.cstore.app.dto.AccountDtos.Account;
import com.cstore.app.dto.AdminDtos.CreateStore;
import com.cstore.app.entity.AppUser;
import com.cstore.app.entity.Role;
import com.cstore.app.entity.Store;
import com.cstore.app.repository.Stores;
import com.cstore.app.service.AccountService;
import com.cstore.app.service.CommerceSupport;
import jakarta.validation.Valid;
import java.util.Objects;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/** Tạo thương hiệu/chi nhánh và tài khoản phụ trách, tái sử dụng logo của cùng thương hiệu. */
@RestController
@RequestMapping("/api")
@Transactional(readOnly = true)
public class AdminStoreController {
  private final Stores stores;
  private final AccountService accountService;

  public AdminStoreController(Stores stores, AccountService accountService) {
    this.stores = stores;
    this.accountService = accountService;
  }

  @PostMapping("/admin/stores")
  @ResponseStatus(HttpStatus.CREATED)
  @Transactional
  public Account create(@Valid @RequestBody CreateStore input) {
    Store store = null;
    if (input.existingStoreId() != null) {
      store =
          stores
              .findById(input.existingStoreId())
              .orElseThrow(() ->
                  new ResponseStatusException(HttpStatus.NOT_FOUND, "Chi nhánh không tồn tại"));
      if (!store.isActive()) {
        throw CommerceSupport.bad("Chi nhánh đã ngừng hoạt động");
      }
      if (store.latitude == null
          || store.longitude == null
          || Double.compare(store.latitude, input.latitude()) != 0
          || Double.compare(store.longitude, input.longitude()) != 0) {
        throw CommerceSupport.bad("Vị trí phải trùng chi nhánh đã chọn");
      }
    }
    String brand = null, name = null;
    if (store == null) {
      if (input.brand() == null || input.brand().isBlank()) {
        throw CommerceSupport.bad("Nhập tên thương hiệu");
      }
      brand = input.brand().trim().replaceAll("\\s+", " ");
      String brandKey = normalize(brand);
      var allStores = stores.findAll();
      for (var retired : allStores) {
        if (!retired.isActive()) {
          retired.brandKey = null;
          retired.branchKey = null;
        }
      }
      stores.flush();
      var siblings =
          allStores.stream()
              .filter(Store::isActive)
              .filter(branch ->
                  normalize(branch.brand == null ? branch.name : branch.brand).equals(brandKey))
              .toList();
      String branchName = input.branchName() == null ? "" : input.branchName().trim();
      // Giữ tương thích với ứng dụng cũ gửi tên chi nhánh trong trường name.
      if (branchName.isBlank()
          && input.name() != null
          && !normalize(input.name()).equals(brandKey)) {
        branchName = input.name().trim();
      }
      if (!siblings.isEmpty() && branchName.isBlank()) {
        throw new ResponseStatusException(
            HttpStatus.CONFLICT,
            "Thương hiệu đã có "
                + siblings.size()
                + " chi nhánh. Nhập tên chi nhánh, ví dụ Chi nhánh 2.");
      }
      name = branchName.isBlank() ? brand : brand + " · " + branchName;
      String branchKey = normalize(name);
      if (siblings.stream().anyMatch(branch -> normalize(branch.name).equals(branchKey))) {
        throw new ResponseStatusException(
            HttpStatus.CONFLICT, "Tên chi nhánh đã tồn tại trong thương hiệu này");
      }
    }
    AppUser user =
        accountService.newUser(input.email(), input.password(), input.fullName(), Role.STORE);
    if (store == null) {
      store = new Store(name, user);
      store.address = input.address().trim();
      store.latitude = input.latitude();
      store.longitude = input.longitude();
      store.brand = brand;
      store.brandKey = normalize(brand);
      store.branchKey = normalize(name);
      store.image =
          stores.findAll().stream()
              .filter(Store::isActive)
              .filter(branch ->
                  normalize(branch.brand == null ? branch.name : branch.brand)
                      .equals(normalize(safeBrand(input.brand()))))
              .map(branch -> branch.image)
              .filter(Objects::nonNull)
              .filter(v -> !v.isBlank())
              .findFirst()
              .orElse(null);
      stores.save(store);
    }
    user.assignedStore = store;
    return accountService.account(user);
  }
}
