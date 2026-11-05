# Bản đồ toàn bộ mã nguồn

Tệp này được sinh từ source hiện tại. Số dòng là mốc để mở file, không phải thứ tự thực thi.
Danh sách khai báo là công cụ tìm nhanh; chương backend/mobile giải thích nghiệp vụ của chúng.
Bộ nhận diện liệt kê các khai báo đặt tên trong source, không phải trình phân tích cú pháp đầy đủ cho mọi lambda/biểu thức ẩn danh.
File chỉ có `export` là điểm import chung, không phải chức năng bị xóa.

Cập nhật từ gốc dự án:

```bash
python3 scripts/run-visible.py --name cap-nhat-ban-do-source -- python3 scripts/generate-source-map.py
```

Tổng cộng **171 file source/cấu hình**. Không bao gồm ảnh nhị phân, .env, QA credentials hoặc artifact sinh tự động.

## backend/pom.xml

[Mở source](../../backend/pom.xml) · 61 dòng.

Cấu hình build, thư viện hoặc dịch vụ.

## backend/src/main/java/com/cstore/app/CStoreApplication.java

[Mở source](../../backend/src/main/java/com/cstore/app/CStoreApplication.java) · 11 dòng.

Điểm vào Java: khởi tạo ứng dụng Spring Boot và quét các package con.

| Dòng | Khai báo để tìm |
| --- | --- |
| 7 | `class CStoreApplication` |
| 8 | `main()` |

## backend/src/main/java/com/cstore/app/config/AdminBootstrap.java

[Mở source](../../backend/src/main/java/com/cstore/app/config/AdminBootstrap.java) · 31 dòng.

Đăng ký và cấu hình các thành phần Spring.

| Dòng | Khai báo để tìm |
| --- | --- |
| 13 | `class AdminBootstrap` |
| 15 | `bootstrap()` |

## backend/src/main/java/com/cstore/app/config/SecurityConfig.java

[Mở source](../../backend/src/main/java/com/cstore/app/config/SecurityConfig.java) · 107 dòng.

Đăng ký và cấu hình các thành phần Spring.

| Dòng | Khai báo để tìm |
| --- | --- |
| 32 | `class SecurityConfig` |
| 34 | `passwordEncoder()` |
| 39 | `jwtKey()` |
| 47 | `jwtEncoder()` |
| 52 | `jwtDecoder()` |
| 69 | `tokenVersion()` |
| 75 | `filterChain()` |

## backend/src/main/java/com/cstore/app/controller/AdminAccountController.java

[Mở source](../../backend/src/main/java/com/cstore/app/controller/AdminAccountController.java) · 145 dòng.

Điểm vào REST API: URL, request và response.

| Dòng | Khai báo để tìm |
| --- | --- |
| 34 | `class AdminAccountController` |
| 40 | `AdminAccountController()` |
| 50 | `accounts()` |
| 60 | `createAccount()` |
| 90 | `access()` |
| 103 | `delete()` |
| 133 | `managedAccount()` |

## backend/src/main/java/com/cstore/app/controller/AdminReportController.java

[Mở source](../../backend/src/main/java/com/cstore/app/controller/AdminReportController.java) · 145 dòng.

Điểm vào REST API: URL, request và response.

| Dòng | Khai báo để tìm |
| --- | --- |
| 33 | `class AdminReportController` |
| 38 | `AdminReportController()` |
| 45 | `brands()` |
| 67 | `revenue()` |

## backend/src/main/java/com/cstore/app/controller/AdminStoreController.java

[Mở source](../../backend/src/main/java/com/cstore/app/controller/AdminStoreController.java) · 127 dòng.

Điểm vào REST API: URL, request và response.

| Dòng | Khai báo để tìm |
| --- | --- |
| 29 | `class AdminStoreController` |
| 33 | `AdminStoreController()` |
| 41 | `create()` |

## backend/src/main/java/com/cstore/app/controller/AuthController.java

[Mở source](../../backend/src/main/java/com/cstore/app/controller/AuthController.java) · 88 dòng.

Điểm vào REST API: URL, request và response.

| Dòng | Khai báo để tìm |
| --- | --- |
| 32 | `class AuthController` |
| 38 | `AuthController()` |
| 48 | `register()` |
| 68 | `login()` |
| 84 | `me()` |

## backend/src/main/java/com/cstore/app/controller/BranchController.java

[Mở source](../../backend/src/main/java/com/cstore/app/controller/BranchController.java) · 31 dòng.

Điểm vào REST API: URL, request và response.

| Dòng | Khai báo để tìm |
| --- | --- |
| 16 | `class BranchController` |
| 19 | `BranchController()` |
| 25 | `branches()` |

## backend/src/main/java/com/cstore/app/controller/CustomerController.java

[Mở source](../../backend/src/main/java/com/cstore/app/controller/CustomerController.java) · 98 dòng.

Điểm vào REST API: URL, request và response.

| Dòng | Khai báo để tìm |
| --- | --- |
| 33 | `class CustomerController` |
| 38 | `CustomerController()` |
| 45 | `deliveryLocation()` |
| 57 | `deliveryLocation()` |
| 68 | `deliveryQuote()` |
| 76 | `nearby()` |

## backend/src/main/java/com/cstore/app/controller/ImageController.java

[Mở source](../../backend/src/main/java/com/cstore/app/controller/ImageController.java) · 179 dòng.

Điểm vào REST API: URL, request và response.

| Dòng | Khai báo để tìm |
| --- | --- |
| 40 | `class ImageController` |
| 47 | `ImageController()` |
| 64 | `upload()` |
| 74 | `uploadBrand()` |
| 96 | `uploadAvatar()` |
| 105 | `uploadAccountAvatar()` |
| 119 | `removeAvatar()` |
| 128 | `setAvatar()` |
| 135 | `writeImage()` |
| 168 | `image()` |

## backend/src/main/java/com/cstore/app/controller/OrderController.java

[Mở source](../../backend/src/main/java/com/cstore/app/controller/OrderController.java) · 202 dòng.

Điểm vào REST API: URL, request và response.

| Dòng | Khai báo để tìm |
| --- | --- |
| 44 | `class OrderController` |
| 51 | `OrderController()` |
| 66 | `checkout()` |
| 117 | `customerOrders()` |
| 124 | `merchantOrders()` |
| 131 | `shipperOrders()` |
| 139 | `storeStatus()` |
| 162 | `cancel()` |
| 178 | `payment()` |

## backend/src/main/java/com/cstore/app/controller/ProductController.java

[Mở source](../../backend/src/main/java/com/cstore/app/controller/ProductController.java) · 88 dòng.

Điểm vào REST API: URL, request và response.

| Dòng | Khai báo để tìm |
| --- | --- |
| 29 | `class ProductController` |
| 33 | `ProductController()` |
| 39 | `allProducts()` |
| 48 | `merchantProducts()` |
| 57 | `create()` |
| 71 | `update()` |
| 85 | `delete()` |

## backend/src/main/java/com/cstore/app/controller/ProfileController.java

[Mở source](../../backend/src/main/java/com/cstore/app/controller/ProfileController.java) · 93 dòng.

Điểm vào REST API: URL, request và response.

| Dòng | Khai báo để tìm |
| --- | --- |
| 26 | `class ProfileController` |
| 32 | `ProfileController()` |
| 40 | `record ProfileInput` |
| 40 | `ProfileInput()` |
| 45 | `record PasswordInput` |
| 45 | `PasswordInput()` |
| 48 | `toString()` |
| 55 | `profile()` |
| 60 | `update()` |
| 73 | `password()` |

## backend/src/main/java/com/cstore/app/controller/ShipperController.java

[Mở source](../../backend/src/main/java/com/cstore/app/controller/ShipperController.java) · 236 dòng.

Điểm vào REST API: URL, request và response.

| Dòng | Khai báo để tìm |
| --- | --- |
| 37 | `class ShipperController` |
| 43 | `ShipperController()` |
| 52 | `navigation()` |
| 109 | `shipperState()` |
| 116 | `location()` |
| 135 | `offers()` |
| 172 | `claim()` |
| 207 | `deliveryStatus()` |

## backend/src/main/java/com/cstore/app/controller/SocialAuthController.java

[Mở source](../../backend/src/main/java/com/cstore/app/controller/SocialAuthController.java) · 61 dòng.

Điểm vào REST API: URL, request và response.

| Dòng | Khai báo để tìm |
| --- | --- |
| 22 | `class SocialAuthController` |
| 28 | `SocialAuthController()` |
| 39 | `record SocialLogin` |
| 39 | `SocialLogin()` |
| 43 | `toString()` |
| 49 | `providers()` |
| 54 | `login()` |

## backend/src/main/java/com/cstore/app/dto/AccountDtos.java

[Mở source](../../backend/src/main/java/com/cstore/app/dto/AccountDtos.java) · 35 dòng.

Kiểu dữ liệu truyền vào/ra API.

| Dòng | Khai báo để tìm |
| --- | --- |
| 8 | `class AccountDtos` |
| 9 | `AccountDtos()` |
| 11 | `record Account` |
| 11 | `Account()` |
| 27 | `record BranchView` |
| 27 | `BranchView()` |

## backend/src/main/java/com/cstore/app/dto/AdminDtos.java

[Mở source](../../backend/src/main/java/com/cstore/app/dto/AdminDtos.java) · 86 dòng.

