# Hướng dẫn thuyết trình giao diện và các nút chức năng C-Store

Tài liệu dùng khi mở ứng dụng Android để trình bày: **đang ở màn nào → bấm nút nào → kết quả gì → nói gì**. Cuối tài liệu có phần giải thích code tạo giao diện và xử lý nút, để trả lời khi giảng viên hỏi.

Nội dung đối chiếu source ngày **05/11/2026**; không phải biên bản chạy thử. Tên chi nhánh, sản phẩm, tài khoản và số liệu phụ thuộc dữ liệu đang có trong hệ thống.

## 1. Chuẩn bị trước buổi thuyết trình

- Mở máy ảo Android đang dùng của dự án; nếu chưa chạy thì mở AVD `Pixel_6`.
- Dùng lại backend và phiên Flutter đang hoạt động. Khi cần chạy mới, làm theo [hướng dẫn chạy dự án](lenh-va-cau-hinh.md), giữ log hiển thị trong Kitty. Không cần mở Chrome vì dự án hiện chạy trên Android.
- Chuẩn bị tài khoản **khách hàng, cửa hàng, shipper và admin**. Cửa hàng phải thuộc đúng chi nhánh sẽ mua hàng. Dùng tài khoản demo đã chuẩn bị; không đưa mật khẩu hoặc token lên slide.
- Chuẩn bị chi nhánh đang hoạt động, có sản phẩm còn tồn kho. Chọn điểm giao gần chi nhánh để có kết quả tìm gần và báo giá đường đi.
- Shipper cần ảnh đại diện, quyền vị trí và tọa độ phù hợp để trực tuyến, nhận đề nghị giao. Nếu demo trên emulator, đặt vị trí máy ảo gần cửa hàng.
- Dùng một đơn xuyên suốt bài demo và ghi lại mã `#CS…` để tìm đúng đơn khi đổi vai trò. Một máy ảo thì lần lượt đăng xuất và đăng nhập các tài khoản.

**Câu mở đầu có thể đọc:**

> “Em xin giới thiệu ứng dụng C-Store, hỗ trợ mua hàng tại cửa hàng tiện lợi và giao đến khách. Hệ thống có bốn vai trò: khách hàng, cửa hàng, shipper và quản trị viên. Em sẽ trình bày giao diện và thực hiện một luồng từ đặt hàng đến giao hàng.”

## 2. Sơ đồ các màn hình

```text
Mở ứng dụng
    └── Đăng nhập / Đăng ký
          ├── Khách hàng: Cửa hàng → Sản phẩm → Giỏ hàng → Xác nhận đặt hàng
          │                          └── Đơn hàng / Hồ sơ
          ├── Cửa hàng: Tổng quan / Sản phẩm / Đơn hàng / Chi nhánh
          ├── Shipper: Đơn gần / Đang giao / Lịch sử / Hồ sơ
          └── Admin: Tổng quan / Thương hiệu / Tài khoản
```

Sau đăng nhập, app chọn giao diện dựa trên vai trò backend trả về. Người dùng không tự chọn vai trò admin hay cửa hàng ở màn đăng nhập.

## 3. Màn hình đăng nhập và đăng ký

**Cách mở:** khởi động app khi chưa có phiên đăng nhập, hoặc đăng xuất khỏi tài khoản hiện tại.

**Trên giao diện:** logo C-Store, lời chào, ô email, ô mật khẩu, nút đăng nhập, nút chuyển sang đăng ký; chế độ đăng nhập có các nút Google/Facebook.

