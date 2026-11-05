package com.cstore.app.repository;

import com.cstore.app.entity.Store;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

/** Các truy vấn chi nhánh; Spring Data tự tạo phần triển khai từ tên phương thức. */
public interface Stores extends JpaRepository<Store, Long> {
  public Optional<Store> findByOwnerId(Long id);
}