Kiểu dữ liệu truyền vào/ra API.

| Dòng | Khai báo để tìm |
| --- | --- |
| 16 | `class AdminDtos` |
| 17 | `AdminDtos()` |
| 19 | `record CreateStore` |
| 19 | `CreateStore()` |
| 32 | `toString()` |
| 37 | `record CreateAccount` |
| 37 | `CreateAccount()` |
| 44 | `toString()` |
| 49 | `record AccessInput` |
| 49 | `AccessInput()` |
| 51 | `record BranchRevenue` |
| 51 | `BranchRevenue()` |
| 61 | `record BrandView` |
| 61 | `BrandView()` |
| 64 | `record BrandRevenue` |
| 64 | `BrandRevenue()` |
| 76 | `record Revenue` |
| 76 | `Revenue()` |

## backend/src/main/java/com/cstore/app/dto/AuthDtos.java

[Mở source](../../backend/src/main/java/com/cstore/app/dto/AuthDtos.java) · 39 dòng.

Kiểu dữ liệu truyền vào/ra API.

| Dòng | Khai báo để tìm |
| --- | --- |
| 10 | `class AuthDtos` |
| 11 | `AuthDtos()` |
| 13 | `record Register` |
| 13 | `Register()` |
| 19 | `toString()` |
| 24 | `record Me` |
| 24 | `Me()` |
| 26 | `record Login` |
| 26 | `Login()` |
| 28 | `toString()` |
| 33 | `record Session` |
| 33 | `Session()` |
| 35 | `toString()` |

## backend/src/main/java/com/cstore/app/dto/DeliveryDtos.java

[Mở source](../../backend/src/main/java/com/cstore/app/dto/DeliveryDtos.java) · 59 dòng.

Kiểu dữ liệu truyền vào/ra API.

| Dòng | Khai báo để tìm |
| --- | --- |
| 14 | `class DeliveryDtos` |
| 15 | `DeliveryDtos()` |
| 17 | `record PositionInput` |
| 17 | `PositionInput()` |
| 23 | `record ShipperState` |
| 23 | `ShipperState()` |
| 26 | `record DeliveryLocation` |
| 26 | `DeliveryLocation()` |
| 32 | `record QuoteInput` |
| 32 | `QuoteInput()` |
| 37 | `record DeliveryQuote` |
| 37 | `DeliveryQuote()` |
| 44 | `record NearbyBranch` |
| 44 | `NearbyBranch()` |
| 47 | `record ShipperNavigation` |
| 47 | `ShipperNavigation()` |

## backend/src/main/java/com/cstore/app/dto/OrderDtos.java

[Mở source](../../backend/src/main/java/com/cstore/app/dto/OrderDtos.java) · 66 dòng.

Kiểu dữ liệu truyền vào/ra API.

| Dòng | Khai báo để tìm |
| --- | --- |
| 17 | `class OrderDtos` |
| 18 | `OrderDtos()` |
| 20 | `record OrderItemInput` |
| 20 | `OrderItemInput()` |
| 22 | `record OrderInput` |
| 22 | `OrderInput()` |
| 32 | `record LineView` |
| 32 | `LineView()` |
| 35 | `record EventView` |
| 35 | `EventView()` |
| 37 | `record OrderView` |
| 37 | `OrderView()` |
| 65 | `record StatusInput` |
| 65 | `StatusInput()` |

## backend/src/main/java/com/cstore/app/dto/ProductDtos.java

[Mở source](../../backend/src/main/java/com/cstore/app/dto/ProductDtos.java) · 31 dòng.

Kiểu dữ liệu truyền vào/ra API.

| Dòng | Khai báo để tìm |
| --- | --- |
| 12 | `class ProductDtos` |
| 13 | `ProductDtos()` |
| 15 | `record ProductView` |
| 15 | `ProductView()` |
| 26 | `record ProductInput` |
| 26 | `ProductInput()` |

## backend/src/main/java/com/cstore/app/dto/VerifiedSocialIdentity.java

[Mở source](../../backend/src/main/java/com/cstore/app/dto/VerifiedSocialIdentity.java) · 4 dòng.

Kiểu dữ liệu truyền vào/ra API.

| Dòng | Khai báo để tìm |
| --- | --- |
| 4 | `record VerifiedSocialIdentity` |
| 4 | `VerifiedSocialIdentity()` |

## backend/src/main/java/com/cstore/app/entity/AppUser.java

[Mở source](../../backend/src/main/java/com/cstore/app/entity/AppUser.java) · 67 dòng.

Ánh xạ đối tượng Java sang bảng và quan hệ database.

| Dòng | Khai báo để tìm |
| --- | --- |
| 18 | `class AppUser` |
| 55 | `version()` |
| 59 | `AppUser()` |
| 61 | `AppUser()` |

## backend/src/main/java/com/cstore/app/entity/CustomerOrder.java

[Mở source](../../backend/src/main/java/com/cstore/app/entity/CustomerOrder.java) · 75 dòng.

Ánh xạ đối tượng Java sang bảng và quan hệ database.

| Dòng | Khai báo để tìm |
| --- | --- |
| 24 | `class CustomerOrder` |
| 69 | `CustomerOrder()` |
| 71 | `CustomerOrder()` |

## backend/src/main/java/com/cstore/app/entity/OrderLine.java

[Mở source](../../backend/src/main/java/com/cstore/app/entity/OrderLine.java) · 45 dòng.

Ánh xạ đối tượng Java sang bảng và quan hệ database.

| Dòng | Khai báo để tìm |
| --- | --- |
| 15 | `class OrderLine` |
| 35 | `OrderLine()` |
| 37 | `OrderLine()` |

## backend/src/main/java/com/cstore/app/entity/Product.java

[Mở source](../../backend/src/main/java/com/cstore/app/entity/Product.java) · 45 dòng.

Ánh xạ đối tượng Java sang bảng và quan hệ database.

| Dòng | Khai báo để tìm |
| --- | --- |
| 15 | `class Product` |
| 36 | `Product()` |
| 38 | `Product()` |

## backend/src/main/java/com/cstore/app/entity/Role.java

[Mở source](../../backend/src/main/java/com/cstore/app/entity/Role.java) · 10 dòng.

Ánh xạ đối tượng Java sang bảng và quan hệ database.

| Dòng | Khai báo để tìm |
| --- | --- |
| 4 | `enum Role` |

## backend/src/main/java/com/cstore/app/entity/SocialIdentity.java

[Mở source](../../backend/src/main/java/com/cstore/app/entity/SocialIdentity.java) · 41 dòng.

Ánh xạ đối tượng Java sang bảng và quan hệ database.

| Dòng | Khai báo để tìm |
| --- | --- |
| 20 | `class SocialIdentity` |
| 34 | `SocialIdentity()` |
| 36 | `SocialIdentity()` |

## backend/src/main/java/com/cstore/app/entity/StatusEvent.java

[Mở source](../../backend/src/main/java/com/cstore/app/entity/StatusEvent.java) · 18 dòng.

Ánh xạ đối tượng Java sang bảng và quan hệ database.

| Dòng | Khai báo để tìm |
| --- | --- |
| 8 | `class StatusEvent` |
| 12 | `StatusEvent()` |
| 14 | `StatusEvent()` |

## backend/src/main/java/com/cstore/app/entity/Store.java

[Mở source](../../backend/src/main/java/com/cstore/app/entity/Store.java) · 54 dòng.

Ánh xạ đối tượng Java sang bảng và quan hệ database.

| Dòng | Khai báo để tìm |
| --- | --- |
| 20 | `class Store` |
| 44 | `Store()` |
| 46 | `Store()` |
| 51 | `isActive()` |

## backend/src/main/java/com/cstore/app/exception/ApiErrors.java

[Mở source](../../backend/src/main/java/com/cstore/app/exception/ApiErrors.java) · 42 dòng.

Chuyển ngoại lệ thành phản hồi HTTP.

| Dòng | Khai báo để tìm |
| --- | --- |
| 13 | `class ApiErrors` |
| 15 | `status()` |
| 23 | `validation()` |
| 33 | `conflict()` |
| 39 | `large()` |

## backend/src/main/java/com/cstore/app/mapper/BranchViews.java

[Mở source](../../backend/src/main/java/com/cstore/app/mapper/BranchViews.java) · 20 dòng.

Dựng dữ liệu công khai trả về client.

| Dòng | Khai báo để tìm |
| --- | --- |
| 7 | `class BranchViews` |
| 8 | `BranchViews()` |
| 10 | `view()` |

## backend/src/main/java/com/cstore/app/mapper/CommerceViews.java

[Mở source](../../backend/src/main/java/com/cstore/app/mapper/CommerceViews.java) · 68 dòng.

Dựng dữ liệu công khai trả về client.

| Dòng | Khai báo để tìm |
| --- | --- |
| 14 | `class CommerceViews` |
| 15 | `CommerceViews()` |
| 17 | `view()` |
| 30 | `view()` |

## backend/src/main/java/com/cstore/app/repository/Orders.java

[Mở source](../../backend/src/main/java/com/cstore/app/repository/Orders.java) · 27 dòng.

Truy vấn database và các khóa bản ghi.

