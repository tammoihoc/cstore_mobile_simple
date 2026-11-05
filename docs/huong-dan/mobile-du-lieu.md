# Đọc phần dữ liệu và logic Flutter

Chương này nối những gì thấy trên màn hình với dữ liệu thực tế. Đọc cùng [kiến trúc](kien-truc-va-luong-chay.md), [giao diện](mobile-giao-dien.md) và [bản giải thích từng dòng](doc-tung-dong.md).

## 1. Cách đọc một dòng Dart

```dart
final account = await api.login(email.trim(), password);
```

Đọc từ phải sang trái: `trim()` bỏ khoảng trắng đầu/cuối email; `api.login(...)` bắt đầu lời gọi bất đồng bộ; `await` đợi lời gọi trả kết quả; kết quả được gán vào biến `account`; `final` không cho gán lại biến đó sau lần khởi tạo. `final` không tự khiến mọi thuộc tính bên trong một đối tượng trở thành bất biến.

```dart
Future<void> reload() async {
  await app.loadProducts();
  app.refresh();
}
```

- `Future<void>`: bên gọi nhận một tác vụ sẽ hoàn thành sau, không có dữ liệu trả về để dùng.
- `async`: thân hàm được phép dùng `await` và kết quả được biểu diễn bằng Future.
- Dấu `{` mở thân hàm. Hai dấu cách hoặc mức thụt lề cho thấy câu lệnh thuộc khối nào.
- `await app.loadProducts()` giữ thứ tự: tải xong mới đi tiếp; lỗi có thể được ném tới bên gọi.
- `app.refresh()` thông báo dữ liệu đã đổi để các widget đang lắng nghe dựng lại.
- `;` kết thúc câu lệnh. `}` đóng thân hàm; nó không có nghĩa gọi thêm một tác vụ.

Trong source thật, `reload()` còn phân nhánh vai trò, bật/tắt loading và xử lý lỗi. Đoạn nhỏ trên chỉ minh họa cách đọc cú pháp.

## 2. Những thư mục cần tìm

| Vị trí | Câu hỏi nó trả lời |
| --- | --- |
| `lib/main.dart` | App bắt đầu từ đâu? |
| `lib/app/app.dart` | Ai tạo AppState, theme và widget gốc? |
| `lib/app/role_home.dart` | Khi tài khoản thay đổi, app chọn màn nào? |
| `lib/app/theme/app_theme.dart` | Màu/font/kích thước chung ở đâu? |
| `lib/models/` | Dữ liệu có các thuộc tính và kiểu gì? |
| `lib/services/api/api_client.dart` | HTTP được gửi, giải mã và báo lỗi như thế nào? |
| `lib/services/api/account_api.dart` | Endpoint cụ thể trả kiểu dữ liệu gì? |
| `lib/services/state/app_state.dart` | Dữ liệu RAM hiện tại và điểm gọi công khai nằm ở đâu? |
| `lib/services/state/*_actions.dart` | Từng nhóm hành động thay đổi trạng thái thế nào? |
| `lib/services/location_service.dart` | App xin quyền và lấy GPS ra sao? |
| `lib/services/geocoding_service.dart` | Đổi tọa độ sang địa chỉ, debounce và cache như thế nào? |
| `lib/services/social_sign_in.dart` | Plugin lấy chứng nhận Google/Facebook như thế nào? |

`services/app_state.dart` và `services/account_api.dart` ở cấp ngoài chỉ export triển khai trong thư mục con. Đó là cách giữ các import đang dùng, không phải hai class cùng tên chạy song song.

## 3. Model: đừng gộp mọi dữ liệu vào một class

