package com.cstore.app.entity;

import jakarta.persistence.Embeddable;
import java.time.Instant;

/** Một lần chuyển trạng thái, được nhúng vào lịch sử của đơn hàng. */
@Embeddable
public class StatusEvent {
  public String status;
  public Instant at;

  protected StatusEvent() {}

  public StatusEvent(String status) {
    this.status = status;
    this.at = Instant.now();
  }
}