| Dòng | Khai báo để tìm |
| --- | --- |
| 13 | `interface Orders` |
| 14 | `findByCustomerIdOrderByIdDesc()` |
| 16 | `findByStoreIdOrderByIdDesc()` |
| 18 | `findByShipperIdOrderByIdDesc()` |
| 20 | `findByStatusOrderByIdDesc()` |
| 22 | `countByShipperIdAndStatusIn()` |
| 26 | `locked()` |

## backend/src/main/java/com/cstore/app/repository/Products.java

[Mở source](../../backend/src/main/java/com/cstore/app/repository/Products.java) · 18 dòng.

Truy vấn database và các khóa bản ghi.

| Dòng | Khai báo để tìm |
| --- | --- |
| 12 | `interface Products` |
| 13 | `findByStoreIdOrderByIdDesc()` |
| 17 | `locked()` |

## backend/src/main/java/com/cstore/app/repository/SocialIdentities.java

[Mở source](../../backend/src/main/java/com/cstore/app/repository/SocialIdentities.java) · 10 dòng.

Truy vấn database và các khóa bản ghi.

| Dòng | Khai báo để tìm |
| --- | --- |
| 8 | `interface SocialIdentities` |
| 9 | `findByProviderAndSubject()` |

## backend/src/main/java/com/cstore/app/repository/Stores.java

[Mở source](../../backend/src/main/java/com/cstore/app/repository/Stores.java) · 10 dòng.

Truy vấn database và các khóa bản ghi.

| Dòng | Khai báo để tìm |
| --- | --- |
| 8 | `interface Stores` |
| 9 | `findByOwnerId()` |

## backend/src/main/java/com/cstore/app/repository/Users.java

[Mở source](../../backend/src/main/java/com/cstore/app/repository/Users.java) · 17 dòng.

Truy vấn database và các khóa bản ghi.

| Dòng | Khai báo để tìm |
| --- | --- |
| 11 | `interface Users` |
| 12 | `findByEmailIgnoreCase()` |
| 16 | `locked()` |

## backend/src/main/java/com/cstore/app/security/FacebookIdentityVerifier.java

[Mở source](../../backend/src/main/java/com/cstore/app/security/FacebookIdentityVerifier.java) · 121 dòng.

Kiểm chứng danh tính đăng nhập nhà cung cấp.

| Dòng | Khai báo để tìm |
| --- | --- |
| 24 | `class FacebookIdentityVerifier` |
| 29 | `FacebookIdentityVerifier()` |
| 36 | `FacebookIdentityVerifier()` |
| 44 | `enabled()` |
| 48 | `verify()` |
| 97 | `endpoint()` |
| 101 | `get()` |
| 112 | `proof()` |

## backend/src/main/java/com/cstore/app/security/GoogleIdentityVerifier.java

[Mở source](../../backend/src/main/java/com/cstore/app/security/GoogleIdentityVerifier.java) · 97 dòng.

Kiểm chứng danh tính đăng nhập nhà cung cấp.

| Dòng | Khai báo để tìm |
| --- | --- |
| 18 | `class GoogleIdentityVerifier` |
| 23 | `GoogleIdentityVerifier()` |
| 32 | `GoogleIdentityVerifier()` |
| 37 | `http()` |
| 44 | `enabled()` |
| 48 | `verify()` |
| 76 | `identity()` |
| 92 | `invalid()` |

## backend/src/main/java/com/cstore/app/service/AccountService.java

[Mở source](../../backend/src/main/java/com/cstore/app/service/AccountService.java) · 100 dòng.

Xử lý nghiệp vụ hoặc dịch vụ dùng lại trên server.

| Dòng | Khai báo để tìm |
| --- | --- |
| 26 | `class AccountService` |
| 32 | `AccountService()` |
| 39 | `account()` |
| 67 | `session()` |
| 93 | `newUser()` |

## backend/src/main/java/com/cstore/app/service/CommerceSupport.java

[Mở source](../../backend/src/main/java/com/cstore/app/service/CommerceSupport.java) · 121 dòng.

Xử lý nghiệp vụ hoặc dịch vụ dùng lại trên server.

| Dòng | Khai báo để tìm |
| --- | --- |
| 24 | `class CommerceSupport` |
| 30 | `CommerceSupport()` |
| 37 | `bad()` |
| 41 | `validCoordinates()` |
| 52 | `requireShipperPhoto()` |
| 58 | `ownedProduct()` |
| 67 | `current()` |
| 74 | `myStore()` |
| 89 | `lockOrder()` |
| 93 | `checkShipper()` |
| 100 | `restore()` |
| 107 | `setStatus()` |
| 113 | `distance()` |

## backend/src/main/java/com/cstore/app/service/DeliveryService.java

[Mở source](../../backend/src/main/java/com/cstore/app/service/DeliveryService.java) · 47 dòng.

Xử lý nghiệp vụ hoặc dịch vụ dùng lại trên server.

| Dòng | Khai báo để tìm |
| --- | --- |
| 17 | `class DeliveryService` |
| 20 | `DeliveryService()` |
| 24 | `quote()` |

## backend/src/main/java/com/cstore/app/service/RoutingService.java

[Mở source](../../backend/src/main/java/com/cstore/app/service/RoutingService.java) · 218 dòng.

Xử lý nghiệp vụ hoặc dịch vụ dùng lại trên server.

| Dòng | Khai báo để tìm |
| --- | --- |
| 23 | `class RoutingService` |
| 24 | `record Step` |
| 24 | `Step()` |
| 33 | `record RoadRoute` |
| 33 | `RoadRoute()` |
| 41 | `record Cached` |
| 41 | `Cached()` |
| 50 | `RoutingService()` |
| 56 | `RoutingService()` |
| 63 | `route()` |
| 115 | `parse()` |
| 198 | `valid()` |
| 207 | `validate()` |
| 213 | `unavailable()` |

## backend/src/main/java/com/cstore/app/service/SocialAccounts.java

[Mở source](../../backend/src/main/java/com/cstore/app/service/SocialAccounts.java) · 40 dòng.

Xử lý nghiệp vụ hoặc dịch vụ dùng lại trên server.

| Dòng | Khai báo để tìm |
| --- | --- |
| 15 | `class SocialAccounts` |
| 19 | `SocialAccounts()` |
| 25 | `resolve()` |

## backend/src/main/java/com/cstore/app/support/BrandNames.java

[Mở source](../../backend/src/main/java/com/cstore/app/support/BrandNames.java) · 36 dòng.

Hàm hỗ trợ nhỏ dùng chung.

| Dòng | Khai báo để tìm |
| --- | --- |
| 10 | `class BrandNames` |
| 11 | `BrandNames()` |
| 13 | `safeBrand()` |
| 17 | `brandName()` |
| 21 | `logo()` |
| 30 | `normalize()` |

## backend/src/main/resources/application.yml

[Mở source](../../backend/src/main/resources/application.yml) · 30 dòng.

Cấu hình build, thư viện hoặc dịch vụ.

## backend/src/test/java/com/cstore/app/AccountFlowTest.java

[Mở source](../../backend/src/test/java/com/cstore/app/AccountFlowTest.java) · 155 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 30 | `class AccountFlowTest` |
| 36 | `login()` |
| 54 | `store()` |
| 69 | `rejectsInvalidCredentialsAndPublicPrivilegedRegistration()` |
| 94 | `onlyAdminCanProvisionPinnedStoreAndLoginResolvesAssignment()` |

## backend/src/test/java/com/cstore/app/AdminDeliveryFlowTest.java

[Mở source](../../backend/src/test/java/com/cstore/app/AdminDeliveryFlowTest.java) · 288 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 41 | `class AdminDeliveryFlowTest` |
| 49 | `record Actor` |
| 49 | `Actor()` |
| 51 | `actor()` |
| 67 | `call()` |
| 79 | `store()` |
| 93 | `confirmedLocationPersistsPerCustomerAndRejectsInvalidPins()` |
| 135 | `adminCreatesLocksAndSoftDeletesAccountsAndRevokesExistingToken()` |
| 189 | `normalizedBrandRequiresDistinctBranchAndSupportsRealImage()` |
| 245 | `call()` |
| 249 | `commissionIncludesOnlyDeliveredPaidMerchandiseAndPreservesHistoryAfterAccountDeletion()` |
| 280 | `seedOrder()` |

## backend/src/test/java/com/cstore/app/BrandAdminFlowTest.java

[Mở source](../../backend/src/test/java/com/cstore/app/BrandAdminFlowTest.java) · 247 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 37 | `class BrandAdminFlowTest` |
| 45 | `record Actor` |
| 45 | `Actor()` |
| 47 | `actor()` |
| 64 | `call()` |
| 75 | `input()` |
| 89 | `create()` |
| 93 | `order()` |
| 102 | `row()` |
| 109 | `revenueGroupsBrandBranchesRanksAndCountsSeparately()` |
| 136 | `deletingOwnerHidesBranchAndLastBrandButPreservesRevenueAndCanCreateFreshBrand()` |
| 186 | `deletingStaffKeepsBranchAndDeletingOwnerWithOpenOrdersIsBlocked()` |
| 224 | `previouslyDeletedOwnerIsExcludedFromCatalogAndBrandCreationOptions()` |

## backend/src/test/java/com/cstore/app/CommerceFlowTest.java