| Nút / thành phần | Thao tác và kết quả | Câu trình bày gợi ý |
| --- | --- | --- |
| Email, Mật khẩu | Nhập thông tin của tài khoản demo | “Người dùng nhập thông tin để hệ thống xác thực tài khoản.” |
| Biểu tượng con mắt | Bật/tắt hiển thị mật khẩu | “Nút này giúp kiểm tra nội dung đã nhập.” |
| Đăng nhập | Kiểm tra form, gửi yêu cầu; thành công thì vào giao diện theo vai trò | “Cùng một màn đăng nhập nhưng mỗi vai trò được đưa đến trang riêng.” |
| Nút chuyển đăng ký/đăng nhập | Đổi chế độ của form | “Người chưa có tài khoản có thể chuyển sang đăng ký.” |
| Họ và tên, Loại tài khoản | Xuất hiện khi đăng ký; chọn Khách hàng hoặc Shipper | “Đăng ký công khai hỗ trợ khách hàng và người giao hàng.” |
| Tạo tài khoản | Đăng ký và đăng nhập khi thành công | “Thông tin hợp lệ sẽ được gửi lên máy chủ để tạo tài khoản.” |
| Google / Facebook | Mở luồng đăng nhập mạng xã hội khi đã cấu hình phù hợp | “Ứng dụng có tích hợp đăng nhập mạng xã hội; phần này cần cấu hình nhà cung cấp.” |

**Demo chính:** đăng nhập bằng tài khoản khách hàng đã chuẩn bị. Chỉ demo Google/Facebook khi đã cấu hình và thử trước buổi trình bày.

**Code để mở khi được hỏi:** [welcome.dart](../../mobile/lib/screens/auth/welcome.dart), tìm `build()`, `submit()`, `registering`; [role_home.dart](../../mobile/lib/app/role_home.dart), tìm `switch (account.role)`.

## 4. Giao diện khách hàng

### 4.1. Trang Cửa hàng — chọn địa chỉ và chi nhánh

**Cách mở:** đăng nhập khách hàng, chọn tab **Cửa hàng** ở thanh dưới.

**Trên giao diện:** khu vực **GIAO ĐẾN**, nội dung giới thiệu, danh sách chi nhánh gần điểm giao. Thanh dưới có **Cửa hàng / Đơn hàng / Hồ sơ**.

| Nút / vùng bấm | Kết quả khi thao tác |
| --- | --- |
| GIAO ĐẾN | Mở bản đồ chọn điểm giao |
| Lấy vị trí GPS trong bản đồ | Xin/lấy vị trí Android và đưa bản đồ đến vị trí đó |
| Chạm vào bản đồ | Ghim điểm, lấy gợi ý địa chỉ; có thể sửa nội dung địa chỉ |
| Phóng to / Thu nhỏ | Thay đổi mức zoom bản đồ |
| Xác nhận vị trí đã ghim | Trả vị trí về trang khách hàng để lưu và tải các chi nhánh gần |
| Thẻ chi nhánh | Chọn chi nhánh và mở danh sách sản phẩm |
| Avatar phía trên / tab Hồ sơ | Mở hồ sơ cá nhân |
| Tab Đơn hàng | Xem các đơn của khách đang đăng nhập |

**Thao tác demo:** bấm **GIAO ĐẾN → ghim điểm → Xác nhận vị trí đã ghim → chọn một chi nhánh**. Chạm biểu tượng cửa hàng trong bản đồ chỉ mở thông tin chi nhánh; chọn chi nhánh mua hàng ở danh sách trang chính.

> “Khách xác nhận điểm nhận hàng trên bản đồ. Dựa vào điểm này, ứng dụng hiển thị các chi nhánh gần và khoảng cách đường đi để khách lựa chọn.”

**Source:** [customer_home.dart](../../mobile/lib/screens/customer/customer_home.dart), [location_picker.dart](../../mobile/lib/screens/location_picker.dart).

### 4.2. Danh sách sản phẩm — tìm và thêm hàng

**Cách mở:** chạm thẻ một chi nhánh.

**Trên giao diện:** tên chi nhánh, ô tìm sản phẩm, bộ lọc danh mục, các thẻ có ảnh/tên/giá, biểu tượng giỏ hàng.