| File | Loại dữ liệu | Ví dụ điều cần chú ý |
| --- | --- | --- |
| `role.dart` | Bốn vai trò | Giá trị này lấy từ tài khoản server, không do form login tự chọn |
| `account.dart` | Tài khoản | `storeId` có thể null; avatar có thể rỗng; không chứa mật khẩu |
| `branch.dart` | Chi nhánh | Tọa độ, trạng thái mở và URL logo |
| `product.dart` | Sản phẩm | Giá/tồn có thể thay đổi; `active` quyết định đang bán |
| `delivery_quote.dart` | Báo giá giao | Kiểm tra km, thời gian và phí không âm, số phải hữu hạn |
| `order_status.dart` | Trạng thái đơn | API dùng `PICKED_UP`, Dart dùng `OrderStatus.pickedUp` |
| `order.dart` | Đơn, dòng hàng, lịch sử | Dòng hàng giữ giá đã chốt; thanh toán đọc từ `paidAt` |
| `number_format.dart` | Hàm thuần | Đổi số thành tiền hiển thị; tính Haversine khi cần |
| `store_metrics.dart` | Tổng hợp dashboard | Chỉ tính doanh thu từ đơn đủ điều kiện giao và thanh toán |

`models.dart` export các file trên, giúp màn hình tiếp tục dùng một dòng import chung. Khi học một cấu trúc dữ liệu, mở file riêng của nó thay vì đọc một file trộn nhiều class.

### JSON thành Account

Trong `Account.fromJson`, dữ liệu đi theo từng bước:

1. Đọc `id`, `email`, `name` bằng đúng kiểu đang được API trả về.
2. Đổi chuỗi vai trò sang chữ thường rồi tìm enum Dart tương ứng.
3. Đọc các trường nullable như `storeId`, `createdAt`.
4. Áp dụng giá trị mặc định cho trường tùy chọn như avatar, giới tính, điện thoại.
5. Tạo đối tượng `Account` để UI dùng cú pháp `account.name`, không lặp việc truy cập Map ở mọi màn.

`as String` là kiểm tra/ép kiểu theo dữ liệu đã biết; nó không biến một số bất kỳ thành chuỗi. Khi muốn biểu diễn mã dạng chuỗi, source dùng `toString()` hoặc nội suy chuỗi. `(value as num).toDouble()` cho phép số JSON là int hoặc double rồi thống nhất thành double.

### Tại sao giá đơn khác giá sản phẩm?

`Product.price` là giá catalog app vừa tải. `OrderLine.price` là giá server đã chốt vào đơn. Đổi giá sản phẩm hôm nay không được đổi tiền đơn đã đặt hôm qua. Vì vậy có hai loại model và backend lưu snapshot dòng hàng.

### Tiền và khoảng cách

Hàm `money` chỉ tạo chuỗi có dấu phân cách hàng nghìn và ký hiệu đồng; không cộng tiền hoặc thanh toán. Haversine ở `distance` tính khoảng cách đường chim bay trên mô hình Trái Đất gần cầu. Báo giá giao trong luồng hiện tại lấy từ backend, nơi dùng tuyến đường bộ OSRM và điều kiện phạm vi. Không thay báo giá server bằng Haversine trên điện thoại.

## 4. AppState giữ gì trong RAM?

| Nhóm | Thuộc tính chính | Khi nào thay đổi? |
| --- | --- | --- |
| Dịch vụ | `api`, `socialSignIn` | Khởi tạo cùng AppState |
| Phiên | `account`, `api.token` | Login, cập nhật hồ sơ, đổi mật khẩu, logout |
| Catalog | `branchList`, `products`, `selected` | Tải chi nhánh, chọn cửa hàng, refresh sản phẩm |
| Đơn và giỏ | `orders`, `cart`, `_offers` | Đọc server, thêm/bớt số lượng, checkout, cập nhật trạng thái |
| Điểm giao khách | `lat`, `lng`, `location`, `positionKnown` | Chọn/lưu ghim và đọc lại sau login |
| Vị trí shipper | `shipperLat`, `shipperLng`, `online`, `shipperSimulated` | GPS, bật/tắt online hoặc mô phỏng kiểm thử |
| Báo giá gần khách | `nearbyQuotes`, `nearbyLoading`, `nearbyError` | Tải danh sách khoảng cách cho ghim hiện tại |
| Giao diện tải/lỗi | `loading`, `error` | Trước và sau request theo vai trò |
| Chống kết quả cũ | `_productsRevision`, `_nearbyRevision`, `_accountEpoch` | Tải mới, đổi ghim, đăng xuất |
| Polling | `timer` | Bắt đầu sau login, hủy khi logout/dispose |

