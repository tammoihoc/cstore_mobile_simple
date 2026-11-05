package com.cstore.app.support;

import com.cstore.app.entity.Store;
import java.text.Normalizer;
import java.util.List;
import java.util.Locale;
import java.util.Objects;

/** Quy tắc chuẩn hóa tên thương hiệu/chi nhánh, dùng chung cho tạo cửa hàng, ảnh và thống kê. */
public final class BrandNames {
  private BrandNames() {}

  public static String safeBrand(String value) {
    return value == null ? "" : value.trim().replaceAll("\\s+", " ");
  }

  public static String brandName(Store store) {
    return store.brand == null || store.brand.isBlank() ? store.name : store.brand;
  }

  public static String logo(List<Store> rows) {
    return rows.stream()
        .map(store -> store.image)
        .filter(Objects::nonNull)
        .filter(value -> !value.isBlank())
        .findFirst()
        .orElse(null);
  }

  public static String normalize(String input) {
    return Normalizer.normalize(input, Normalizer.Form.NFKC)
        .trim()
        .replaceAll("\\s+", " ")
        .toLowerCase(Locale.ROOT);
  }
}