| Nút / thành phần | Kết quả khi thao tác |
| --- | --- |
| Tìm sản phẩm | Lọc tên sản phẩm trong danh sách đã tải |
| Tất cả / tên danh mục | Lọc sản phẩm theo danh mục |
| Thẻ sản phẩm | Mở bảng chi tiết sản phẩm |
| Dấu `+` / Thêm vào giỏ | Thêm một đơn vị; bị giới hạn bởi tồn kho |
| Giỏ hàng ở thanh trên | Mở trang giỏ hàng |
| Xem giỏ · … món | Xuất hiện khi giỏ có hàng, mở giỏ hàng |
| Quay lại | Nếu giỏ có hàng, hỏi **Ở lại** hoặc **Xóa giỏ và rời** |

**Thao tác demo:** thử tìm tên một sản phẩm, chọn danh mục, mở chi tiết, thêm hàng rồi mở giỏ.

> “Khách có thể tìm theo tên hoặc lọc theo danh mục. Khi thêm sản phẩm, số lượng trong giỏ thay đổi ngay. Giỏ mua hàng gắn với chi nhánh đang chọn.”

**Source:** [shop_page.dart](../../mobile/lib/screens/customer/shop_page.dart).

### 4.3. Giỏ hàng — điều chỉnh số lượng

**Trên giao diện:** ảnh và tên sản phẩm, đơn giá, số lượng, tạm tính, nút **Tiếp tục đặt hàng**.

| Nút | Kết quả khi thao tác |
| --- | --- |
| `+` | Tăng số lượng nếu chưa đạt tồn kho |
| `−` | Giảm số lượng; về 0 thì bỏ sản phẩm khỏi giỏ |
| Tiếp tục đặt hàng | Chuyển sang trang xác nhận; chưa tạo đơn tại bước này |

> “Ở giỏ hàng, khách kiểm tra sản phẩm và điều chỉnh số lượng. Tạm tính là tiền hàng; phí giao được tính theo điểm giao ở bước xác nhận.”

**Source:** [cart_page.dart](../../mobile/lib/screens/customer/cart_page.dart).

### 4.4. Xác nhận đặt hàng — tạo đơn COD

**Trên giao diện:** thông tin người nhận, số điện thoại, địa chỉ/điểm ghim, thông tin phí giao và tổng tiền.

| Nút / thành phần | Kết quả khi thao tác |
| --- | --- |
| Người nhận / Số điện thoại | Nhập hoặc kiểm tra thông tin nhận hàng |
| Chọn điểm giao trên bản đồ / Đã ghim vị trí giao hàng | Chọn hoặc đổi điểm giao rồi tải lại báo giá |
| Thử lại tuyến đường | Tải lại báo giá khi lấy đường đi gặp lỗi |
| Xác nhận đặt hàng COD | Kiểm tra form, điểm ghim và báo giá; gửi tạo đơn, thành công thì mở chi tiết đơn |

**Thao tác demo:** kiểm tra thông tin, chờ phí giao tải xong, bấm **Xác nhận đặt hàng COD**, ghi lại mã đơn.

> “Khách kiểm tra người nhận, điểm giao, tiền hàng và phí giao trước khi xác nhận. Đây là hình thức COD, tức thanh toán khi nhận hàng. Backend kiểm tra lại giá và tồn kho trước khi tạo đơn.”

**Source:** [checkout_page.dart](../../mobile/lib/screens/customer/checkout_page.dart), tìm `loadQuote()` và `submit()`.

### 4.5. Đơn hàng và hồ sơ