`cart` là Map từ **mã sản phẩm → số lượng**, không phải danh sách giá do người dùng tự quyết. `selected` là chi nhánh đang mua; khi đổi chi nhánh, giỏ và catalog cũ phải được xóa theo logic hiện có.

Getter như `subtotal`, `customerOrders`, `storeOrders`, `deliveries` tính từ dữ liệu trong RAM. Gọi getter không đồng nghĩa truy vấn SQL hoặc tự đồng bộ mạng.

## 5. AppState và các nhóm xử lý có quan hệ gì?

```dart
late final _catalog = _CatalogActions(this);
```

- `late`: tạo giá trị khi lần đầu sử dụng.
- `final`: sau khi tạo, không gán một helper khác vào cùng biến.
- `_catalog`: biến private của thư viện Dart.
- `_CatalogActions(this)`: helper nhận tham chiếu tới chính AppState hiện tại.

```dart
Future<void> loadProducts() {
  return _catalog.loadProducts();
}
```

Đây là hàm chuyển tiếp có tên công khai mà các màn đã gọi. Logic thật nằm trong `catalog_actions.dart`. Nó không tạo một request thứ hai và không tạo bản sao AppState. Cách tách này giữ các điểm gọi hiện có, nhưng đưa từng trách nhiệm sang file dễ đọc hơn.

| Nhóm | Các thao tác bạn sẽ tìm thấy |
| --- | --- |
| `_SessionActions` | `login`, `loginSocial`, `_loadSession`, `register`, `logout` |
| `_CatalogActions` | Đọc chi nhánh, sản phẩm, đơn; chọn chi nhánh; lưu/xóa sản phẩm; upload ảnh |
| `_DeliveryLocationActions` | Lưu ghim, tải cửa hàng gần, báo giá, kiểm tra tọa độ |
| `_CartOrderActions` | Đổi số lượng, checkout, đổi trạng thái, ghi nhận thanh toán |
| `_ProfileActions` | Đọc/sửa hồ sơ, ảnh và mật khẩu |
| `_ShipperActions` | Nhận đơn, bật online và gửi vị trí |

Các file nhóm bắt đầu bằng `part of 'app_state.dart';`; file chính khai báo `part '...';`. Vì vậy chúng thuộc cùng thư viện và được phép truy cập thành phần private như `_accountEpoch`. Từ screen, import `services/app_state.dart`; không import trực tiếp file `*_actions.dart`.

## 6. HTTP: hai lớp có nhiệm vụ khác nhau

`ApiClient` biết cách gửi HTTP và đọc lỗi. `AccountApi extends ApiClient` bổ sung endpoint và chuyển JSON thành model. Đây là kế thừa một lớp cụ thể, không phải kiến trúc microservice hay hai API server.

Một lời gọi đi qua:

1. Ghép `base`, `/api` và path tương đối.
2. Tạo header JSON; thêm `Authorization` nếu phiên đã có token.
3. Chọn method: mặc định GET khi không có body, POST khi có body; caller có thể chỉ định PUT/DELETE.
4. Gửi request và áp dụng timeout; truy vấn gần khách được chờ dài hơn request thường.
5. Nếu status từ 400 trở lên, cố đọc thông điệp JSON, rồi ném `StateError` phù hợp.
6. Nếu body rỗng, trả null; nếu có dữ liệu, giải mã UTF-8 rồi JSON.
7. Lớp endpoint tạo model, ví dụ `Account.fromJson`.