[Mở source](../../backend/src/test/java/com/cstore/app/CommerceFlowTest.java) · 309 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 42 | `class CommerceFlowTest` |
| 46 | `roadRouting()` |
| 66 | `token()` |
| 83 | `call()` |
| 95 | `record Fixture` |
| 95 | `Fixture()` |
| 97 | `fixture()` |
| 143 | `order()` |
| 164 | `realImageStockCancelAndCodLifecycle()` |
| 239 | `call()` |
| 243 | `concurrentCheckoutDoesNotOversell()` |
| 268 | `call()` |
| 272 | `branchIsolationRadiusAndThreeDeliveryLimit()` |

## backend/src/test/java/com/cstore/app/ProfileFlowTest.java

[Mở source](../../backend/src/test/java/com/cstore/app/ProfileFlowTest.java) · 270 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 37 | `class ProfileFlowTest` |
| 45 | `record Actor` |
| 45 | `Actor()` |
| 47 | `actor()` |
| 67 | `call()` |
| 78 | `png()` |
| 85 | `customerProfilePersistsAndCannotChangeAnotherAccount()` |
| 110 | `shipperMustUploadPhotoBeforeGoingOnlineAndCustomerCanRemovePhoto()` |
| 148 | `storeAccountsUseBrandLogoAndAdminCanUploadShipperPortrait()` |
| 185 | `passwordChangeVerifiesCurrentAndRevokesOtherSessions()` |
| 234 | `staleLocationUpdateCannotUndoPasswordOrRevocation()` |

## backend/src/test/java/com/cstore/app/RoadDeliveryFlowTest.java

[Mở source](../../backend/src/test/java/com/cstore/app/RoadDeliveryFlowTest.java) · 285 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 43 | `class RoadDeliveryFlowTest` |
| 52 | `record Fixture` |
| 52 | `Fixture()` |
| 56 | `roads()` |
| 62 | `road()` |
| 72 | `actor()` |
| 94 | `call()` |
| 106 | `fixture()` |
| 127 | `order()` |
| 148 | `quoteAndOrderUseRoadDistanceAndFeeRatherThanShortStraightLine()` |
| 177 | `routesBeyondTenKmAndUnavailableRoadProviderCannotTakeStockOrChargeFakeFees()` |
| 198 | `pickupSimulationMovesDriverToStoreSwitchesLegAndRealGpsClearsSimulation()` |
| 269 | `shipperRoadRangeRejectsStoreThatIsNearbyOnlyInStraightLine()` |

## backend/src/test/java/com/cstore/app/RoutingServiceTest.java

[Mở source](../../backend/src/test/java/com/cstore/app/RoutingServiceTest.java) · 121 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 13 | `class RoutingServiceTest` |
| 16 | `route()` |
| 26 | `choosesShortestReturnedRoadInsteadOfFastestAndPreservesGeometryAndSteps()` |
| 46 | `noRouteAndMalformedResponsesNeverBecomeZeroOrStraightLine()` |
| 69 | `networkRequestsUseLngLatAndCacheRepeatedRoute()` |
| 99 | `providerFailureRemainsUnavailable()` |

## backend/src/test/java/com/cstore/app/SocialLoginFlowTest.java

[Mở source](../../backend/src/test/java/com/cstore/app/SocialLoginFlowTest.java) · 194 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 38 | `class SocialLoginFlowTest` |
| 48 | `configure()` |
| 54 | `anonymousConfigurationDoesNotExposeSecrets()` |
| 61 | `verifiedIdentityCreatesCustomerAndCannotUseLocalPassword()` |
| 102 | `repeatedLoginUsesProviderSubjectEvenWhenProviderEmailChanges()` |
| 125 | `existingEmailWithDifferentProviderLinksToSameAccount()` |
| 161 | `rejectedTokensAndUnknownProvidersCannotCreateAnAccount()` |
| 179 | `blockedSocialAccountCannotCreateANewSession()` |

## backend/src/test/java/com/cstore/app/SocialTokenVerificationTest.java

[Mở source](../../backend/src/test/java/com/cstore/app/SocialTokenVerificationTest.java) · 269 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 29 | `class SocialTokenVerificationTest` |
| 38 | `setup()` |
| 50 | `token()` |
| 73 | `unauthorized()` |
| 80 | `acceptsSignedGoogleIdentityWithMatchingAudience()` |
| 90 | `rejectsGoogleWrongAudienceIssuerUnverifiedEmailAndExpiredToken()` |
| 121 | `rejectsGoogleInvalidSignatureAndMalformedToken()` |
| 135 | `debug()` |
| 152 | `expectDebug()` |
| 162 | `verifiesFacebookAppTokenUserAndProfileIdentity()` |
| 181 | `rejectsFacebookTokenFromAnotherAppBeforeReadingProfile()` |
| 189 | `rejectsExpiredFacebookDataAccess()` |
| 203 | `rejectsInvalidFacebookTokenAppTokenAndExpiredAccess()` |
| 218 | `rejectsFacebookProfileSubjectMismatch()` |
| 232 | `facebookMissingEmailGivesActionableError()` |
| 248 | `disabledProvidersFailBeforeAnyNetworkRequest()` |

## docker-compose.yml

[Mở source](../../docker-compose.yml) · 22 dòng.

Cấu hình build, thư viện hoặc dịch vụ.

## mobile/analysis_options.yaml

[Mở source](../../mobile/analysis_options.yaml) · 5 dòng.

Cấu hình build, thư viện hoặc dịch vụ.

## mobile/android/app/build.gradle.kts

[Mở source](../../mobile/android/app/build.gradle.kts) · 87 dòng.

Cấu hình hoặc mã nền tảng Android.

## mobile/android/app/src/debug/AndroidManifest.xml

[Mở source](../../mobile/android/app/src/debug/AndroidManifest.xml) · 8 dòng.

Cấu hình hoặc mã nền tảng Android.

## mobile/android/app/src/main/AndroidManifest.xml

[Mở source](../../mobile/android/app/src/main/AndroidManifest.xml) · 65 dòng.

Cấu hình hoặc mã nền tảng Android.

## mobile/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java

[Mở source](../../mobile/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java) · 69 dòng.

Cấu hình hoặc mã nền tảng Android.

| Dòng | Khai báo để tìm |
| --- | --- |
| 15 | `class GeneratedPluginRegistrant` |
| 17 | `registerWith()` |

## mobile/android/app/src/main/kotlin/com/example/cstore_mobile/MainActivity.kt

[Mở source](../../mobile/android/app/src/main/kotlin/com/example/cstore_mobile/MainActivity.kt) · 3 dòng.

Cấu hình hoặc mã nền tảng Android.

## mobile/android/app/src/main/res/drawable/launch_background.xml

[Mở source](../../mobile/android/app/src/main/res/drawable/launch_background.xml) · 12 dòng.

Cấu hình hoặc mã nền tảng Android.

## mobile/android/app/src/main/res/drawable-v21/launch_background.xml

[Mở source](../../mobile/android/app/src/main/res/drawable-v21/launch_background.xml) · 12 dòng.

Cấu hình hoặc mã nền tảng Android.

## mobile/android/app/src/main/res/values/styles.xml

[Mở source](../../mobile/android/app/src/main/res/values/styles.xml) · 18 dòng.

Cấu hình hoặc mã nền tảng Android.

## mobile/android/app/src/main/res/values-night/styles.xml

[Mở source](../../mobile/android/app/src/main/res/values-night/styles.xml) · 18 dòng.

Cấu hình hoặc mã nền tảng Android.

## mobile/android/app/src/profile/AndroidManifest.xml

[Mở source](../../mobile/android/app/src/profile/AndroidManifest.xml) · 7 dòng.

Cấu hình hoặc mã nền tảng Android.

## mobile/android/build.gradle.kts

[Mở source](../../mobile/android/build.gradle.kts) · 24 dòng.

Cấu hình hoặc mã nền tảng Android.

## mobile/android/gradle.properties

[Mở source](../../mobile/android/gradle.properties) · 6 dòng.

Cấu hình hoặc mã nền tảng Android.

## mobile/android/settings.gradle.kts

[Mở source](../../mobile/android/settings.gradle.kts) · 26 dòng.

Cấu hình hoặc mã nền tảng Android.

## mobile/integration_test/auth_scroll_smoke_test.dart

[Mở source](../../mobile/integration_test/auth_scroll_smoke_test.dart) · 97 dòng.

Test tích hợp chạy trên thiết bị/emulator.

| Dòng | Khai báo để tìm |
| --- | --- |
| 8 | `main()` |
| 17 | `settle()` |
| 29 | `reveal()` |
| 49 | `closeTo()` |

## mobile/integration_test/create_partner_test.dart

[Mở source](../../mobile/integration_test/create_partner_test.dart) · 229 dòng.

Test tích hợp chạy trên thiết bị/emulator.

| Dòng | Khai báo để tìm |
| --- | --- |
| 10 | `main()` |
| 27 | `input()` |
| 29 | `hint()` |
| 31 | `waitFor()` |
| 39 | `idle()` |
| 50 | `reveal()` |
| 64 | `enter()` |
| 73 | `hide()` |
| 78 | `snapshot()` |
| 84 | `pin()` |
| 100 | `remove()` |

## mobile/integration_test/live_commerce_test.dart

[Mở source](../../mobile/integration_test/live_commerce_test.dart) · 393 dòng.

Test tích hợp chạy trên thiết bị/emulator.