| Màn hình | Nút / thao tác chính | Kết quả |
| --- | --- | --- |
| Đơn hàng | Lọc trạng thái, lọc ngày, kéo làm mới | Thu hẹp hoặc tải lại danh sách đơn |
| Danh sách đơn | Chạm thẻ đơn | Mở thông tin giao hàng, món hàng, tổng tiền, thanh toán và lịch sử xử lý |
| Chi tiết đơn chờ xác nhận | Hủy đơn hàng | Mở xác nhận hủy; chỉ dùng khi cửa hàng chưa chấp nhận |
| Hồ sơ | Chỉnh sửa hồ sơ / chọn ảnh / Lưu hồ sơ | Cập nhật thông tin cá nhân và ảnh |
| Hồ sơ | Địa chỉ giao hàng | Mở chọn điểm giao cho khách |
| Hồ sơ | Đổi mật khẩu | Mở form đổi mật khẩu nếu tài khoản có mật khẩu |
| Hồ sơ | Đăng xuất tài khoản | Kết thúc phiên, trở về màn đăng nhập |

**Với đơn đang demo:** giữ đơn để cửa hàng xử lý. Muốn trình bày hủy thì dùng một đơn khác hoặc mở hộp thoại rồi chọn **Giữ đơn**.

> “Khách theo dõi được trạng thái và lịch sử của đơn. Nút hủy chỉ xuất hiện ở giai đoạn còn chờ xác nhận.”

**Source:** [order_list_page.dart](../../mobile/lib/screens/orders/order_list_page.dart), [order_detail_page.dart](../../mobile/lib/screens/orders/order_detail_page.dart), [profile_page.dart](../../mobile/lib/screens/profile/profile_page.dart).

## 5. Giao diện cửa hàng

**Cách mở:** đăng xuất khách, đăng nhập tài khoản của đúng chi nhánh vừa đặt. Thanh dưới có **Tổng quan / Sản phẩm / Đơn hàng / Chi nhánh**.

| Tab / màn hình | Nội dung nhìn thấy | Nút và chức năng chính |
| --- | --- | --- |
| Tổng quan | Doanh thu tiền hàng, thống kê đơn và tồn kho | Bộ lọc thời gian báo cáo; các ô dẫn sang đơn hàng hoặc sản phẩm; kéo làm mới |
| Sản phẩm | Danh sách sản phẩm và số lượng tồn | Thêm sản phẩm, tìm tên, lọc danh mục, lọc Tất cả / Sắp hết / Hết hàng |
| Form sản phẩm | Thông tin, giá, tồn kho và ảnh sản phẩm | Thư viện ảnh / Chụp ảnh / Lưu sản phẩm; khi sửa có Xóa sản phẩm |
| Đơn hàng | Các đơn thuộc chi nhánh | Lọc và mở đơn; đơn đang chờ có Chấp nhận đơn / Từ chối đơn |
| Chi nhánh | Thông tin chi nhánh và tài khoản | Đổi mật khẩu, Đăng xuất tài khoản |

**Thao tác demo chính:** vào **Đơn hàng → mở đúng mã đơn → Chấp nhận đơn**. Kết quả mong đợi của luồng này là trạng thái chuyển từ **Chờ xác nhận** sang **Chờ shipper**.

> “Cửa hàng quản lý sản phẩm và tồn kho tại chi nhánh của mình. Khi nhận đơn mới, cửa hàng xem chi tiết rồi chấp nhận hoặc từ chối có lý do. Sau khi chấp nhận, đơn chuyển sang giai đoạn tìm shipper.”

**Nếu trình bày báo cáo:** doanh thu tiền hàng trên tổng quan tính các đơn **đã giao và đã thanh toán** trong kỳ. Đơn mới tạo hoặc mới chấp nhận chưa được tính vào số này.

**Source:** [store_home.dart](../../mobile/lib/screens/store/store_home.dart), [store_inventory.dart](../../mobile/lib/screens/store/widgets/store_inventory.dart), [product_editor.dart](../../mobile/lib/screens/store/product_editor.dart), [store_dashboard.dart](../../mobile/lib/screens/store/widgets/store_dashboard.dart).

## 6. Giao diện shipper

**Cách mở:** đăng nhập shipper. Thanh dưới có **Đơn gần / Đang giao / Lịch sử / Hồ sơ**.

