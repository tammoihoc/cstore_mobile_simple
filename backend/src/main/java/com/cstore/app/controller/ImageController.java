package com.cstore.app.controller;

import com.cstore.app.dto.AccountDtos;
import com.cstore.app.dto.ProductDtos;
import com.cstore.app.entity.AppUser;
import com.cstore.app.entity.Role;
import com.cstore.app.mapper.BranchViews;
import com.cstore.app.mapper.CommerceViews;
import com.cstore.app.repository.Stores;
import com.cstore.app.repository.Users;
import com.cstore.app.service.AccountService;
import com.cstore.app.service.CommerceSupport;
import com.cstore.app.support.BrandNames;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.UUID;
import javax.imageio.ImageIO;
import javax.imageio.stream.ImageInputStream;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api")
public class ImageController {
  private final CommerceSupport api;
  private final Stores stores;
  private final Users users;
  private final AccountService accounts;
  private final Path directory;

  public ImageController(
      CommerceSupport api,
      Stores stores,
      Users users,
      AccountService accounts,
      @Value("${UPLOAD_DIR:./uploads}") String dir)
      throws IOException {
    this.api = api;
    this.stores = stores;
    this.users = users;
    this.accounts = accounts;
    directory = Path.of(dir).toAbsolutePath().normalize();
    Files.createDirectories(directory);
  }

  @PostMapping("/merchant/products/{id}/image")
  @Transactional
  public ProductDtos.ProductView upload(
      Authentication auth, @PathVariable Long id, @RequestParam("file") MultipartFile file)
      throws IOException {
    var product = api.ownedProduct(auth, id);
    product.image = writeImage(file);
    return CommerceViews.view(product);
  }

  @PostMapping("/admin/stores/{id}/image")
  @Transactional
  public AccountDtos.BranchView uploadBrand(
      @PathVariable Long id, @RequestParam("file") MultipartFile file) throws IOException {
    var store =
        stores
            .findById(id)
            .orElseThrow(
                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Chi nhánh không tồn tại"));
    if (!store.isActive()) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Chi nhánh đã ngừng hoạt động");
    }
    String image = writeImage(file), brandKey = BrandNames.normalize(BrandNames.brandName(store));
    for (var branch : stores.findAll()) {
      if (branch.isActive()
          && BrandNames.normalize(BrandNames.brandName(branch)).equals(brandKey)) {
        branch.image = image;
      }
    }
    return BranchViews.view(store);
  }

  @PostMapping("/account/avatar")
  @Transactional
  public AccountDtos.Account uploadAvatar(
      Authentication auth, @RequestParam("file") MultipartFile file) throws IOException {
    var user = api.current(auth);
    setAvatar(user, file);
    return accounts.account(user);
  }

  @PostMapping("/admin/accounts/{id}/avatar")
  @Transactional
  public AccountDtos.Account uploadAccountAvatar(
      @PathVariable Long id, @RequestParam("file") MultipartFile file) throws IOException {
    var user =
        users
            .findById(id)
            .filter(u -> !u.deleted)
            .orElseThrow(
                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Tài khoản không tồn tại"));
    setAvatar(user, file);
    return accounts.account(user);
  }

  @DeleteMapping("/account/avatar")
  @Transactional
  public AccountDtos.Account removeAvatar(Authentication auth) {
    var user = api.current(auth);
    if (user.role != Role.CUSTOMER) {
      throw CommerceSupport.bad("Ảnh shipper bắt buộc. Bạn có thể thay bằng ảnh khác.");
    }
    user.avatar = null;
    return accounts.account(user);
  }

  private void setAvatar(AppUser user, MultipartFile file) throws IOException {
    if (user.role == Role.STORE || user.role == Role.MERCHANT) {
      throw CommerceSupport.bad("Tài khoản cửa hàng sử dụng logo thương hiệu.");
    }
    user.avatar = writeImage(file);
  }

  private String writeImage(MultipartFile file) throws IOException {
    if (file.isEmpty() || file.getSize() > 5 * 1024 * 1024) {
      throw CommerceSupport.bad("Ảnh phải từ 1 byte đến 5 MB");
    }
    BufferedImage image;
    try (ImageInputStream input = ImageIO.createImageInputStream(file.getInputStream())) {
      if (input == null) {
        throw CommerceSupport.bad("Ảnh không hợp lệ");
      }
      var readers = ImageIO.getImageReaders(input);
      if (!readers.hasNext()) {
        throw CommerceSupport.bad("Chỉ nhận ảnh JPEG, PNG hoặc WebP được hỗ trợ");
      }
      var reader = readers.next();
      try {
        reader.setInput(input);
        if ((long) reader.getWidth(0) * reader.getHeight(0) > 16000000) {
          throw CommerceSupport.bad("Ảnh quá lớn (tối đa 16 megapixel)");
        }
        image = reader.read(0);
      } finally {
        reader.dispose();
      }
    }
    if (image == null) {
      throw CommerceSupport.bad("Ảnh không hợp lệ");
    }
    String name = UUID.randomUUID() + ".png";
    ImageIO.write(image, "png", directory.resolve(name).toFile());
    return "/api/images/" + name;
  }

  @GetMapping("/images/{name:[a-f0-9-]+\\.png}")
  public ResponseEntity<byte[]> image(@PathVariable String name) throws IOException {
    var path = directory.resolve(name).normalize();
    if (!path.startsWith(directory) || !Files.isRegularFile(path)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND);
    }
    return ResponseEntity.ok()
        .contentType(MediaType.IMAGE_PNG)
        .header("X-Content-Type-Options", "nosniff")
        .cacheControl(CacheControl.maxAge(java.time.Duration.ofDays(7)))
        .body(Files.readAllBytes(path));
  }
}
