package com.cstore.app.controller;

import com.cstore.app.dto.AccountDtos.BranchView;
import com.cstore.app.mapper.BranchViews;
import com.cstore.app.repository.Stores;
import java.util.List;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Danh sách chi nhánh công khai đang hoạt động và đã có tọa độ. */
@RestController
@RequestMapping("/api")
@Transactional(readOnly = true)
public class BranchController {
  private final Stores stores;

  public BranchController(Stores stores) {
    this.stores = stores;
  }

  @GetMapping("/branches")
  @Transactional(readOnly = true)
  public List<BranchView> branches() {
    return stores.findAll().stream()
        .filter(s -> s.isActive() && s.latitude != null && s.longitude != null)
        .map(BranchViews::view)
        .toList();
  }
}