**Trên giao diện:** hồ sơ tài xế, công tắc trực tuyến, nút cập nhật GPS, các đề nghị giao phù hợp và đơn đã nhận.

| Nút / thành phần | Khi dùng | Kết quả |
| --- | --- | --- |
| Hoàn thiện hồ sơ shipper | Khi thiếu ảnh đại diện | Mở hồ sơ để bổ sung ảnh trước khi nhận đơn |
| Công tắc trực tuyến | Khi sẵn sàng nhận đơn | Cập nhật trạng thái và vị trí; cần lấy được vị trí phù hợp |
| Nút cập nhật vị trí GPS | Khi cần cập nhật tọa độ | Lấy vị trí Android và gửi lên backend |
| Thẻ đơn ở Đơn gần | Khi có đề nghị giao phù hợp | Mở chi tiết để xem và nhận giao |
| Nhận giao đơn này | Đơn đã được cửa hàng chấp nhận, shipper đủ điều kiện | Gán đơn cho shipper; trạng thái Đã nhận giao |
| Xem đường đến cửa hàng / Mở bản đồ giao hàng | Khi xem lộ trình | Mở bản đồ tuyến lấy hàng và giao hàng |
| Đã lấy hàng | Sau khi nhận đơn và đến cửa hàng lấy hàng | Chuyển sang Đã lấy hàng; server kiểm tra điều kiện |
| Bắt đầu giao | Sau bước lấy hàng | Chuyển sang Đang giao |
| Xác nhận đã nhận tiền | Khi đã lấy hàng hoặc đang giao, chưa ghi nhận thanh toán | Mở hộp thoại; chọn Đã nhận đủ để ghi nhận thu COD |
| Xác nhận đã giao | Sau khi giao hàng và đã ghi nhận thanh toán | Chuyển sang Đã giao nếu các điều kiện backend hợp lệ |
| Lịch sử | Sau khi hoàn tất | Xem lại các đơn giao hoàn tất |

**Thứ tự demo:**

```text
Bổ sung ảnh nếu thiếu → bật trực tuyến → mở đơn phù hợp → Nhận giao đơn này
→ mở bản đồ → đến cửa hàng → Đã lấy hàng → Bắt đầu giao
→ thu COD → Xác nhận đã nhận tiền → Đã nhận đủ → Xác nhận đã giao
```

**Trên máy ảo:** GPS có thể chưa ở gần cửa hàng nên thao tác lấy hàng bị từ chối. Trang bản đồ có luồng **Mô phỏng đã tới cửa hàng và nhận hàng** với hộp thoại xác nhận. Nếu dùng, nói rõ đây là mô phỏng để minh họa; thao tác này không chứng minh GPS trên điện thoại thật. Xem tuyến đường không tự xác nhận đã đến nơi.

> “Shipper bật trạng thái trực tuyến để nhận các đề nghị phù hợp. Sau khi nhận đơn, tài xế xem tuyến đến cửa hàng, xác nhận lấy hàng và bắt đầu giao. Khi giao đến khách, tài xế thu COD, ghi nhận thanh toán rồi hoàn tất đơn.”

**Source:** [shipper_home.dart](../../mobile/lib/screens/shipper/shipper_home.dart), [navigation_route.dart](../../mobile/lib/screens/shipper/navigation_route.dart), [order_detail_page.dart](../../mobile/lib/screens/orders/order_detail_page.dart), tìm `actions()`.

## 7. Giao diện quản trị viên

**Cách mở:** đăng nhập tài khoản admin đã có. Thanh dưới có **Tổng quan / Thương hiệu / Tài khoản**.

