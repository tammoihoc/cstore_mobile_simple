package com.cstore.app.repository;

import com.cstore.app.entity.CustomerOrder;
import jakarta.persistence.LockModeType;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;

/** Các truy vấn đơn hàng theo khách, chi nhánh, shipper và trạng thái. */
public interface Orders extends JpaRepository<CustomerOrder, Long> {
  public List<CustomerOrder> findByCustomerIdOrderByIdDesc(Long id);

  public List<CustomerOrder> findByStoreIdOrderByIdDesc(Long id);

  public List<CustomerOrder> findByShipperIdOrderByIdDesc(Long id);

  public List<CustomerOrder> findByStatusOrderByIdDesc(String status);

  public long countByShipperIdAndStatusIn(Long id, Collection<String> statuses);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select o from CustomerOrder o where o.id = :id")
  public Optional<CustomerOrder> locked(Long id);
}