| Dòng | Khai báo để tìm |
| --- | --- |
| 16 | `main()` |
| 34 | `input()` |
| 36 | `waitFor()` |
| 44 | `waitUntil()` |
| 53 | `action()` |
| 57 | `reveal()` |
| 71 | `clickAction()` |
| 83 | `screenshot()` |
| 89 | `returnToLogin()` |
| 98 | `enter()` |
| 107 | `hide()` |
| 112 | `login()` |

## mobile/integration_test/profile_test.dart

[Mở source](../../mobile/integration_test/profile_test.dart) · 174 dòng.

Test tích hợp chạy trên thiết bị/emulator.

| Dòng | Khai báo để tìm |
| --- | --- |
| 11 | `main()` |
| 24 | `input()` |
| 26 | `waitUntil()` |
| 34 | `ready()` |
| 36 | `reveal()` |
| 49 | `enter()` |
| 58 | `hide()` |
| 63 | `tap()` |
| 70 | `shot()` |
| 76 | `login()` |
| 85 | `password()` |

## mobile/integration_test/ui_refinements_test.dart

[Mở source](../../mobile/integration_test/ui_refinements_test.dart) · 272 dòng.

Test tích hợp chạy trên thiết bị/emulator.

| Dòng | Khai báo để tìm |
| --- | --- |
| 17 | `main()` |
| 34 | `input()` |
| 36 | `until()` |
| 44 | `reveal()` |
| 57 | `tap()` |
| 64 | `enter()` |
| 73 | `hide()` |
| 78 | `shot()` |
| 84 | `top()` |
| 92 | `login()` |
| 101 | `logout()` |
| 109 | `gender()` |
| 118 | `dates()` |

## mobile/lib/app/app.dart

[Mở source](../../mobile/lib/app/app.dart) · 41 dòng.

Widget gốc và điều hướng theo phiên/vai trò.

| Dòng | Khai báo để tìm |
| --- | --- |
| 8 | `class CStoreApp` |
| 15 | `createState()` |
| 18 | `class _CStoreAppState` |
| 22 | `dispose()` |
| 28 | `build()` |

## mobile/lib/app/role_home.dart

[Mở source](../../mobile/lib/app/role_home.dart) · 35 dòng.

Widget gốc và điều hướng theo phiên/vai trò.

| Dòng | Khai báo để tìm |
| --- | --- |
| 13 | `class RoleHome` |
| 19 | `build()` |

## mobile/lib/app/theme/app_theme.dart

[Mở source](../../mobile/lib/app/theme/app_theme.dart) · 89 dòng.

Giao diện chung: màu, font, khoảng cách, kiểu widget.

| Dòng | Khai báo để tìm |
| --- | --- |
| 4 | `buildAppTheme()` |

## mobile/lib/main.dart

[Mở source](../../mobile/lib/main.dart) · 8 dòng.

Điểm vào Dart: gắn widget gốc của Flutter vào màn hình.

| Dòng | Khai báo để tìm |
| --- | --- |
| 6 | `main()` |

## mobile/lib/models/account.dart

[Mở source](../../mobile/lib/models/account.dart) · 52 dòng.

Kiểu dữ liệu ứng dụng hoặc model của một màn hình.

| Dòng | Khai báo để tìm |
| --- | --- |
| 4 | `class Account` |
| 33 | `getter photoRequired` |

## mobile/lib/models/branch.dart

[Mở source](../../mobile/lib/models/branch.dart) · 21 dòng.

Kiểu dữ liệu ứng dụng hoặc model của một màn hình.

| Dòng | Khai báo để tìm |
| --- | --- |
| 2 | `class Branch` |

## mobile/lib/models/delivery_quote.dart

[Mở source](../../mobile/lib/models/delivery_quote.dart) · 31 dòng.

Kiểu dữ liệu ứng dụng hoặc model của một màn hình.

| Dòng | Khai báo để tìm |
| --- | --- |
| 2 | `class DeliveryQuote` |

## mobile/lib/models/models.dart

[Mở source](../../mobile/lib/models/models.dart) · 10 dòng.

Kiểu dữ liệu ứng dụng hoặc model của một màn hình.

## mobile/lib/models/number_format.dart

[Mở source](../../mobile/lib/models/number_format.dart) · 36 dòng.

Kiểu dữ liệu ứng dụng hoặc model của một màn hình.

| Dòng | Khai báo để tìm |
| --- | --- |
| 5 | `money()` |
| 13 | `distance()` |
| 19 | `toRadians()` |

## mobile/lib/models/order.dart

[Mở source](../../mobile/lib/models/order.dart) · 126 dòng.

Kiểu dữ liệu ứng dụng hoặc model của một màn hình.

| Dòng | Khai báo để tìm |
| --- | --- |
| 5 | `class OrderLine` |
| 20 | `class HistoryEntry` |
| 29 | `class ShopOrder` |
| 65 | `getter subtotal` |
| 69 | `getter total` |
| 70 | `getter paid` |
| 71 | `getter activeDelivery` |
| 78 | `orderFromJson()` |

## mobile/lib/models/order_status.dart

[Mở source](../../mobile/lib/models/order_status.dart) · 44 dòng.

Kiểu dữ liệu ứng dụng hoặc model của một màn hình.

| Dòng | Khai báo để tìm |
| --- | --- |
| 2 | `enum OrderStatus` |
| 24 | `statusFromApi()` |
| 35 | `statusToApi()` |

## mobile/lib/models/product.dart

[Mở source](../../mobile/lib/models/product.dart) · 33 dòng.

Kiểu dữ liệu ứng dụng hoặc model của một màn hình.

| Dòng | Khai báo để tìm |
| --- | --- |
| 2 | `class Product` |
| 22 | `productFromJson()` |

## mobile/lib/models/role.dart

[Mở source](../../mobile/lib/models/role.dart) · 2 dòng.

Kiểu dữ liệu ứng dụng hoặc model của một màn hình.

| Dòng | Khai báo để tìm |
| --- | --- |
| 2 | `enum Role` |

## mobile/lib/models/store_metrics.dart

[Mở source](../../mobile/lib/models/store_metrics.dart) · 93 dòng.

Kiểu dữ liệu ứng dụng hoặc model của một màn hình.

| Dòng | Khai báo để tìm |
| --- | --- |
| 5 | `completedAt()` |
| 17 | `class ProductSales` |
| 23 | `class StoreMetrics` |
| 78 | `getter estimatedNet` |
| 79 | `getter waiting` |
| 81 | `getter accepted` |
| 83 | `getter delivering` |
| 84 | `getter stopped` |
| 89 | `getter unpaidDelivered` |
| 91 | `getter placedCompleted` |

## mobile/lib/screens/admin/admin_home.dart

[Mở source](../../mobile/lib/screens/admin/admin_home.dart) · 376 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 22 | `class AdminHome` |
| 26 | `createState()` |
| 29 | `class _AdminHomeState` |
| 39 | `getter brands` |
| 42 | `initState()` |
| 48 | `load()` |
| 78 | `createStore()` |
| 97 | `editAccount()` |
| 153 | `changeAccountPhoto()` |
| 181 | `openBrand()` |
| 196 | `build()` |

## mobile/lib/screens/admin/models/brand_option.dart

[Mở source](../../mobile/lib/screens/admin/models/brand_option.dart) · 26 dòng.

Kiểu dữ liệu ứng dụng hoặc model của một màn hình.

| Dòng | Khai báo để tìm |
| --- | --- |
| 5 | `class BrandOption` |
| 9 | `getter key` |
| 10 | `getter image` |
| 14 | `brandOptions()` |
| 25 | `normalizeBrandName()` |

## mobile/lib/screens/admin/pages/brand_detail_page.dart

[Mở source](../../mobile/lib/screens/admin/pages/brand_detail_page.dart) · 182 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 10 | `class BrandDetailPage` |
| 15 | `build()` |

## mobile/lib/screens/admin/pages/create_account_page.dart

[Mở source](../../mobile/lib/screens/admin/pages/create_account_page.dart) · 286 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 13 | `class CreateAccount` |
| 17 | `createState()` |
| 20 | `class _CreateAccountState` |
| 31 | `dispose()` |
| 38 | `pickPhoto()` |
| 65 | `save()` |
| 109 | `build()` |
| 231 | `AccountAvatar()` |

## mobile/lib/screens/admin/pages/create_partner_page.dart

[Mở source](../../mobile/lib/screens/admin/pages/create_partner_page.dart) · 462 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 15 | `class CreatePartner` |
| 20 | `createState()` |
| 23 | `class _CreatePartnerState` |
| 37 | `getter options` |
| 38 | `getter selectedBrand` |
| 40 | `getter duplicate` |
| 43 | `initState()` |
| 55 | `dispose()` |
| 63 | `selectBrand()` |
| 74 | `pickImage()` |
| 101 | `save()` |
| 156 | `option()` |
| 159 | `CircleAvatar()` |
| 195 | `build()` |
| 211 | `SizedBox()` |
| 269 | `Icon()` |
| 405 | `ProductImage()` |

## mobile/lib/screens/admin/widgets/admin_account_card.dart

[Mở source](../../mobile/lib/screens/admin/widgets/admin_account_card.dart) · 132 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 11 | `buildAdminAccountCard()` |

## mobile/lib/screens/admin/widgets/admin_account_filters.dart

[Mở source](../../mobile/lib/screens/admin/widgets/admin_account_filters.dart) · 155 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 10 | `buildAdminAccountFilters()` |

