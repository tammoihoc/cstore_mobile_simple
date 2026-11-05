package com.cstore.app.mapper;

import com.cstore.app.dto.AccountDtos.BranchView;
import com.cstore.app.entity.Store;

/** Đổi chi nhánh thành JSON công khai, không kèm dữ liệu chủ tài khoản. */
public final class BranchViews {
  private BranchViews() {}

  public static BranchView view(Store store) {
    return new BranchView(
        store.id,
        store.name,
        store.address,
        store.latitude,
        store.longitude,
        store.brand,
        store.image);
  }
}
