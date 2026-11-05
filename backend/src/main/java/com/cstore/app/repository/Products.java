package com.cstore.app.repository;

import com.cstore.app.entity.Product;
import jakarta.persistence.LockModeType;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;

/** Các truy vấn sản phẩm. Khóa ghi ngăn hai giao dịch cùng bán một lượng tồn kho. */
public interface Products extends JpaRepository<Product, Long> {
  public List<Product> findByStoreIdOrderByIdDesc(Long id);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select p from Product p where p.id = :id")
  public Optional<Product> locked(Long id);
}