## mobile/lib/screens/admin/widgets/admin_brand_logo.dart

[Mở source](../../mobile/lib/screens/admin/widgets/admin_brand_logo.dart) · 39 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 7 | `class AdminBrandLogo` |
| 13 | `build()` |
| 23 | `ColoredBox()` |

## mobile/lib/screens/admin/widgets/admin_colors.dart

[Mở source](../../mobile/lib/screens/admin/widgets/admin_colors.dart) · 9 dòng.

Trang giao diện, tab hoặc thành phần của trang.

## mobile/lib/screens/admin/widgets/admin_overview.dart

[Mở source](../../mobile/lib/screens/admin/widgets/admin_overview.dart) · 313 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 10 | `buildAdminOverview()` |
| 16 | `brandCard()` |
| 205 | `adminMetric()` |
| 230 | `buildAdminBrandCard()` |

## mobile/lib/screens/admin/widgets/admin_ui.dart

[Mở source](../../mobile/lib/screens/admin/widgets/admin_ui.dart) · 108 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 7 | `adminRows()` |
| 10 | `adminAmount()` |
| 11 | `accountRoleName()` |
| 17 | `accountRoleIcon()` |
| 23 | `adminBadge()` |
| 38 | `adminValueRow()` |
| 51 | `adminStepHeading()` |
| 87 | `adminFormField()` |

## mobile/lib/screens/auth/welcome.dart

[Mở source](../../mobile/lib/screens/auth/welcome.dart) · 330 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 7 | `class LoginPage` |
| 11 | `createState()` |
| 14 | `class _LoginPageState` |
| 25 | `dispose()` |
| 33 | `submit()` |
| 58 | `socialLogin()` |
| 88 | `build()` |
| 201 | `SizedBox()` |
| 263 | `socialButton()` |
| 274 | `SizedBox()` |
| 280 | `Icon()` |
| 290 | `hero()` |

## mobile/lib/screens/customer/cart_page.dart

[Mở source](../../mobile/lib/screens/customer/cart_page.dart) · 135 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 13 | `class CartPage` |
| 17 | `build()` |
| 44 | `empty()` |

## mobile/lib/screens/customer/checkout_page.dart

[Mở source](../../mobile/lib/screens/customer/checkout_page.dart) · 377 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 11 | `class CheckoutPage` |
| 15 | `createState()` |
| 18 | `class _CheckoutPageState` |
| 28 | `initState()` |
| 41 | `dispose()` |
| 49 | `chooseLocation()` |
| 78 | `loadQuote()` |
| 104 | `submit()` |
| 132 | `build()` |
| 137 | `content()` |

## mobile/lib/screens/customer/customer_home.dart

[Mở source](../../mobile/lib/screens/customer/customer_home.dart) · 382 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 14 | `class CustomerHome` |
| 18 | `createState()` |
| 21 | `class _CustomerHomeState` |
| 24 | `build()` |
| 49 | `home()` |
| 51 | `OrderList()` |
| 79 | `home()` |
| 327 | `Color()` |
| 362 | `location()` |

## mobile/lib/screens/customer/shop_page.dart

[Mở source](../../mobile/lib/screens/customer/shop_page.dart) · 337 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 10 | `class ShopPage` |
| 14 | `createState()` |
| 17 | `class _ShopPageState` |
| 20 | `leave()` |
| 54 | `build()` |

## mobile/lib/screens/location_picker.dart

[Mở source](../../mobile/lib/screens/location_picker.dart) · 475 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 11 | `class PinnedLocation` |
| 17 | `class LocationPicker` |
| 33 | `createState()` |
| 36 | `class _LocationPickerState` |
| 51 | `initState()` |
| 59 | `dispose()` |
| 67 | `getter canConfirm` |
| 73 | `choose()` |
| 95 | `gps()` |
| 117 | `tilesFailed()` |
| 126 | `showBranch()` |
| 178 | `build()` |
| 186 | `SizedBox()` |
| 204 | `LatLng()` |
| 247 | `Color()` |

## mobile/lib/screens/orders/order_detail_page.dart

[Mở source](../../mobile/lib/screens/orders/order_detail_page.dart) · 516 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 12 | `class OrderDetail` |
| 22 | `createState()` |
| 25 | `class _OrderDetailState` |
| 27 | `getter state` |
| 28 | `getter role` |
| 31 | `run()` |
| 38 | `date()` |
| 40 | `two()` |
| 44 | `panel()` |
| 55 | `build()` |
| 320 | `Color()` |
| 401 | `actions()` |

## mobile/lib/screens/orders/order_list_page.dart

[Mở source](../../mobile/lib/screens/orders/order_list_page.dart) · 102 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 11 | `class OrderList` |
| 16 | `createState()` |
| 19 | `class _OrderListState` |
| 23 | `build()` |

## mobile/lib/screens/orders.dart

[Mở source](../../mobile/lib/screens/orders.dart) · 4 dòng.

Trang giao diện, tab hoặc thành phần của trang.

## mobile/lib/screens/profile/pages/change_password_page.dart

[Mở source](../../mobile/lib/screens/profile/pages/change_password_page.dart) · 164 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 9 | `class ChangePasswordPage` |
| 13 | `createState()` |
| 16 | `class _ChangePasswordPageState` |
| 23 | `dispose()` |
| 31 | `save()` |
| 57 | `build()` |
| 60 | `Padding()` |

## mobile/lib/screens/profile/pages/edit_profile_page.dart

[Mở source](../../mobile/lib/screens/profile/pages/edit_profile_page.dart) · 229 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 11 | `class EditProfilePage` |
| 15 | `createState()` |
| 18 | `class _EditProfilePageState` |
| 28 | `dispose()` |
| 35 | `photo()` |
| 64 | `save()` |
| 90 | `build()` |

## mobile/lib/screens/profile/profile_page.dart

[Mở source](../../mobile/lib/screens/profile/profile_page.dart) · 305 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 15 | `class ProfilePage` |
| 22 | `createState()` |
| 25 | `class _ProfilePageState` |
| 29 | `initState()` |
| 34 | `refresh()` |
| 52 | `edit()` |
| 58 | `build()` |
| 153 | `Color()` |

## mobile/lib/screens/profile/widgets/profile_colors.dart

[Mở source](../../mobile/lib/screens/profile/widgets/profile_colors.dart) · 7 dòng.

Trang giao diện, tab hoặc thành phần của trang.

## mobile/lib/screens/profile/widgets/profile_menu_tile.dart

[Mở source](../../mobile/lib/screens/profile/widgets/profile_menu_tile.dart) · 43 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 6 | `profileMenuTile()` |

## mobile/lib/screens/shipper/models/delivery_navigation.dart

[Mở source](../../mobile/lib/screens/shipper/models/delivery_navigation.dart) · 125 dòng.

Kiểu dữ liệu ứng dụng hoặc model của một màn hình.

| Dòng | Khai báo để tìm |
| --- | --- |
| 6 | `class RoadStep` |
| 21 | `getter instruction` |
| 44 | `getter icon` |
| 52 | `class RoadLeg` |
| 73 | `getter distanceLabel` |
| 76 | `getter durationLabel` |
| 81 | `class DeliveryNavigation` |
| 119 | `getter toStore` |
| 120 | `getter title` |

## mobile/lib/screens/shipper/navigation_route.dart

[Mở source](../../mobile/lib/screens/shipper/navigation_route.dart) · 592 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 17 | `class ShipperNavigationPage` |
| 23 | `createState()` |
| 26 | `class _ShipperNavigationPageState` |
| 33 | `getter state` |
| 34 | `getter order` |
| 40 | `initState()` |
| 47 | `didUpdateWidget()` |
| 57 | `dispose()` |
| 65 | `sync()` |
| 75 | `load()` |
| 113 | `fit()` |
| 130 | `useGps()` |
| 142 | `pickup()` |
| 173 | `marker()` |
| 216 | `build()` |
| 224 | `LatLng()` |
| 500 | `Text()` |
| 537 | `legRow()` |

## mobile/lib/screens/shipper/shipper_home.dart

[Mở source](../../mobile/lib/screens/shipper/shipper_home.dart) · 401 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 14 | `class ShipperHome` |
| 18 | `createState()` |
| 21 | `class _ShipperHomeState` |
| 25 | `updatePosition()` |
| 49 | `preview()` |
| 88 | `build()` |
| 111 | `RefreshIndicator()` |
| 282 | `SizedBox()` |
| 336 | `ListView()` |
| 372 | `OrderList()` |

## mobile/lib/screens/store/product_editor.dart

[Mở source](../../mobile/lib/screens/store/product_editor.dart) · 213 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 9 | `class ProductEditor` |
| 14 | `createState()` |
| 17 | `class _ProductEditorState` |
| 25 | `initState()` |
| 38 | `recover()` |
| 48 | `dispose()` |
| 55 | `pick()` |
| 68 | `save()` |
| 105 | `build()` |

## mobile/lib/screens/store/store_home.dart

[Mở source](../../mobile/lib/screens/store/store_home.dart) · 123 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 17 | `class StoreHome` |
| 21 | `createState()` |
| 24 | `class _StoreHomeState` |
| 29 | `getter s` |
| 30 | `editProduct()` |
| 36 | `build()` |
| 60 | `buildStoreDashboard()` |
| 69 | `buildStoreInventory()` |
| 83 | `OrderList()` |

