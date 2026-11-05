# Tất cả các nút: chức năng được code ở đâu?

File này dùng để tra từ **nút nhìn thấy trên app → file giao diện → hàm xử lý → nghiệp vụ/API**. Bao gồm nút chữ, nút biểu tượng, thẻ có thể bấm, tab, menu, bộ lọc và thao tác kéo làm mới trong source Flutter hiện tại.

Các liên kết mở source thật. Trong file source, tìm tên hàm hoặc đoạn code ở cột “Xử lý khi bấm”. Hàm không có tên riêng được ghi là **callback ngay trong `build`**. Một hàng có thể gộp các nút cùng cách xử lý, ví dụ các nút lọc trạng thái.

## 1. Đọc một nút như thế nào?

Ví dụ nút **Đăng nhập** trong [welcome.dart](../../mobile/lib/screens/auth/welcome.dart):

```dart
FilledButton(
  onPressed: busy ? null : submit,
  // Các thuộc tính giao diện khác...
)
```

`onPressed` là nơi nối nút với hàm. Khi `busy == true`, callback là `null` nên nút bị vô hiệu hóa. Khi được bấm, nút chạy `submit()` ở đầu cùng file. Hàm này kiểm tra form rồi gọi `widget.state.login(...)`.

Luồng đầy đủ:

```text
Nút Đăng nhập
  → welcome.dart: submit()
  → services/state/app_state.dart: AppState.login()
  → services/state/session_actions.dart: _SessionActions.login()
  → services/api/account_api.dart: AccountApi.login()
  → services/api/api_client.dart: request()
  → backend/controller/AuthController.java: login()
```

Muốn sửa **nhãn, màu, kích thước hoặc điều kiện bấm**: mở file giao diện. Muốn sửa **việc xảy ra sau khi bấm**: theo hàm xử lý và nghiệp vụ trong bảng. Những nút chỉ chuyển trang hoặc lọc dữ liệu đang có sẽ xử lý tại giao diện.

`services/app_state.dart` và `services/account_api.dart` chỉ export để giữ đường dẫn import cũ. Code triển khai nằm trong `services/state/` và `services/api/`. Trong các bảng, `s`, `state` và `widget.state` đều là đối tượng `AppState` mà màn hình đang sử dụng.

Tra nhanh theo màn hình:

- [Đăng nhập, đăng ký](#2-đăng-nhập-và-đăng-ký)
- [Khách hàng, mua hàng, giỏ và checkout](#3-khách-hàng)
- [Danh sách và chi tiết đơn](#4-đơn-hàng-dùng-chung-khách-cửa-hàng-shipper)
- [Cửa hàng và sản phẩm](#5-cửa-hàng)
- [Shipper và bản đồ giao hàng](#6-shipper)
- [Hồ sơ, ảnh đại diện, mật khẩu](#7-hồ-sơ-dùng-chung)
- [Admin, tài khoản, thương hiệu](#8-admin)
- [Chọn vị trí và các nút dùng chung](#9-chọn-vị-trí-và-widget-dùng-chung)
- [Tra tiếp nghiệp vụ và backend](#10-file-nghiệp-vụ-và-backend-để-đọc-tiếp)

## 2. Đăng nhập và đăng ký

File giao diện: [screens/auth/welcome.dart](../../mobile/lib/screens/auth/welcome.dart), lớp `_LoginPageState`.

| Nút / điều khiển | Xử lý khi bấm | Nơi đọc tiếp / kết quả |
| --- | --- | --- |
| Đăng nhập | `submit()` khi `registering == false` | `AppState.login()` → `_SessionActions.login()` → `AccountApi.login()`; đăng nhập xong app chọn màn theo vai trò |
| Tạo tài khoản | `submit()` khi `registering == true` | `AppState.register()` → `_SessionActions.register()`; gửi đăng ký rồi đăng nhập |
| Chuyển giữa đăng ký và đăng nhập | Callback của nút có key `login-register-toggle` | `setState` đổi `registering`, xóa lỗi/thông báo trong cùng file |
| Google / Facebook | `socialButton(provider)` → `socialLogin(provider)` | `AppState.loginSocial()` → `_SessionActions.loginSocial()` → [social_sign_in.dart](../../mobile/lib/services/social_sign_in.dart), kiểm tra cấu hình và gọi API đăng nhập xã hội |
| Biểu tượng con mắt mật khẩu | Callback `setState(() => hidden = !hidden)` | Hiện/ẩn nội dung ô mật khẩu, không gọi API |
| Loại tài khoản Khách hàng / Shipper | `DropdownButtonFormField<Role>.onChanged` | Gán `role`; `submit()` dùng giá trị này khi đăng ký |

## 3. Khách hàng

### 3.1. Trang chính

File giao diện: [screens/customer/customer_home.dart](../../mobile/lib/screens/customer/customer_home.dart), lớp `_CustomerHomeState`.

| Nút / điều khiển | Xử lý khi bấm | Nơi đọc tiếp / kết quả |
| --- | --- | --- |
| Avatar / Hồ sơ của tôi | Callback `tab = 2` | Hiện `ProfilePage` |
| Đăng xuất trên thanh trên | Callback gọi `select(null)` rồi `logout()` | Xóa lựa chọn chi nhánh/giỏ; `_SessionActions.logout()` xóa phiên |
| Tab Cửa hàng / Đơn hàng / Hồ sơ | `NavigationBar.onDestinationSelected` | Đổi `tab`; hiện `home()`, `OrderList` hoặc `ProfilePage` |
| Ô GIAO ĐẾN | `location()` | Mở `LocationPicker`; nhận `PinnedLocation` rồi gọi `AppState.setLocation()` |
| Thẻ chi nhánh gần bạn | Callback `onTap` trong `home()` | Gọi `s.select(b)` rồi mở `ShopPage`; `_CatalogActions.select()` tải sản phẩm |
| Thử lại tuyến đường | `s.loadNearby` | `_DeliveryLocationActions.loadNearby()` tải lại chi nhánh và khoảng cách gần điểm giao |

### 3.2. Mua sản phẩm tại chi nhánh

File giao diện: [screens/customer/shop_page.dart](../../mobile/lib/screens/customer/shop_page.dart), lớp `_ShopPageState`.

| Nút / điều khiển | Xử lý khi bấm | Nơi đọc tiếp / kết quả |
| --- | --- | --- |
| Mũi tên quay lại / nút Back Android | `leave()`; Back Android nối qua `PopScope` | Nếu giỏ có hàng thì hỏi xác nhận rời chi nhánh |
| Ở lại trong hộp thoại | `Navigator.pop(c, false)` | `leave()` giữ nguyên trang và giỏ |
| Xóa giỏ và rời | `Navigator.pop(c, true)` | `leave()` gọi `s.select(null)` rồi quay lại |
| Biểu tượng Giỏ hàng | Callback `Navigator.push` trong `AppBar.actions` | Mở `CartPage` |
| Xem giỏ · … món | Callback `Navigator.push` trong `bottomNavigationBar` | Mở `CartPage` |
| Thẻ sản phẩm | `InkWell.onTap` | Mở `showModalBottomSheet` chứa chi tiết sản phẩm |
| Dấu `+` trên thẻ sản phẩm | Callback `s.change(p, 1)` | `_CartOrderActions.change()` tăng số lượng trong RAM; khóa nút khi đã đạt tồn kho |
| Thêm vào giỏ (…) trong chi tiết | Callback `s.change(p, 1)` | Cùng nghiệp vụ với dấu `+` trên thẻ |
| Ô Tìm sản phẩm | `onChanged` gán `query` | Lọc tên trong danh sách đã tải |
| Chip Tất cả / tên danh mục | `ChoiceChip.onSelected` gán `category` | Lọc danh mục tại giao diện |

### 3.3. Giỏ hàng

File giao diện: [screens/customer/cart_page.dart](../../mobile/lib/screens/customer/cart_page.dart), lớp `CartPage`.

| Nút | Xử lý khi bấm | Nơi đọc tiếp / kết quả |
| --- | --- | --- |
| Giảm số lượng (`−`) | `state.change(state.product(e.key), -1)` | `_CartOrderActions.change()`; về 0 thì bỏ sản phẩm khỏi giỏ |
| Tăng số lượng (`+`) | `state.change(state.product(e.key), 1)` | Cùng hàm trên; nút khóa khi đạt tồn kho |
| Tiếp tục đặt hàng | Callback `Navigator.push` | Mở `CheckoutPage`, chưa tạo đơn ở bước này |

### 3.4. Xác nhận đặt hàng

File giao diện: [screens/customer/checkout_page.dart](../../mobile/lib/screens/customer/checkout_page.dart), lớp `_CheckoutPageState`.

| Nút | Xử lý khi bấm | Nơi đọc tiếp / kết quả |
| --- | --- | --- |
| Chọn điểm giao trên bản đồ / Đã ghim vị trí giao hàng | `chooseLocation()` | Mở `LocationPicker`, gọi `s.setLocation(...)`, cập nhật form rồi `loadQuote()` |
| Thử lại tuyến đường | `loadQuote()` | `AppState.quoteDelivery()` → `_DeliveryLocationActions.quoteDelivery()` lấy phí/khoảng cách đường bộ |
| Xác nhận đặt hàng COD | `submit()` | Kiểm tra form, ghim, báo giá → `AppState.checkout()` → `_CartOrderActions.checkout()` → mở `OrderDetail` của đơn vừa tạo |

## 4. Đơn hàng dùng chung khách, cửa hàng, shipper

### 4.1. Danh sách đơn

File giao diện: [screens/orders/order_list_page.dart](../../mobile/lib/screens/orders/order_list_page.dart), lớp `_OrderListState`.

| Nút / điều khiển | Xử lý khi bấm | Kết quả |
| --- | --- | --- |
| Tất cả / Chờ xác nhận / Đang giao / Hoàn tất / Từ chối / hủy | `ChoiceChip.onSelected` gán `filter` | Lọc danh sách theo trạng thái và vai trò |
| Bộ lọc ngày | `DateFilterBar.onChanged` gán `dateRange` | Lọc ngày đặt đơn; chi tiết nút lịch xem mục 9 |
| Thẻ đơn hàng | `OrderPreview.onTap` → `Navigator.push` | Mở `OrderDetail(state: s, order: o, role: widget.role)` |
| Kéo làm mới | `s.reload` | `_CatalogActions.reload()` tải đơn theo vai trò |

### 4.2. Chi tiết đơn và các nút nghiệp vụ

File giao diện: [screens/orders/order_detail_page.dart](../../mobile/lib/screens/orders/order_detail_page.dart), lớp `_OrderDetailState`. Hàm **`actions(ShopOrder o)`** chứa các nút thay đổi đơn. Hàm `run(...)` bao thao tác chờ và báo lỗi.

| Nút | Khi xuất hiện | Xử lý khi bấm / nơi đọc tiếp |
| --- | --- | --- |
| Gọi người nhận | Vai trò khác khách và có số người nhận | Callback `launchUrl(Uri(scheme: 'tel', path: o.phone))` mở trình gọi điện |
| Gọi shipper | Không phải shipper, không phải người giao của đơn và có số shipper | Callback `launchUrl(...)` với `o.shipperPhone` |
| Mở bản đồ giao hàng | Shipper, đơn đã được cửa hàng chấp nhận hoặc đang giao | Callback `Navigator.push` mở `ShipperNavigationPage` |
| Hủy đơn hàng | Khách, đơn `pending` | Hỏi xác nhận → `run(() => state.transition(o, OrderStatus.cancelled, role))` |
| Giữ đơn / Hủy đơn trong hộp thoại | Khi đang hỏi hủy | Trả `false` / `true` qua `Navigator.pop`; chỉ `true` mới gọi chuyển trạng thái |
| Chấp nhận đơn | Cửa hàng, đơn `pending` | `run(() => state.transition(o, OrderStatus.accepted, role))` |
| Từ chối đơn | Cửa hàng, đơn `pending` | `ask(context, 'Lý do từ chối')` → `transition(...rejected, reason: reason)` |
| Nhận giao đơn này | Shipper, đơn `accepted` | `run(() => state.claim(o))` → `_ShipperActions.claim()` |
| Đã lấy hàng | Shipper được gán đơn, trạng thái `assigned` | `transition` sang `pickedUp` |
| Bắt đầu giao | Shipper được gán đơn, trạng thái `pickedUp` | `transition` sang `delivering` |
| Xác nhận đã giao | Shipper được gán đơn, trạng thái `delivering` | `transition` sang `delivered` |
| Xác nhận đã nhận tiền | Đơn chưa trả tiền và thỏa điều kiện trong `actions(o)` | Hỏi đã nhận đủ → `run(() => state.pay(o, role))` |
| Chưa nhận / Đã nhận đủ trong hộp thoại COD | Khi đang hỏi xác nhận tiền | Trả `false` / `true`; chỉ `true` mới gọi `pay()` |

Các lệnh `transition()` và `pay()` được triển khai trong [cart_order_actions.dart](../../mobile/lib/services/state/cart_order_actions.dart). Nút thu tiền của cửa hàng loại trừ đơn chờ/từ chối/hủy; shipper phải được gán đơn và đang `pickedUp` hoặc `delivering`. Backend vẫn kiểm tra quyền và thứ tự trạng thái khi nhận request.

## 5. Cửa hàng

### 5.1. Trang chính và các tab

File nối sự kiện: [screens/store/store_home.dart](../../mobile/lib/screens/store/store_home.dart), lớp `_StoreHomeState`.

| Nút / điều khiển | File dựng nút | Xử lý khi bấm / nơi đọc tiếp |
| --- | --- | --- |
| Làm mới dữ liệu | `store_home.dart` | `s.reload` → `_CatalogActions.reload()` |
| Đăng xuất | `store_home.dart` | `s.logout` → `_SessionActions.logout()` |
| Các tab thanh dưới | `store_home.dart` | `onDestinationSelected` đổi `tab`, chọn dashboard / tồn kho / đơn / thông tin chi nhánh |
| Bộ lọc thời gian báo cáo | [store_dashboard.dart](../../mobile/lib/screens/store/widgets/store_dashboard.dart) | `onReportDatesChanged` → callback trong `StoreHome` gán `reportDates` |
| Các ô thống kê trạng thái đơn có thể bấm | `store_dashboard.dart`, qua [store_components.dart](../../mobile/lib/screens/store/widgets/store_components.dart): `storeMetric(..., onTap: onOrdersTap)` | `onOrdersTap` trong `StoreHome` chuyển `tab = 2` tới danh sách đơn |
| Quản lý tồn kho | `store_dashboard.dart` | `onInventoryTap` trong `StoreHome` chuyển `tab = 1` |
| Thêm sản phẩm / bấm thẻ sản phẩm | [store_inventory.dart](../../mobile/lib/screens/store/widgets/store_inventory.dart) | `onEdit()` / `onEdit(p)` → `StoreHome.editProduct([product])` mở `ProductEditor` |
| Tìm sản phẩm / chọn danh mục / chip tình trạng tồn kho | `store_inventory.dart` | `onSearchChanged`, `onCategoryChanged`, `onStockFilterChanged` → callback trong `StoreHome` cập nhật `search`, `category`, `stockFilter` |
| Đổi mật khẩu | [store_branch_details.dart](../../mobile/lib/screens/store/widgets/store_branch_details.dart) | `onChangePassword` → callback trong `StoreHome` mở `ChangePasswordPage` |
| Đăng xuất tài khoản | `store_branch_details.dart` | `s.logout` |
| Kéo làm mới dashboard / tồn kho | `store_dashboard.dart` / `store_inventory.dart` | `s.reload` |
| Kéo làm mới thông tin chi nhánh | `store_branch_details.dart` | Callback lần lượt gọi `s.reloadBranches()` và `s.refreshProfile()` |

### 5.2. Form sản phẩm

File giao diện: [screens/store/product_editor.dart](../../mobile/lib/screens/store/product_editor.dart), lớp `_ProductEditorState`.

| Nút | Xử lý khi bấm | Nơi đọc tiếp / kết quả |
| --- | --- | --- |
| Thư viện ảnh | `pick(ImageSource.gallery)` | Mở `ImagePicker`, giữ ảnh đã chọn để lưu |
| Chụp ảnh | `pick(ImageSource.camera)` | Mở camera qua `ImagePicker` |
| Lưu sản phẩm | `save()` | `AppState.saveProduct()` → `_CatalogActions.saveProduct()`; nếu có ảnh thì `AppState.uploadImage()` → `_CatalogActions.uploadImage()` |
| Xóa sản phẩm | Callback trong nút cuối form | `attempt(...)` gọi `widget.state.removeProduct(saved!)` → `_CatalogActions.removeProduct()`, thành công thì đóng trang |

## 6. Shipper

### 6.1. Trang chính

File giao diện: [screens/shipper/shipper_home.dart](../../mobile/lib/screens/shipper/shipper_home.dart), lớp `_ShipperHomeState`.

| Nút / điều khiển | Xử lý khi bấm | Nơi đọc tiếp / kết quả |
| --- | --- | --- |
| Đăng xuất | `s.logout` | `_SessionActions.logout()` |
| Tab Đơn gần / Đang giao / Lịch sử / Hồ sơ | `onDestinationSelected` gán `tab` | Hiện nội dung tương ứng; lịch sử dùng `OrderList`, hồ sơ dùng `ProfilePage` |
| Công tắc trực tuyến | `updatePosition(online: v)` | Lấy vị trí phù hợp rồi `AppState.setShipperPosition()` → `_ShipperActions.setShipperPosition()` |
| Nút cập nhật vị trí GPS | `updatePosition()` | Cập nhật tọa độ; xem nhánh xử lý vị trí mô phỏng trong chính hàm này |
| Nút bổ sung ảnh hồ sơ | Callback `Navigator.push` | Mở `ProfilePage`; thiếu ảnh cũng được kiểm tra trong `updatePosition()` |
| Thẻ đơn | `OrderPreview.onTap` trong hàm dựng thẻ | Mở `OrderDetail` với `Role.shipper`; nút nhận/chuyển trạng thái nằm ở mục 4 |
| Nút xem tuyến giao bên dưới thẻ | Callback `Navigator.push` | Mở `ShipperNavigationPage` |
| Kéo làm mới danh sách đơn gần | `s.reload` | `_CatalogActions.reload()` tải trạng thái, đơn và đề nghị giao |

### 6.2. Bản đồ giao hàng

File giao diện: [screens/shipper/navigation_route.dart](../../mobile/lib/screens/shipper/navigation_route.dart), lớp `_ShipperNavigationPageState`.

| Nút | Xử lý khi bấm | Nơi đọc tiếp / kết quả |
| --- | --- | --- |
| Dùng GPS Android | `useGps()` | `LocationService.current()` → `state.setShipperPosition()` |
| Tải lại đường đi / Thử tải lại đường đi | `load()` | Gọi API `/shipper/orders/{id}/route`, dựng lại tuyến và `fit()` |
| Đã lấy hàng | `pickup()` | `state.transition(order, OrderStatus.pickedUp, Role.shipper)` |
| Mô phỏng đã tới cửa hàng và nhận hàng | `pickup(simulate: true)` | Hỏi xác nhận rồi gọi `transition(..., simulateArrival: true)` |
| Hủy / Xác nhận mô phỏng | Callback trong hộp thoại của `pickup()` | Trả `false` / `true`; chỉ xác nhận mới gửi chuyển trạng thái mô phỏng |
| Phóng to / Thu nhỏ | [map_zoom_controls.dart](../../mobile/lib/widgets/map_zoom_controls.dart): `zoom(1)` / `zoom(-1)` | Đổi mức zoom của `MapController` |
| Xem toàn bộ tuyến | `MapZoomControls.onFit` → `fit()` | Căn bản đồ bao phủ các điểm của tuyến |
| Dòng bản quyền OpenStreetMap | Callback `launchUrl(...)` | Mở trang bản quyền OSM |

## 7. Hồ sơ dùng chung

### 7.1. Xem hồ sơ

File giao diện: [screens/profile/profile_page.dart](../../mobile/lib/screens/profile/profile_page.dart), lớp `_ProfilePageState`. Các dòng menu dựng bằng [profile_menu_tile.dart](../../mobile/lib/screens/profile/widgets/profile_menu_tile.dart) và nhận callback từ trang này.

| Nút / điều khiển | Xử lý khi bấm | Nơi đọc tiếp / kết quả |
| --- | --- | --- |
| Biểu tượng sửa cạnh avatar / Chỉnh sửa hồ sơ / Thêm ảnh | `edit()` | Mở `EditProfilePage` |
| Địa chỉ giao hàng | `widget.onLocation` | Với trang khách, callback là `CustomerHome.location()` mở bản đồ |
| Đổi mật khẩu | Callback `Navigator.push` của menu | Mở `ChangePasswordPage` |
| Thử lại hồ sơ / kéo làm mới | `refresh()` | Gọi `AppState.refreshProfile()` → `_ProfileActions.refreshProfile()` |
| Đăng xuất tài khoản | Callback cuối trang | Quay về route đầu rồi `widget.state.logout()` |

### 7.2. Chỉnh sửa hồ sơ

File giao diện: [screens/profile/pages/edit_profile_page.dart](../../mobile/lib/screens/profile/pages/edit_profile_page.dart), lớp `_EditProfilePageState`.

| Nút / điều khiển | Xử lý khi bấm | Nơi đọc tiếp / kết quả |
| --- | --- | --- |
| Chọn / đổi ảnh đại diện | `photo()` | `ImagePicker` → `AppState.uploadAvatar()` → `_ProfileActions.uploadAvatar()`; ảnh được tải ngay |
| Xóa ảnh đại diện | Callback gọi `attempt(context, widget.state.removeAvatar)` | `_ProfileActions.removeAvatar()`; nút này không hiển thị cho shipper |
| Giới tính | `DropdownButtonFormField.onChanged` | Cập nhật `gender` trong form, lưu khi bấm Lưu hồ sơ |
| Lưu hồ sơ | `save()` | `AppState.updateProfile()` → `_ProfileActions.updateProfile()`, thành công thì đóng trang |

### 7.3. Đổi mật khẩu

File giao diện: [screens/profile/pages/change_password_page.dart](../../mobile/lib/screens/profile/pages/change_password_page.dart), lớp `_ChangePasswordPageState`.

| Nút | Xử lý khi bấm | Nơi đọc tiếp / kết quả |
| --- | --- | --- |
| Con mắt tại từng ô mật khẩu | Callback đổi `obscure[i]` | Hiện/ẩn riêng từng ô |
| Lưu mật khẩu | `save()` | Kiểm tra form → `AppState.changePassword()` → `_ProfileActions.changePassword()` → `AccountApi.changePassword()` |

Nếu tài khoản chỉ đăng nhập mạng xã hội (`passwordEnabled == false`), trang hiển thị thông báo thay cho form đổi mật khẩu.

## 8. Admin

### 8.1. Tổng quan, thương hiệu và tài khoản

File nối sự kiện: [screens/admin/admin_home.dart](../../mobile/lib/screens/admin/admin_home.dart), lớp `_AdminHomeState`.

| Nút / điều khiển | File dựng nút | Xử lý khi bấm / nơi đọc tiếp |
| --- | --- | --- |
| Làm mới dữ liệu / Thử lại / kéo làm mới | `admin_home.dart` | `load()` tải tài khoản, chi nhánh, doanh thu |
| Đăng xuất | `admin_home.dart` | `widget.state.logout()` |
| Tab Tổng quan / Thương hiệu / Tài khoản | `admin_home.dart` | `onDestinationSelected` gán `tab`, xóa `search` |
| Nút nổi Tạo thương hiệu | `admin_home.dart` | `createStore()` mở `CreatePartner` |
| Nút nổi Thêm tài khoản | `admin_home.dart`, khi `tab == 2` | Callback mở `CreateAccount`, tạo xong gọi `load()` |
| Xem tất cả thương hiệu | [admin_overview.dart](../../mobile/lib/screens/admin/widgets/admin_overview.dart) | `onShowAllBrands` → callback `tab = 1` trong `AdminHome` |
| Thẻ thương hiệu | `admin_overview.dart`: `buildAdminBrandCard` | `onOpenBrand` → `openBrand(brand)` trong `AdminHome`, mở `BrandDetailPage` |
| Tìm thương hiệu | `admin_home.dart` | `onChanged` gán `search`, lọc danh sách đang có |
| Đang hoạt động / Lịch sử đã ngừng | `admin_home.dart` | `onSelected` gán `showArchived` |
| Ô vai trò / dropdown vai trò | [admin_account_filters.dart](../../mobile/lib/screens/admin/widgets/admin_account_filters.dart) | `onRoleChanged` → callback gán `filter` trong `AdminHome`; bấm lại ô vai trò đang chọn thì bỏ lọc vai trò |
| Tìm theo tên hoặc email | `admin_account_filters.dart` | `onSearchChanged` → gán `search` |
| Ngày tạo tài khoản | `admin_account_filters.dart` | `onDatesChanged` → gán `accountDates` |
| Mới nhất trước / Cũ nhất trước | `admin_account_filters.dart` | `onSortChanged` → gán `newestFirst` |
| Tất cả bên cạnh bộ lọc tài khoản | `admin_account_filters.dart` | `onReset` → xóa `filter` và `accountDates` trong `AdminHome` |
| Menu ba chấm Quản lý tài khoản | [admin_account_card.dart](../../mobile/lib/screens/admin/widgets/admin_account_card.dart) | `PopupMenuButton.onSelected` → `onAction` → `AdminHome.editAccount(user, action)`; ẩn menu cho tài khoản đang đăng nhập |
| Cập nhật ảnh đại diện trong menu | `admin_account_card.dart`, action `avatar` | `editAccount()` → `changeAccountPhoto(user)` → `api.uploadAccountAvatar()`; không có mục này cho vai trò cửa hàng |
| Cấm đăng nhập / Cho phép đăng nhập | `admin_account_card.dart`, action `status` | `editAccount()` hỏi xác nhận → PUT `/admin/accounts/{id}/status` |
| Xóa tài khoản / Xóa cửa hàng và tài khoản | `admin_account_card.dart`, action `delete` | `editAccount()` hỏi xác nhận → DELETE `/admin/accounts/{id}` |
| Hủy / nút xác nhận cấm, cho phép hoặc xóa | Hộp thoại trong `AdminHome.editAccount()` | `Navigator.pop(c, false/true)`; chỉ xác nhận mới gửi API |
| Thêm chi nhánh ở chi tiết thương hiệu | [brand_detail_page.dart](../../mobile/lib/screens/admin/pages/brand_detail_page.dart) | `onAdd` do `AdminHome.openBrand()` truyền vào → `createStore(brand: ...)`; thương hiệu ngừng hoạt động không có nút này |

### 8.2. Tạo thương hiệu / chi nhánh

File giao diện: [screens/admin/pages/create_partner_page.dart](../../mobile/lib/screens/admin/pages/create_partner_page.dart), lớp `_CreatePartnerState`.

| Nút / điều khiển | Xử lý khi bấm | Nơi đọc tiếp / kết quả |
| --- | --- | --- |
| Chọn tạo thương hiệu / thêm chi nhánh cho thương hiệu có sẵn | `selectBrand(key)` | Đổi thương hiệu đang chọn, xóa dữ liệu tên chi nhánh/ảnh đang nhập |
| Ô tên thương hiệu | `onChanged` gọi `setState` | Tính lại thương hiệu trùng qua getter `duplicate` |
| Thêm chi nhánh cho thương hiệu này | `selectBrand(duplicate!.key)` | Chọn thương hiệu trùng thay vì tạo thương hiệu mới |
| Ô ghim vị trí chi nhánh | Callback `ListTile.onTap` | Mở `LocationPicker`, nhận vị trí và lưu vào biến `pin` của form |
| Chọn ảnh thương hiệu / Đổi ảnh | `pickImage()` | Chọn ảnh qua `ImagePicker`, chưa upload ở bước này |
| Tạo thương hiệu và tài khoản / Tạo chi nhánh và tài khoản / Thử tải logo lại | `save()` | `api.createStore(...)` tạo một lần, giữ `createdStoreId`; `api.uploadStoreImage(...)` tải logo; tải lại chi nhánh rồi đóng form |

### 8.3. Tạo tài khoản

File giao diện: [screens/admin/pages/create_account_page.dart](../../mobile/lib/screens/admin/pages/create_account_page.dart), lớp `_CreateAccountState`.

| Nút / điều khiển | Xử lý khi bấm | Nơi đọc tiếp / kết quả |
| --- | --- | --- |
| Vai trò | Callback dropdown gán `role`, xóa `photo`, `photoName` | Đổi các trường của form theo vai trò |
| Chi nhánh quản lý | Callback dropdown gán `storeId` | Chọn chi nhánh cho tài khoản cửa hàng |
| Chọn / đổi ảnh đại diện | `pickPhoto()` | Giữ ảnh trong biến `photo`, chưa upload |
| Tạo tài khoản / Thử tải ảnh lại | `save()` | POST `/admin/accounts` nếu chưa có `createdId`; sau đó `api.uploadAccountAvatar(...)` nếu cần, thành công thì đóng form |

## 9. Chọn vị trí và widget dùng chung

### 9.1. Chọn vị trí

File giao diện: [screens/location_picker.dart](../../mobile/lib/screens/location_picker.dart), lớp `_LocationPickerState`.

| Nút / thao tác | Xử lý khi bấm | Nơi đọc tiếp / kết quả |
| --- | --- | --- |
| Lấy vị trí GPS | `gps()` | [location_service.dart](../../mobile/lib/services/location_service.dart): `LocationService.current()` → di chuyển bản đồ → `choose(...)` |
| Chạm điểm trên bản đồ | `MapOptions.onTap` → `choose(point)` | Ghim điểm, gọi [geocoding_service.dart](../../mobile/lib/services/geocoding_service.dart): `reverse()` để gợi ý địa chỉ |
| Chạm biểu tượng chi nhánh | `showBranch(branch)` | Mở bảng thông tin chi nhánh; không chọn chi nhánh mua hàng tại đây |
| Phóng to / Thu nhỏ | `MapZoomControls` → `zoom(1)` / `zoom(-1)` | Đổi zoom trong widget dùng chung |
| Thử tải lại bản đồ | Callback đổi `tileError = false`, tăng `revision` | Tạo lại lớp tile để tải ảnh bản đồ |
| Dòng bản quyền OpenStreetMap | Callback `launchUrl(...)` | Mở trang bản quyền OSM |
| Sửa ô địa chỉ | `onChanged` gán `addressEdited = true` | Giữ nội dung người dùng tự sửa khi kết quả gợi ý địa chỉ trả về |
| Xác nhận vị trí đã ghim | Callback `Navigator.pop(context, PinnedLocation(...))` | Trả địa chỉ/tọa độ cho màn đã mở bản đồ; nút chỉ bật khi `canConfirm` cho phép |

`LocationPicker` trả kết quả cho màn gọi. Việc lưu địa chỉ giao hàng lên server nằm ở `CustomerHome.location()` hoặc `CheckoutPage.chooseLocation()`. Với form tạo chi nhánh, vị trí được gửi khi `CreatePartner.save()` chạy.

### 9.2. Bộ lọc ngày, lỗi đồng bộ và hộp thoại

| Nút / điều khiển | File | Xử lý khi bấm |
| --- | --- | --- |
| Tất cả ngày / Hôm nay / 7 ngày gần đây / 30 ngày gần đây / Tháng này | [widgets/date_filter.dart](../../mobile/lib/widgets/date_filter.dart): `DateFilterBar` | Dropdown gọi `onChanged(options[name])`; trang cha nhận khoảng ngày để lọc |
| Chọn khoảng ngày | `date_filter.dart` | Mở `showDateRangePicker`; nút Áp dụng/Hủy do Flutter dựng; chọn xong gọi `onChanged(range)` |
| Bỏ lọc ngày | `date_filter.dart` | `onChanged(null)` |
| Thử lại trên thanh lỗi đồng bộ | [widgets/sync_status.dart](../../mobile/lib/widgets/sync_status.dart) | `state.reload` → `_CatalogActions.reload()` |
| Hủy / Xác nhận trong hộp nhập lý do | [widgets/common.dart](../../mobile/lib/widgets/common.dart): `ask()` | Trả `null` / `controller.text` cho nơi gọi, ví dụ Từ chối đơn |
| Bấm một thẻ đơn | [widgets/order_widgets.dart](../../mobile/lib/widgets/order_widgets.dart): `OrderPreview` | Chuyển tiếp `onTap` do màn cha truyền vào; nơi mở chi tiết là `OrderList` hoặc `ShipperHome` |
| Bấm một dòng menu hồ sơ | [profile_menu_tile.dart](../../mobile/lib/screens/profile/widgets/profile_menu_tile.dart): `profileMenuTile()` | Chuyển tiếp callback do `ProfilePage` truyền vào |
| Mũi tên Back mặc định trên các trang | `AppBar` của trang tương ứng | Flutter tự dựng nút quay lại bằng `Navigator`; ngoại lệ trang mua hàng dùng `ShopPage.leave()` như mục 3.2 |
| Đóng popup/menu/bảng chi tiết bằng Back hoặc chạm ngoài | `showDialog`, `PopupMenuButton`, `showModalBottomSheet` tại nơi mở | Hành vi đóng do Flutter xử lý theo cấu hình của widget; không có hàm nghiệp vụ riêng cho mỗi lần đóng |

## 10. File nghiệp vụ và backend để đọc tiếp

### 10.1. Nghiệp vụ phía Flutter

| Muốn sửa chức năng | File triển khai | Hàm cần tìm |
| --- | --- | --- |
| Các hàm công khai mà màn hình gọi | [services/state/app_state.dart](../../mobile/lib/services/state/app_state.dart) | `AppState`; các hàm chuyển tiếp tới nhóm xử lý bên dưới |
| Đăng nhập / đăng ký / đăng xuất / đăng nhập xã hội | [session_actions.dart](../../mobile/lib/services/state/session_actions.dart) | `_SessionActions.login`, `register`, `logout`, `loginSocial`, `_loadSession` |
| Chọn chi nhánh / tải lại / tạo sửa xóa sản phẩm / ảnh sản phẩm | [catalog_actions.dart](../../mobile/lib/services/state/catalog_actions.dart) | `_CatalogActions.select`, `reload`, `reloadBranches`, `loadProducts`, `saveProduct`, `removeProduct`, `uploadImage` |
| Lưu điểm giao / cửa hàng gần / báo giá | [delivery_location_actions.dart](../../mobile/lib/services/state/delivery_location_actions.dart) | `_DeliveryLocationActions.setLocation`, `loadNearby`, `quoteDelivery` |
| Tăng giảm giỏ / đặt đơn / đổi trạng thái / thu tiền | [cart_order_actions.dart](../../mobile/lib/services/state/cart_order_actions.dart) | `_CartOrderActions.change`, `checkout`, `transition`, `pay` |
| Nhận giao đơn / vị trí và trực tuyến shipper | [shipper_actions.dart](../../mobile/lib/services/state/shipper_actions.dart) | `_ShipperActions.claim`, `setShipperPosition` |
| Hồ sơ / avatar / đổi mật khẩu | [profile_actions.dart](../../mobile/lib/services/state/profile_actions.dart) | `_ProfileActions.refreshProfile`, `updateProfile`, `uploadAvatar`, `removeAvatar`, `changePassword` |
| Endpoint tài khoản / ảnh / tạo cửa hàng | [services/api/account_api.dart](../../mobile/lib/services/api/account_api.dart) | `AccountApi.login`, `updateProfile`, `changePassword`, `createStore`, các hàm `upload...` |
| Cách gửi HTTP / token / đọc lỗi / upload | [services/api/api_client.dart](../../mobile/lib/services/api/api_client.dart) | `ApiClient.request`, `uploadFile` |
| App chuyển màn sau đăng nhập | [app/role_home.dart](../../mobile/lib/app/role_home.dart) | `RoleHome` chọn trang theo vai trò của `state.account` |

Admin có nhiều thao tác gọi `widget.state.api` trực tiếp trong `AdminHome`, `CreatePartner`, `CreateAccount`; tuyến giao shipper được tải trực tiếp trong `ShipperNavigationPage.load()`. Vì vậy cần đọc cả file màn hình, không chỉ tìm trong `AppState`.

### 10.2. Điểm nhận request ở backend

Đường dẫn API dưới đây viết tương đối như trong Flutter; `ApiClient.base` mặc định đã chứa `/api`. Các controller nằm trong `backend/src/main/java/com/cstore/app/controller/`.

| Nhóm nút | API liên quan | Controller cần mở |
| --- | --- | --- |
| Đăng nhập / đăng ký | POST `/auth/login`, `/auth/register` | [AuthController.java](../../backend/src/main/java/com/cstore/app/controller/AuthController.java) |
| Google / Facebook | GET `/auth/providers`, POST `/auth/social` | [SocialAuthController.java](../../backend/src/main/java/com/cstore/app/controller/SocialAuthController.java) |
| Lưu hồ sơ / đổi mật khẩu | GET/PUT `/account/profile`, PUT `/account/password` | [ProfileController.java](../../backend/src/main/java/com/cstore/app/controller/ProfileController.java) |
| Lưu địa chỉ / tìm gần / báo giá | PUT `/customer/location`, GET `/customer/nearby`, POST `/customer/delivery-quote` | [CustomerController.java](../../backend/src/main/java/com/cstore/app/controller/CustomerController.java) |
| Đặt đơn / cửa hàng nhận hoặc từ chối / khách hủy / xác nhận tiền | POST `/customer/orders`, PUT `/merchant/orders/{id}/status`, PUT `/customer/orders/{id}/cancel`, PUT `/{merchant hoặc shipper}/orders/{id}/payment` | [OrderController.java](../../backend/src/main/java/com/cstore/app/controller/OrderController.java) |
| Nhận giao / đổi trạng thái giao / cập nhật GPS / xem tuyến | POST `/shipper/orders/{id}/claim`, PUT `/shipper/orders/{id}/status`, PUT `/shipper/location`, GET `/shipper/orders/{id}/route` | [ShipperController.java](../../backend/src/main/java/com/cstore/app/controller/ShipperController.java) |
| Tạo sửa xóa sản phẩm | POST `/merchant/products`, PUT/DELETE `/merchant/products/{id}` | [ProductController.java](../../backend/src/main/java/com/cstore/app/controller/ProductController.java) |
| Admin tạo / cấm / cho phép / xóa tài khoản | POST `/admin/accounts`, PUT `/admin/accounts/{id}/status`, DELETE `/admin/accounts/{id}` | [AdminAccountController.java](../../backend/src/main/java/com/cstore/app/controller/AdminAccountController.java) |
| Admin tạo thương hiệu / chi nhánh | POST `/admin/stores` | [AdminStoreController.java](../../backend/src/main/java/com/cstore/app/controller/AdminStoreController.java) |
| Admin làm mới số liệu doanh thu | GET `/admin/revenue` | [AdminReportController.java](../../backend/src/main/java/com/cstore/app/controller/AdminReportController.java) |
| Upload ảnh sản phẩm / logo / avatar / xóa avatar | POST `/merchant/products/{id}/image`, `/admin/stores/{id}/image`, `/account/avatar`, `/admin/accounts/{id}/avatar`; DELETE `/account/avatar` | [ImageController.java](../../backend/src/main/java/com/cstore/app/controller/ImageController.java) |

Muốn sửa quy tắc lưu dữ liệu, quyền hoặc trạng thái đơn: theo lời gọi từ controller xuống service/repository được dùng tại đó. Xem thêm [chương backend](backend.md) và [bản đồ khai báo file/class/hàm](ban-do-source.md).

## 11. Cách tìm nhanh khi đổi hoặc thêm nút

1. Tìm chữ trên nút trong `mobile/lib/screens/` hoặc `mobile/lib/widgets/` bằng chức năng tìm trong project của trình soạn thảo.
2. Đọc `onPressed`, `onTap`, `onSelected`, `onChanged` hoặc `onDestinationSelected` bên cạnh widget. Nút biểu tượng thường có tên ở `tooltip`.
3. Nếu callback là tên hàm như `save`, `submit`, `pickup`, tìm hàm đó trong cùng lớp. Tên giống nhau ở hai màn hình là hai hàm khác nhau.
4. Nếu widget nhận `onEdit`, `onAction`, `onFit` hoặc callback khác qua tham số, theo chỗ màn cha truyền callback vào như các bảng phía trên.
5. Nếu thấy `state.xxx`, mở `services/state/app_state.dart` rồi nhóm `*_actions.dart`. Nếu thấy `state.api.xxx` hoặc `state.api.request`, theo `AccountApi`/endpoint tới backend.

Tài liệu đối chiếu source ngày 05/11/2026. Khi thêm, đổi nhãn hoặc di chuyển xử lý của nút, cập nhật hàng tương ứng trong file này. Các mô tả trên là luồng từ source, không thay thế kết quả kiểm thử giao diện hoặc API thực tế.