| Tab / màn hình | Nút / thao tác chính | Chức năng |
| --- | --- | --- |
| Tổng quan | Làm mới dữ liệu, Xem tất cả thương hiệu, chạm thẻ thương hiệu | Xem thống kê và mở chi tiết thương hiệu |
| Thương hiệu | Tìm thương hiệu; Đang hoạt động / Lịch sử đã ngừng | Tìm và lọc thương hiệu |
| Thương hiệu | Tạo thương hiệu | Mở form tạo thương hiệu, chi nhánh và tài khoản |
| Chi tiết thương hiệu đang hoạt động | Thêm chi nhánh | Mở form tạo chi nhánh thuộc thương hiệu |
| Form tạo thương hiệu / chi nhánh | Ghim vị trí, chọn ảnh, nút tạo | Nhập thông tin và tạo chi nhánh kèm tài khoản; tên nút thay đổi theo chế độ |
| Tài khoản | Lọc vai trò, tìm tên/email, lọc ngày, sắp xếp | Tìm tài khoản cần quản lý |
| Tài khoản | Thêm tài khoản | Mở form tạo tài khoản và chọn vai trò phù hợp |
| Menu ba chấm của tài khoản khác | Cập nhật ảnh, Cấm đăng nhập / Cho phép đăng nhập, Xóa | Thực hiện quản lý; mục ảnh không áp dụng cho tài khoản cửa hàng |

**Thao tác demo gợi ý:** xem tổng quan, mở một thương hiệu, xem các chi nhánh, chuyển sang tài khoản và thử bộ lọc. Có thể mở form tạo để giới thiệu các trường rồi quay lại. Nếu cần minh họa cấm/xóa, mở hộp thoại rồi chọn **Hủy** để giữ tài khoản demo cho các bước sau.

> “Quản trị viên theo dõi dữ liệu toàn hệ thống, quản lý thương hiệu, chi nhánh và tài khoản. Các bộ lọc giúp tìm đúng đối tượng; những thao tác như cấm hoặc xóa tài khoản có bước xác nhận.”

**Source:** [admin_home.dart](../../mobile/lib/screens/admin/admin_home.dart), [create_partner_page.dart](../../mobile/lib/screens/admin/pages/create_partner_page.dart), [create_account_page.dart](../../mobile/lib/screens/admin/pages/create_account_page.dart).

## 8. Nếu được hỏi: code nào làm hiện giao diện và nút?

### 8.1. Từ khởi động đến màn hình đầu tiên

```text
main.dart: main() → runApp(const CStoreApp())
    → app/app.dart: MaterialApp, theme, home: RoleHome(state: state)
        → app/role_home.dart: kiểm tra state.account
            ├── Chưa đăng nhập → LoginPage
            └── Đã đăng nhập → trang theo account.role
```

> “Flutter dựng giao diện từ các widget. Hàm main chạy widget gốc CStoreApp. MaterialApp cấu hình ứng dụng, còn RoleHome chọn màn hình dựa trên phiên đăng nhập và vai trò.”

Mở lần lượt [main.dart](../../mobile/lib/main.dart), [app.dart](../../mobile/lib/app/app.dart), [role_home.dart](../../mobile/lib/app/role_home.dart).

### 8.2. Các widget tạo những phần nhìn thấy

| Tên trong code | Phần hiện trên màn hình |
| --- | --- |
| `Scaffold` | Khung trang, ghép thanh trên, nội dung và thanh dưới |
| `AppBar` | Thanh tiêu đề phía trên và các nút biểu tượng |
| `SafeArea` | Giữ nội dung tránh vùng tai thỏ/thanh hệ thống |
| `ListView`, `Column`, `Row` | Danh sách cuộn, bố cục dọc, bố cục ngang |
| `Text`, `Icon`, `ProductImage` | Chữ, biểu tượng, ảnh sản phẩm |
| `TextFormField`, `Form` | Ô nhập và nhóm kiểm tra dữ liệu nhập |
| `FilledButton`, `OutlinedButton`, `TextButton` | Nút có nền, nút viền, nút chữ |
| `IconButton` | Nút biểu tượng như giỏ hàng, đăng xuất, dấu cộng/trừ |
| `InkWell` | Làm thẻ hoặc vùng nội dung có thể chạm |
| `NavigationBar` | Thanh chọn tab phía dưới |
| `ChoiceChip` | Nút lựa chọn bộ lọc như danh mục, trạng thái |
| `Navigator.push(...)` | Mở một trang khác |
| `showDialog(...)` | Hiện hộp thoại xác nhận |
| `showModalBottomSheet(...)` | Hiện bảng từ dưới lên, ví dụ chi tiết sản phẩm |