## mobile/lib/screens/store/widgets/store_branch_details.dart

[Mở source](../../mobile/lib/screens/store/widgets/store_branch_details.dart) · 166 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 11 | `buildStoreBranchDetails()` |

## mobile/lib/screens/store/widgets/store_components.dart

[Mở source](../../mobile/lib/screens/store/widgets/store_components.dart) · 94 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 6 | `storePanel()` |
| 13 | `storeMetric()` |
| 55 | `storeFinanceRow()` |
| 80 | `storeStockRow()` |

## mobile/lib/screens/store/widgets/store_dashboard.dart

[Mở source](../../mobile/lib/screens/store/widgets/store_dashboard.dart) · 326 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 15 | `buildStoreDashboard()` |
| 197 | `Text()` |
| 251 | `Text()` |

## mobile/lib/screens/store/widgets/store_inventory.dart

[Mở source](../../mobile/lib/screens/store/widgets/store_inventory.dart) · 181 dòng.

Trang giao diện, tab hoặc thành phần của trang.

| Dòng | Khai báo để tìm |
| --- | --- |
| 11 | `buildStoreInventory()` |
| 19 | `Function()` |
| 147 | `Color()` |
| 158 | `Color()` |

## mobile/lib/screens/store/widgets/store_styles.dart

[Mở source](../../mobile/lib/screens/store/widgets/store_styles.dart) · 9 dòng.

Trang giao diện, tab hoặc thành phần của trang.

## mobile/lib/services/account_api.dart

[Mở source](../../mobile/lib/services/account_api.dart) · 2 dòng.

Dịch vụ ứng dụng hoặc file export tương thích.

## mobile/lib/services/api/account_api.dart

[Mở source](../../mobile/lib/services/api/account_api.dart) · 168 dòng.

Giao tiếp HTTP/JSON, endpoint và upload.

| Dòng | Khai báo để tìm |
| --- | --- |
| 6 | `class AccountApi` |
| 12 | `login()` |
| 23 | `socialProviders()` |
| 31 | `socialLogin()` |
| 45 | `_session()` |
| 55 | `profile()` |
| 58 | `updateProfile()` |
| 70 | `uploadAvatar()` |
| 86 | `uploadAccountAvatar()` |
| 96 | `removeAvatar()` |
| 102 | `changePassword()` |
| 119 | `branches()` |
| 132 | `accounts()` |
| 138 | `createStore()` |
| 146 | `uploadStoreImage()` |
| 157 | `uploadImage()` |

## mobile/lib/services/api/api_client.dart

[Mở source](../../mobile/lib/services/api/api_client.dart) · 158 dòng.

Giao tiếp HTTP/JSON, endpoint và upload.

| Dòng | Khai báo để tìm |
| --- | --- |
| 7 | `class ApiClient` |
| 21 | `request()` |
| 55 | `_send()` |
| 61 | `encodedBody()` |
| 89 | `_readErrorMessage()` |
| 99 | `_errorMessage()` |
| 125 | `uploadFile()` |
| 155 | `imageUrl()` |
| 157 | `close()` |

## mobile/lib/services/app_state.dart

[Mở source](../../mobile/lib/services/app_state.dart) · 2 dòng.

Dịch vụ ứng dụng hoặc file export tương thích.

## mobile/lib/services/geocoding_service.dart

[Mở source](../../mobile/lib/services/geocoding_service.dart) · 176 dòng.

Dịch vụ ứng dụng hoặc file export tương thích.

| Dòng | Khai báo để tìm |
| --- | --- |
| 7 | `class GeocodingService` |
| 30 | `reverse()` |
| 63 | `_fetch()` |
| 97 | `_request()` |
| 127 | `_format()` |
| 169 | `dispose()` |

## mobile/lib/services/location_service.dart

[Mở source](../../mobile/lib/services/location_service.dart) · 36 dòng.

Dịch vụ ứng dụng hoặc file export tương thích.

| Dòng | Khai báo để tìm |
| --- | --- |
| 4 | `class LocationService` |
| 5 | `current()` |
| 25 | `AndroidSettings()` |

## mobile/lib/services/social_sign_in.dart

[Mở source](../../mobile/lib/services/social_sign_in.dart) · 123 dòng.

Dịch vụ ứng dụng hoặc file export tương thích.

| Dòng | Khai báo để tìm |
| --- | --- |
| 6 | `enum SocialProvider` |
| 15 | `class SocialSignIn` |
| 16 | `isConfigured()` |
| 17 | `authenticate()` |
| 18 | `signOut()` |
| 21 | `class NativeSocialSignIn` |
| 39 | `isConfigured()` |
| 51 | `authenticate()` |
| 105 | `signOut()` |

## mobile/lib/services/state/app_state.dart

[Mở source](../../mobile/lib/services/state/app_state.dart) · 357 dòng.

Dữ liệu RAM và nhóm thao tác của AppState.

| Dòng | Khai báo để tìm |
| --- | --- |
| 17 | `class AppState` |
| 50 | `getter storeBranchId` |
| 51 | `getter shipperId` |
| 52 | `getter maxDeliveries` |
| 53 | `getter customerOrders` |
| 55 | `getter storeOrders` |
| 57 | `getter deliveries` |
| 59 | `getter offers` |
| 60 | `branch()` |
| 61 | `product()` |
| 62 | `getter nearby` |
| 76 | `getter subtotal` |
| 94 | `refresh()` |
| 97 | `login()` |
| 107 | `loginSocial()` |
| 111 | `_loadSession()` |
| 115 | `register()` |
| 129 | `logout()` |
| 134 | `reloadBranches()` |
| 138 | `reload()` |
| 142 | `loadOrders()` |
| 146 | `loadProducts()` |
| 150 | `select()` |
| 154 | `saveProduct()` |
| 170 | `removeProduct()` |
| 174 | `uploadImage()` |
| 187 | `setLocation()` |
| 199 | `loadNearby()` |
| 203 | `quoteDelivery()` |
| 215 | `_applyLocation()` |
| 227 | `validCoordinates()` |
| 238 | `change()` |
| 248 | `checkout()` |
| 264 | `transition()` |
| 280 | `pay()` |
| 291 | `refreshProfile()` |
| 295 | `updateProfile()` |
| 307 | `uploadAvatar()` |
| 317 | `removeAvatar()` |
| 321 | `changePassword()` |
| 332 | `claim()` |
| 336 | `setShipperPosition()` |
| 351 | `dispose()` |

## mobile/lib/services/state/cart_order_actions.dart

[Mở source](../../mobile/lib/services/state/cart_order_actions.dart) · 96 dòng.

Dữ liệu RAM và nhóm thao tác của AppState.

| Dòng | Khai báo để tìm |
| --- | --- |
| 5 | `class _CartOrderActions` |
| 10 | `change()` |
| 25 | `checkout()` |
| 60 | `transition()` |
| 86 | `pay()` |

## mobile/lib/services/state/catalog_actions.dart

[Mở source](../../mobile/lib/services/state/catalog_actions.dart) · 160 dòng.

Dữ liệu RAM và nhóm thao tác của AppState.

| Dòng | Khai báo để tìm |
| --- | --- |
| 5 | `class _CatalogActions` |
| 10 | `reloadBranches()` |
| 15 | `reload()` |
| 58 | `loadOrders()` |
| 70 | `loadProducts()` |
| 97 | `select()` |
| 113 | `saveProduct()` |
| 137 | `removeProduct()` |
| 145 | `uploadImage()` |

## mobile/lib/services/state/delivery_location_actions.dart

[Mở source](../../mobile/lib/services/state/delivery_location_actions.dart) · 124 dòng.

Dữ liệu RAM và nhóm thao tác của AppState.

| Dòng | Khai báo để tìm |
| --- | --- |
| 5 | `class _DeliveryLocationActions` |
| 10 | `setLocation()` |
| 43 | `loadNearby()` |
| 79 | `quoteDelivery()` |
| 103 | `_applyLocation()` |
| 114 | `validCoordinates()` |

## mobile/lib/services/state/profile_actions.dart

[Mở source](../../mobile/lib/services/state/profile_actions.dart) · 75 dòng.

Dữ liệu RAM và nhóm thao tác của AppState.

| Dòng | Khai báo để tìm |
| --- | --- |
| 5 | `class _ProfileActions` |
| 10 | `refreshProfile()` |
| 20 | `updateProfile()` |
| 37 | `uploadAvatar()` |
| 52 | `removeAvatar()` |
| 61 | `changePassword()` |

## mobile/lib/services/state/session_actions.dart

[Mở source](../../mobile/lib/services/state/session_actions.dart) · 146 dòng.

Dữ liệu RAM và nhóm thao tác của AppState.

| Dòng | Khai báo để tìm |
| --- | --- |
| 5 | `class _SessionActions` |
| 10 | `login()` |
| 26 | `loginSocial()` |
| 57 | `_loadSession()` |
| 96 | `register()` |
| 117 | `logout()` |

## mobile/lib/services/state/shipper_actions.dart

[Mở source](../../mobile/lib/services/state/shipper_actions.dart) · 48 dòng.

Dữ liệu RAM và nhóm thao tác của AppState.

| Dòng | Khai báo để tìm |
| --- | --- |
| 5 | `class _ShipperActions` |
| 10 | `claim()` |
| 21 | `setShipperPosition()` |

