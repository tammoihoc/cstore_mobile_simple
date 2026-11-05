package com.cstore.app.controller;

import com.cstore.app.dto.AccountDtos.Account;
import com.cstore.app.dto.AdminDtos.AccessInput;
import com.cstore.app.dto.AdminDtos.CreateAccount;
import com.cstore.app.entity.AppUser;
import com.cstore.app.entity.Role;
import com.cstore.app.entity.Store;
import com.cstore.app.repository.Orders;
import com.cstore.app.repository.Stores;
import com.cstore.app.repository.Users;
import com.cstore.app.service.AccountService;
import com.cstore.app.service.CommerceSupport;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/** Quản trị tài khoản: tạo, khóa/mở và xóa mềm. Không xóa dữ liệu lịch sử đơn hàng. */
@RestController
@RequestMapping("/api")
@Transactional(readOnly = true)
public class AdminAccountController {
  private final Users users;
  private final Stores stores;
  private final Orders orders;
  private final AccountService accountService;

  public AdminAccountController(
      Users users, Stores stores, Orders orders, AccountService accountService) {
    this.users = users;
    this.stores = stores;
    this.orders = orders;
    this.accountService = accountService;
  }

  @GetMapping("/admin/accounts")
  @Transactional(readOnly = true)
  public List<Account> accounts() {
    return users.findAll().stream()
        .filter(user -> !user.deleted)
        .map(accountService::account)
        .toList();
  }

  @PostMapping("/admin/accounts")
  @ResponseStatus(HttpStatus.CREATED)
  @Transactional
  public Account createAccount(@Valid @RequestBody CreateAccount input) {
    if (input.role() == Role.MERCHANT) {
      throw CommerceSupport.bad("Chọn vai trò STORE cho tài khoản cửa hàng");
    }
    Store store = null;
    if (input.role() == Role.STORE) {
      if (input.storeId() == null) {
        throw CommerceSupport.bad("Chọn chi nhánh cho tài khoản cửa hàng");
      }
      store =
          stores
              .findById(input.storeId())
              .orElseThrow(() -> CommerceSupport.bad("Chi nhánh không tồn tại"));
      if (!store.isActive()) {
        throw CommerceSupport.bad("Chi nhánh đã ngừng hoạt động");
      }
      if (store.latitude == null || store.longitude == null) {
        throw CommerceSupport.bad("Chi nhánh chưa ghim vị trí");
      }
    } else if (input.storeId() != null) {
      throw CommerceSupport.bad("Chỉ tài khoản cửa hàng được gán chi nhánh");
    }
    AppUser user =
        accountService.newUser(input.email(), input.password(), input.fullName(), input.role());
    user.assignedStore = store;
    return accountService.account(user);
  }

  @PutMapping("/admin/accounts/{id}/status")
  @Transactional
  public Account access(
      Authentication auth, @PathVariable Long id, @Valid @RequestBody AccessInput input) {
    AppUser user = managedAccount(auth, id);
    user.blocked = input.blocked();
    if (user.blocked) {
      user.online = false;
    }
    return accountService.account(user);
  }

  @DeleteMapping("/admin/accounts/{id}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  @Transactional
  public void delete(Authentication auth, @PathVariable Long id) {
    AppUser user = managedAccount(auth, id);
    var owned = stores.findByOwnerId(user.id).orElse(null);
    if (owned != null && owned.isActive()) {
      boolean inProgress =
          orders.findByStoreIdOrderByIdDesc(owned.id).stream()
              .anyMatch(o ->
                  List.of("PENDING", "ACCEPTED", "ASSIGNED", "PICKED_UP", "DELIVERING")
                      .contains(o.status));
      if (inProgress) {
        throw new ResponseStatusException(
            HttpStatus.CONFLICT,
            "Chi nhánh còn đơn đang xử lý. Hoàn tất hoặc hủy đơn trước khi xóa cửa hàng.");
      }
      // Xóa mềm: ẩn chi nhánh khỏi danh sách hoạt động, giữ đơn và doanh thu lịch sử.
      owned.archived = true;
      owned.brandKey = null;
      owned.branchKey = null;
      for (var staff : users.findAll()) {
        if (staff.assignedStore != null && staff.assignedStore.id.equals(owned.id)) {
          staff.blocked = true;
          staff.online = false;
        }
      }
    }
    user.deleted = true;
    user.blocked = true;
    user.online = false;
  }

  private AppUser managedAccount(Authentication auth, Long id) {
    AppUser user =
        users
            .findById(id)
            .filter(account -> !account.deleted)
            .orElseThrow(
                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Tài khoản không tồn tại"));
    if (user.email.equalsIgnoreCase(auth.getName())) {
      throw CommerceSupport.bad("Không thể khóa hoặc xóa tài khoản đang đăng nhập");
    }
    return user;
  }
}