Các chuỗi `$base`, `$path` trong code là nội suy **giá trị biến**, không phải ký hiệu shell trong terminal. Đừng ghép token vào URL hoặc log. HTTP không tự mã hóa đường truyền; dùng HTTPS khi cấu hình môi trường thật.

### Upload ảnh

`uploadFile` dùng `MultipartRequest` và `MultipartFile.fromBytes`: một phần request tên `file` chứa byte ảnh. Server nhận và kiểm tra ảnh rồi lưu đường dẫn. `client.send` trả stream; `drain()` tiêu thụ phần response để giải phóng tài nguyên. Việc app chọn ảnh được không chứng minh server đã lưu ảnh; phải chờ HTTP thành công và tải dữ liệu mới.

## 7. Đăng nhập thành công rồi chuyện gì xảy ra?

`_SessionActions.login` chờ `api.login`, gán `account`, rồi `_loadSession`. Nếu có lỗi trong login hoặc các bước nạp phiên, catch gọi logout để xóa phiên dở dang và `rethrow` cho form hiển thị lỗi.

`_loadSession`:

1. Tải chi nhánh trước vì nhiều màn cần mã và tọa độ cửa hàng.
2. Với khách, đọc điểm giao đã lưu; chỉ áp dụng khi có xác nhận ghim, tọa độ hợp lệ và địa chỉ không rỗng.
3. Với cửa hàng, kiểm tra chi nhánh gắn tài khoản có trong dữ liệu nhận về.
4. Tải dữ liệu theo vai trò.
5. Hủy timer cũ nếu có, rồi tạo timer gọi reload mỗi 10 giây. reload chỉ tải dữ liệu cho khách/cửa hàng/shipper; danh sách tài khoản và báo cáo admin có luồng load riêng ở AdminHome.

`unawaited(loadNearby())` cố ý không chờ báo giá gần khách trước khi đi tiếp. Hàm được gọi vẫn phải tự xử lý lỗi của nó; không phải mọi lỗi bất đồng bộ đều bị tự bỏ qua.

## 8. Tại sao phải có revision/epoch?

Giả sử bạn chọn cửa hàng A, sau đó nhanh tay chọn B. Request A chậm, B nhanh. Nếu cứ gán kết quả theo thứ tự server trả về, sản phẩm A có thể ghi đè màn đang mua B.

`loadProducts` tăng `_productsRevision`, ghi số vừa tăng vào biến cục bộ, gọi mạng, rồi so lại trước khi gán. Nếu số không còn khớp, request thuộc lần cũ nên kết thúc sớm. Logic tương tự được dùng cho ghim giao với `_nearbyRevision`.

`_accountEpoch` đánh dấu thay đổi phiên. Những thao tác hồ sơ có kiểm tra epoch sẽ bỏ kết quả nếu logout xảy ra trong lúc chờ. Đây là bảo vệ ở các hàm **có kiểm tra tương ứng**, không phải cơ chế tự hủy mọi HTTP request hoặc bảo vệ toàn cục cho mọi hàm trong AppState.

Khi đọc một hàm bất đồng bộ, tự hỏi: người dùng có thể đổi màn, tài khoản hoặc ghim trước khi response về không? Source hiện tại dùng cả `mounted` ở UI và các số phiên/lần tải ở state; hai cơ chế giải quyết hai vấn đề khác nhau.

## 9. Theo dõi một đơn hàng

### Thêm/bớt sản phẩm

`change` kiểm tra sản phẩm thuộc cửa hàng đang chọn, còn bán và số lượng tiếp theo không vượt tồn app đang biết. Số lượng về 0 thì bỏ khỏi Map. Cuối cùng gọi refresh để UI đổi tổng tiền. Kiểm tra ở app giúp phản hồi nhanh; server vẫn phải kiểm tra tồn thật lúc checkout.