**Cách giải thích:** `build()` trả về cây widget mô tả giao diện; `child` là phần tử con, `children` là danh sách phần tử con. Các thuộc tính `padding`, `color`, `style` điều chỉnh khoảng cách và hình thức.

### 8.3. Nút hiện lên và nút chạy chức năng là hai phần của cùng một widget

Ví dụ trích từ nút đăng nhập trong [welcome.dart](../../mobile/lib/screens/auth/welcome.dart):

```dart
FilledButton(
  onPressed: busy ? null : submit,
  // child hiển thị chữ hoặc vòng chờ theo trạng thái.
)
```

Đây là trích đoạn để đọc, không phải một file Dart hoàn chỉnh.

- `FilledButton` tạo nút có nền; `child` quyết định nội dung nhìn thấy.
- `onPressed` nối thao tác bấm với hàm `submit`.
- Khi `busy` là `true`, `onPressed` nhận `null`, nút bị vô hiệu hóa trong lúc xử lý.
- `submit()` kiểm tra form rồi gọi `state.login(...)` hoặc `state.register(...)`.

> “Phần widget tạo hình thức nút, còn onPressed quy định chức năng. Vì vậy muốn biết nút làm gì, em theo từ onPressed đến hàm xử lý.”

### 8.4. Vì sao bấm nút xong màn hình thay đổi?

Có hai ví dụ dễ trình bày:

**Đổi tab:** callback gọi `setState(() => tab = i)`. Flutter dựng lại trang với nội dung tương ứng tab mới. Ví dụ ở [store_home.dart](../../mobile/lib/screens/store/store_home.dart).

**Tăng số lượng giỏ:** màn hình gọi `state.change(product, 1)`. Phần xử lý sửa giỏ và gọi `app.refresh()`. Trong `AppState`, `refresh()` gọi `notifyListeners()`; các `ListenableBuilder` đang nghe state dựng lại nội dung liên quan.

```text
Bấm + → state.change(...) → cập nhật cart → refresh()/notifyListeners()
    → ListenableBuilder dựng lại → số lượng và tạm tính thay đổi
```

Xem [cart_order_actions.dart](../../mobile/lib/services/state/cart_order_actions.dart) và [app_state.dart](../../mobile/lib/services/state/app_state.dart).

**Phân biệt khi nói:** tăng/giảm giỏ xử lý trong RAM của app. Bấm xác nhận đặt hàng mới gửi yêu cầu tạo đơn lên backend. Backend kiểm tra quyền, giá và tồn kho rồi lưu vào database.

### 8.5. Vì sao có nút lúc thấy, lúc không?

Ở [order_detail_page.dart](../../mobile/lib/screens/orders/order_detail_page.dart), hàm `actions()` kiểm tra **vai trò và trạng thái đơn**:

- Khách + đơn chờ xác nhận: hiện **Hủy đơn hàng**.
- Cửa hàng + đơn chờ xác nhận: hiện **Chấp nhận đơn / Từ chối đơn**.
- Shipper + đơn chờ shipper: có nút **Nhận giao đơn này** trong chi tiết đề nghị.
- Shipper được gán đơn: nút lần lượt là **Đã lấy hàng → Bắt đầu giao → Xác nhận đã giao** theo trạng thái.

> “Giao diện hiển thị thao tác phù hợp với vai trò và tiến độ đơn. Backend vẫn xác thực quyền và điều kiện khi nhận yêu cầu, nên việc ẩn nút chỉ là một phần của giao diện.”

