package com.cstore.app.repository;

import com.cstore.app.entity.AppUser;
import jakarta.persistence.LockModeType;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;

/** Các truy vấn tài khoản; locked() giữ khóa ghi đến khi giao dịch kết thúc. */
public interface Users extends JpaRepository<AppUser, Long> {
  public Optional<AppUser> findByEmailIgnoreCase(String email);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select u from AppUser u where u.email = :email")
  public Optional<AppUser> locked(String email);
}