### Checkout

Hàm kiểm tra giỏ/chi nhánh, gửi dữ liệu giao và danh sách mã/số lượng, nhận JSON đơn, tạo `ShopOrder`, xóa giỏ rồi tải lại dữ liệu. Nếu request tạo đơn ném lỗi, code chưa đi tới dòng xóa giỏ. Nếu bước reload gặp lỗi, trạng thái lỗi được quản lý theo logic reload; không suy rằng HTTP tạo đơn trước đó tự rollback.

### Chuyển trạng thái

`transition` chọn prefix endpoint theo vai trò. Trạng thái hủy dùng `/cancel`; các cập nhật khác dùng `/status` với chuỗi chuyển từ enum. Backend kiểm tra quyền và điều kiện chuyển tiếp; app không được chuyển một trạng thái bất kỳ chỉ vì enum có giá trị đó.

### Thanh toán

`pay` gọi API ghi nhận thu tiền theo vai trò cửa hàng/shipper rồi tải dữ liệu mới. Không có tích hợp thanh toán online ở hàm này. `paidAt != null` là điều kiện app dùng để biết đã ghi nhận thanh toán.

## 10. GPS, địa chỉ và bản đồ là ba việc khác nhau

- `LocationService.current()` xin quyền và lấy vị trí từ Android; có thể lỗi nếu GPS tắt, quyền bị từ chối hoặc quá thời gian.
- `GeocodingService.reverse()` gửi tọa độ tới Nominatim để gợi ý địa chỉ. Có debounce, cache và hàng đợi theo tiến trình; không phải nguồn xác thực tọa độ thực của thiết bị.
- Các widget `FlutterMap` vẽ tile và marker. Tải được bản đồ không chứng minh đã xin quyền GPS; ngược lại, GPS có thể có kết quả dù tile chưa tải.
- Phí/km/tuyến giao chính thức được backend trả từ dịch vụ đường bộ; không tin khoảng cách UI tự nhập.

Giữ phần xử lý GPS/mạng trong service và trạng thái, thay vì nhét toàn bộ vào `build()`. Flutter có thể gọi `build()` nhiều lần; tạo request mới mỗi lần build có thể gây gọi lặp và giao diện giật.

## 11. Những chỗ cần dọn khi đóng app/widget

`AppState.dispose()` hủy timer, tăng số lần tải gần khách và đóng HTTP client. Các trang có `TextEditingController`, `MapController`, timer hoặc service sở hữu client cần dispose theo source. Nếu widget bị gỡ, không gọi setState tùy tiện sau await; kiểm tra `mounted` ở chỗ UI.

Với HTTP client được truyền từ ngoài vào một service, đọc biến như `_ownsClient`: service không nên đóng tài nguyên mà bên khác vẫn sở hữu. Test dùng cách truyền client để thay server bằng phản hồi có kiểm soát.

## 12. Cách tự kiểm tra mình đã hiểu

Thử trả lời trước khi sửa:

1. `cart` lưu giá hay số lượng? Vì sao backend tính lại giá?
2. Khi đổi cửa hàng, dòng nào xóa catalog và giỏ cũ?
3. Vì sao `loadProducts` so revision sau await?
4. `notifyListeners` có ghi MySQL không?
5. Tại sao không nhét một request vào `build()`?
6. `as String` khác `toString()` ở đâu?
7. Xóa file facade export cũ sẽ ảnh hưởng những import nào?
8. Nếu backend trả 409 khi checkout, giỏ có bị xóa ngay không?
9. Token nhà cung cấp Google/Facebook có phải JWT phiên C-Store không?
10. Test widget với MockClient đã chứng minh GPS trên điện thoại thật chưa?

Nếu trả lời được và lần tới đúng hàm trong bản đồ source, bạn đã có cách đọc dự án theo luồng, thay vì chỉ nhìn từng dòng rời rạc.