## 9. Kịch bản trình bày khoảng 12–15 phút

| Thời lượng dự kiến | Màn hình / thao tác | Ý cần nói |
| --- | --- | --- |
| 1 phút | Giới thiệu và màn đăng nhập | Mục tiêu ứng dụng, bốn vai trò, form đăng nhập/đăng ký |
| 3 phút | Khách: điểm giao → chi nhánh → sản phẩm → giỏ → xác nhận | Cách tìm mua hàng, số lượng, tiền hàng, phí giao và COD |
| 2 phút | Cửa hàng: sản phẩm → đơn → Chấp nhận đơn | Quản lý tồn kho và xử lý đơn mới |
| 3–4 phút | Shipper: trực tuyến → nhận đơn → bản đồ → lấy/giao → thu COD → hoàn tất | Trình tự xử lý giao hàng, phân biệt mô phỏng nếu có dùng |
| 1–2 phút | Admin: tổng quan → thương hiệu → tài khoản | Quản lý toàn hệ thống và bộ lọc |
| 2 phút | Mở code main → RoleHome → một nút → AppState | Giao diện được dựng thế nào, nút nối với hàm và cập nhật dữ liệu ra sao |

Thời gian trên là dự kiến, chưa gồm thời gian xử lý mạng hoặc nhập lại tài khoản. Nếu chỉ có 5–7 phút, ưu tiên khách đặt đơn, cửa hàng chấp nhận và giới thiệu nhanh màn shipper/admin; trình bày đúng bước đã thực hiện thực tế.

**Lời kết có thể đọc:**

> “Qua phần demo, em đã trình bày cách các vai trò phối hợp trong một đơn hàng. Flutter hiển thị giao diện và tiếp nhận thao tác, Spring Boot kiểm tra và xử lý nghiệp vụ, MySQL lưu dữ liệu. Các nút xuất hiện theo vai trò và trạng thái để người dùng thực hiện đúng bước.”

## 10. Những tình huống dễ gặp khi demo

| Hiện tượng | Cách xử lý / cách giải thích |
| --- | --- |
| Không kết nối được máy chủ | Kiểm tra backend và log Kitty; emulator mặc định gọi `http://10.0.2.2:8080` |
| Không thấy chi nhánh gần | Xác nhận điểm ghim gần chi nhánh hoạt động; danh sách phụ thuộc kết quả tính đường đi |
| Không lấy được phí giao | Kiểm tra mạng và dịch vụ định tuyến, dùng Thử lại tuyến đường; chờ báo giá hợp lệ trước khi đặt |
| Không thêm được sản phẩm | Kiểm tra tồn kho và chi nhánh đang chọn |
| Shipper không bật trực tuyến / không thấy đơn | Kiểm tra ảnh hồ sơ, quyền GPS, tọa độ, trạng thái đơn đã được cửa hàng chấp nhận và điều kiện nhận giao |
| Bấm Đã lấy hàng bị từ chối | Kiểm tra vị trí so với cửa hàng; trên máy ảo có thể dùng luồng mô phỏng trong bản đồ và giải thích rõ |
| Chưa hoàn tất được đơn | Kiểm tra đúng thứ tự trạng thái và đã ghi nhận nhận tiền COD |
| Vai trò khác chưa thấy dữ liệu mới | Chờ lượt tải lại hoặc kéo làm mới; các màn khách/cửa hàng/shipper có tải định kỳ khoảng 10 giây |
| Doanh thu chưa tăng | Chỉ tính đúng kỳ và các đơn đã giao, đã thanh toán; làm mới màn báo cáo |

Muốn tra chi tiết mọi nút và hàm xử lý, mở [bản đồ các nút](ban-do-cac-nut.md). Muốn giải thích sâu đăng ký, đăng nhập, đặt hàng và giao hàng đến backend, mở [tài liệu luồng nghiệp vụ](thuyet-trinh-dang-ky-dang-nhap-dat-hang-giao-hang.md).