## mobile/lib/widgets/account_avatar.dart

[Mở source](../../mobile/lib/widgets/account_avatar.dart) · 63 dòng.

Thành phần giao diện có thể dùng lại.

| Dòng | Khai báo để tìm |
| --- | --- |
| 5 | `class AccountAvatar` |
| 18 | `build()` |
| 25 | `switch()` |
| 48 | `ClipOval()` |

## mobile/lib/widgets/common.dart

[Mở source](../../mobile/lib/widgets/common.dart) · 64 dòng.

Thành phần giao diện có thể dùng lại.

| Dòng | Khai báo để tìm |
| --- | --- |
| 5 | `heading()` |
| 19 | `empty()` |
| 23 | `attempt()` |
| 24 | `Function()` |
| 41 | `ask()` |

## mobile/lib/widgets/cstore_logo.dart

[Mở source](../../mobile/lib/widgets/cstore_logo.dart) · 41 dòng.

Thành phần giao diện có thể dùng lại.

| Dòng | Khai báo để tìm |
| --- | --- |
| 3 | `class CStoreLogo` |
| 10 | `build()` |
| 20 | `class CStoreAppBarTitle` |
| 26 | `build()` |

## mobile/lib/widgets/date_filter.dart

[Mở source](../../mobile/lib/widgets/date_filter.dart) · 114 dòng.

Thành phần giao diện có thể dùng lại.

| Dòng | Khai báo để tìm |
| --- | --- |
| 3 | `localDay()` |
| 8 | `inDateRange()` |
| 16 | `displayDay()` |
| 21 | `class DateFilterBar` |
| 30 | `presets()` |
| 49 | `build()` |

## mobile/lib/widgets/map_zoom_controls.dart

[Mở source](../../mobile/lib/widgets/map_zoom_controls.dart) · 48 dòng.

Thành phần giao diện có thể dùng lại.

| Dòng | Khai báo để tìm |
| --- | --- |
| 4 | `class MapZoomControls` |
| 11 | `zoom()` |
| 19 | `build()` |

## mobile/lib/widgets/order_widgets.dart

[Mở source](../../mobile/lib/widgets/order_widgets.dart) · 261 dòng.

Thành phần giao diện có thể dùng lại.

| Dòng | Khai báo để tìm |
| --- | --- |
| 7 | `class StatusPill` |
| 11 | `build()` |
| 16 | `Color()` |
| 38 | `class OrderItemRow` |
| 43 | `build()` |
| 84 | `class OrderPreview` |
| 96 | `build()` |
| 231 | `class AmountRow` |
| 237 | `build()` |

## mobile/lib/widgets/product_image.dart

[Mở source](../../mobile/lib/widgets/product_image.dart) · 46 dòng.

Thành phần giao diện có thể dùng lại.

| Dòng | Khai báo để tìm |
| --- | --- |
| 4 | `class ProductImage` |
| 15 | `placeholder()` |
| 25 | `build()` |

## mobile/lib/widgets/sync_status.dart

[Mở source](../../mobile/lib/widgets/sync_status.dart) · 23 dòng.

Thành phần giao diện có thể dùng lại.

| Dòng | Khai báo để tìm |
| --- | --- |
| 4 | `class SyncStatus` |
| 9 | `build()` |

## mobile/pubspec.yaml

[Mở source](../../mobile/pubspec.yaml) · 29 dòng.

Cấu hình build, thư viện hoặc dịch vụ.

## mobile/test/account_test.dart

[Mở source](../../mobile/test/account_test.dart) · 94 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 16 | `main()` |

## mobile/test/admin_brands_test.dart

[Mở source](../../mobile/test/admin_brands_test.dart) · 145 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 17 | `brandRow()` |
| 39 | `jsonResponse()` |
| 41 | `adminState()` |
| 76 | `main()` |

## mobile/test/checkout_test.dart

[Mở source](../../mobile/test/checkout_test.dart) · 171 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 13 | `checkoutRoundTrip()` |
| 141 | `main()` |

## mobile/test/delivery_location_test.dart

[Mở source](../../mobile/test/delivery_location_test.dart) · 137 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 14 | `class ControlledGeocoding` |
| 17 | `reverse()` |
| 24 | `main()` |

## mobile/test/navigation_test.dart

[Mở source](../../mobile/test/navigation_test.dart) · 15 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 5 | `main()` |

## mobile/test/product_refresh_test.dart

[Mở source](../../mobile/test/product_refresh_test.dart) · 53 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 10 | `main()` |
| 16 | `product()` |
| 26 | `response()` |

## mobile/test/profile_test.dart

[Mở source](../../mobile/test/profile_test.dart) · 259 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 16 | `user()` |
| 30 | `response()` |
| 33 | `main()` |

## mobile/test/road_distance_test.dart

[Mở source](../../mobile/test/road_distance_test.dart) · 114 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 14 | `customer()` |
| 27 | `main()` |

## mobile/test/scrolling_test.dart

[Mở source](../../mobile/test/scrolling_test.dart) · 90 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 8 | `customerState()` |
| 22 | `showCustomerPage()` |
| 31 | `main()` |

## mobile/test/shipper_navigation_test.dart

[Mở source](../../mobile/test/shipper_navigation_test.dart) · 213 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 12 | `leg()` |
| 31 | `navigationJson()` |
| 55 | `main()` |
| 82 | `orderJson()` |
| 111 | `jsonResponse()` |

## mobile/test/social_auth_test.dart

[Mở source](../../mobile/test/social_auth_test.dart) · 194 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 14 | `class FakeSocialSignIn` |
| 23 | `isConfigured()` |
| 25 | `authenticate()` |
| 31 | `signOut()` |
| 34 | `providers()` |
| 37 | `session()` |
| 50 | `main()` |
| 137 | `providers()` |

## mobile/test/ui_refinements_test.dart

[Mở source](../../mobile/test/ui_refinements_test.dart) · 280 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 17 | `json()` |
| 19 | `order()` |
| 36 | `main()` |
| 194 | `user()` |

## mobile/test/widget_test.dart

[Mở source](../../mobile/test/widget_test.dart) · 60 dòng.

Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.

| Dòng | Khai báo để tìm |
| --- | --- |
| 10 | `main()` |

## scripts/GenerateAppIcons.java

[Mở source](../../scripts/GenerateAppIcons.java) · 58 dòng.

Công cụ terminal: chạy, kiểm thử hoặc tạo tài liệu.

| Dòng | Khai báo để tìm |
| --- | --- |
| 11 | `class GenerateAppIcons` |
| 12 | `main()` |
| 37 | `resize()` |

## scripts/generate-reading-guide.py

[Mở source](../../scripts/generate-reading-guide.py) · 620 dòng.

Công cụ terminal: chạy, kiểm thử hoặc tạo tài liệu.

| Dòng | Khai báo để tìm |
| --- | --- |
| 19 | `skip_comment()` |
| 40 | `skip_string()` |
| 60 | `skip_interpolation()` |
| 79 | `structural_source()` |
| 98 | `matching_end()` |
| 121 | `select_source()` |
| 148 | `parse_notes()` |
| 544 | `render()` |

## scripts/generate-source-map.py

[Mở source](../../scripts/generate-source-map.py) · 157 dòng.

Công cụ terminal: chạy, kiểm thử hoặc tạo tài liệu.

| Dòng | Khai báo để tìm |
| --- | --- |
| 10 | `purpose()` |
| 58 | `declarations()` |
| 85 | `files()` |
| 116 | `main()` |

## scripts/run-visible.py

[Mở source](../../scripts/run-visible.py) · 198 dòng.

Công cụ terminal: chạy, kiểm thử hoặc tạo tài liệu.

| Dòng | Khai báo để tìm |
| --- | --- |
| 23 | `viewer()` |
| 40 | `viewer_running()` |
| 49 | `ensure_viewer()` |
| 75 | `open_chrome()` |
| 89 | `run()` |
| 161 | `main()` |

## scripts/start-backend.sh

[Mở source](../../scripts/start-backend.sh) · 39 dòng.

Công cụ terminal: chạy, kiểm thử hoặc tạo tài liệu.

## scripts/test-admin-brands-live.py

[Mở source](../../scripts/test-admin-brands-live.py) · 70 dòng.

Công cụ terminal: chạy, kiểm thử hoặc tạo tài liệu.

| Dòng | Khai báo để tìm |
| --- | --- |
| 16 | `main()` |

## scripts/test-android-live.py

[Mở source](../../scripts/test-android-live.py) · 101 dòng.

Công cụ terminal: chạy, kiểm thử hoặc tạo tài liệu.

| Dòng | Khai báo để tìm |
| --- | --- |
| 10 | `executable()` |
| 38 | `run()` |

## scripts/test-live.py

[Mở source](../../scripts/test-live.py) · 161 dòng.

Công cụ terminal: chạy, kiểm thử hoặc tạo tài liệu.

| Dòng | Khai báo để tìm |
| --- | --- |
| 11 | `safe_error()` |
| 18 | `request()` |
| 27 | `login()` |
| 28 | `register()` |
| 33 | `main()` |

## scripts/test-ui-refinements-live.py

[Mở source](../../scripts/test-ui-refinements-live.py) · 27 dòng.

Công cụ terminal: chạy, kiểm thử hoặc tạo tài liệu.
