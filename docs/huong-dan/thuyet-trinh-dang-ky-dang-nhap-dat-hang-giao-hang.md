# Hiểu và thuyết trình code đăng ký, đăng nhập, đặt hàng, giao hàng C-Store

Tài liệu này giải thích từ đầu cho người chưa quen đọc dự án có cả Flutter và Spring Boot. Bạn nên đọc phần ví dụ trước, rồi mở các file được dẫn để đối chiếu. Không cần học thuộc tất cả tên class ngay lần đầu.

Nội dung được đối chiếu mã nguồn ngày 05/11/2026. Đây là tài liệu giải thích source, không phải báo cáo chạy thử ứng dụng. Các sản phẩm, giá tiền và mã đơn trong ví dụ là dữ liệu minh họa.

## Cách dùng tài liệu

- Muốn hiểu ứng dụng làm gì: đọc phần 1–3.
- Muốn hiểu bốn chức năng và code tương ứng: đọc phần 4–7.
- Muốn mở file để thuyết trình: dùng phần 8–9.
- Muốn chuẩn bị câu hỏi của giảng viên: đọc phần 10–11.
- Muốn có bài nói mẫu: dùng phần 12.

## 1. Trước tiên, hiểu một câu chuyện mua hàng

Hãy tưởng tượng có ba người:

- **Lan là khách hàng:** muốn mua hàng và nhận tại nhà.
- **Nhân viên cửa hàng:** kiểm tra, chấp nhận đơn và chuẩn bị hàng.
- **Minh là shipper:** nhận đơn, đến cửa hàng lấy hàng rồi giao cho Lan.

Toàn bộ quá trình diễn ra như sau:

```text
Lan chưa có tài khoản
    ↓
Lan đăng ký tài khoản khách hàng
    ↓
Ứng dụng tự đăng nhập sau khi đăng ký thành công
    ↓
Lan chọn vị trí giao, chọn chi nhánh, thêm sản phẩm vào giỏ
    ↓
Lan kiểm tra người nhận, số điện thoại, địa chỉ, phí giao
    ↓
Lan xác nhận đặt hàng COD
    ↓
Cửa hàng nhận được đơn đang chờ và bấm chấp nhận
    ↓
Minh đang trực tuyến, đủ điều kiện nên thấy đề nghị nhận đơn
    ↓
Minh bấm nhận giao, đến cửa hàng lấy hàng
    ↓
Minh bắt đầu giao đến Lan
    ↓
Minh thu tiền, xác nhận đã thu COD và xác nhận giao xong
```

Đây là một luồng thành công. Nếu cửa hàng từ chối hoặc khách hủy đúng lúc được phép thì đơn kết thúc theo nhánh khác.

**Điều cần nhớ:** đăng ký tạo tài khoản; đăng nhập xác định người đang dùng; đặt hàng tạo yêu cầu mua; giao hàng xử lý yêu cầu đó đến khi hoàn tất.

## 2. Dự án gồm những phần nào?

### 2.1. Flutter là phần người dùng nhìn thấy

Thư mục: `mobile/lib/`.

Flutter tạo các màn hình, ô nhập, nút bấm, giỏ hàng và bản đồ. Nó nhận thao tác của người dùng rồi gửi yêu cầu đến backend.

Ví dụ: Lan bấm nút “Xác nhận đặt hàng COD”. Flutter lấy thông tin trong form và giỏ hàng để gửi đi.

Bạn có thể gọi Flutter là **phần giao diện**, hoặc frontend.

### 2.2. Spring Boot là phần xử lý phía máy chủ

Thư mục: `backend/src/main/java/com/cstore/app/`.

Backend trả lời những câu hỏi như:

- Email này đã được đăng ký chưa?
- Mật khẩu có đúng không?
- Người này có quyền đặt hàng không?
- Sản phẩm còn đủ số lượng không?
- Đơn đã có shipper khác nhận chưa?
- Đơn đã thu tiền trước khi hoàn tất chưa?

Các quyết định nghiệp vụ cuối cùng nằm ở backend. Giao diện có thể kiểm tra trước để người dùng sửa nhanh, nhưng backend vẫn kiểm tra lại.

### 2.3. MySQL là nơi lưu dữ liệu lâu dài

Database lưu tài khoản, sản phẩm, đơn hàng và các thông tin liên quan.

Ví dụ: Lan đóng ứng dụng rồi mở lại, đơn đã tạo vẫn còn trong database. Tuy nhiên, phiên đăng nhập của app hiện chỉ giữ trong RAM nên không có cơ chế tự đăng nhập lại sau khi khởi động lại app.

### 2.4. Ba phần nói chuyện với nhau như thế nào?

```text
Người dùng bấm nút
    ↓
Flutter thu thập và kiểm tra dữ liệu
    ↓ gửi yêu cầu HTTP đến API
Spring Boot kiểm tra quyền và xử lý nghiệp vụ
    ↓ đọc hoặc ghi
MySQL
    ↓ kết quả được backend chuyển thành JSON
Flutter nhận dữ liệu và cập nhật màn hình
```

**API** là điểm giao tiếp mà Flutter gọi để yêu cầu backend làm một việc.

Ví dụ `POST /api/customer/orders` có nghĩa là “gửi yêu cầu tạo đơn hàng khách hàng”.

**JSON** là cách đóng gói dữ liệu dưới dạng tên trường và giá trị, để Flutter và Java trao đổi với nhau.

## 3. Một số từ cần biết trước khi đọc code

| Từ trong code | Hiểu đơn giản | Ví dụ trong dự án |
| --- | --- | --- |
| `screen`, `page` | Màn hình | `CheckoutPage` là màn xác nhận đặt hàng |
| `submit()` | Hàm xử lý lúc gửi form | Đọc dữ liệu khi bấm đăng nhập hoặc đặt hàng |
| `AppState` | Nơi giữ dữ liệu hiện tại của app và cung cấp thao tác cho giao diện | Tài khoản, giỏ hàng, danh sách đơn |
| `Controller` | Nơi backend tiếp nhận một API cụ thể | `AuthController` nhận yêu cầu đăng nhập |
| `Service` | Nhóm hàm xử lý một mảng công việc | `DeliveryService` tính phí giao |
| `Repository` | Thành phần truy vấn database | `Users`, `Products`, `Orders` |
| `Entity` | Đối tượng Java được ánh xạ để lưu database | `AppUser`, `CustomerOrder` |
| `DTO` | Cấu trúc dữ liệu nhận hoặc trả qua API | `OrderInput`, `OrderView` |
| `role` | Vai trò của tài khoản | Khách, cửa hàng, shipper, admin |
| `stock` | Số lượng sản phẩm còn trong kho | Còn 10 hộp sữa |
| `status` | Trạng thái xử lý đơn | Chờ xác nhận, đang giao |
| `COD` | Thanh toán khi nhận hàng | Shipper thu tiền từ khách |
| `JWT` | Thông tin xác nhận phiên đăng nhập do backend ký và cấp | Dùng khi gọi API cần đăng nhập |
| `transaction` | Một nhóm thay đổi dữ liệu được thực hiện cùng nhau | Tạo đơn và trừ kho |

Một số ký hiệu thường gặp:

```dart
await widget.state.login(email.text, password.text);
```

- `email.text`: lấy nội dung trong ô email.
- `password.text`: lấy nội dung trong ô mật khẩu.
- `widget.state.login(...)`: gọi thao tác đăng nhập qua AppState được truyền vào màn hình.
- `await`: chờ thao tác bất đồng bộ hoàn thành trước khi chạy tiếp đoạn phụ thuộc vào kết quả đó. Trong lúc chờ mạng, ứng dụng vẫn có thể hiển thị trạng thái đang xử lý.

```java
@PostMapping("/auth/login")
```

Kết hợp với `@RequestMapping("/api")` của controller, annotation này nối yêu cầu `POST /api/auth/login` với hàm Java ở bên dưới.

```java
@Valid @RequestBody Login input
```

- `@RequestBody`: đọc dữ liệu JSON của yêu cầu vào đối tượng Java.
- `@Valid`: kiểm tra các ràng buộc khai báo trong DTO, chẳng hạn trường không được trống.
- `input`: biến chứa thông tin người dùng gửi lên.

## 4. Chức năng đăng ký — giải thích từ thao tác đến database

### 4.1. Đăng ký để làm gì?

Đăng ký tạo ra một tài khoản mới. Sau đó hệ thống có thể biết đơn hàng thuộc khách nào hoặc shipper nào đang nhận giao.

Trong màn đăng ký công khai hiện tại, người dùng được chọn:

- `CUSTOMER`: khách hàng.
- `SHIPPER`: người giao hàng.

Backend không cho tự đăng ký vai trò cửa hàng hoặc admin qua API đăng ký công khai.

### 4.2. Người dùng nhập những gì?

Người dùng nhập họ tên, email, mật khẩu và chọn vai trò.

Màn hình nằm tại [welcome.dart](../../mobile/lib/screens/auth/welcome.dart), class `LoginPage`. Một màn hình được dùng cho cả đăng nhập và đăng ký.

Biến sau quyết định màn hình đang ở chế độ nào:

```dart
bool busy = false, hidden = true, registering = false;
```

- `registering == true`: đang đăng ký.
- `registering == false`: đang đăng nhập.
- `hidden`: quyết định mật khẩu có đang bị che trên giao diện không.
- `busy`: cho biết yêu cầu đang xử lý để tránh bấm nút lặp ngay trong màn hình.

### 4.3. Khi bấm “Tạo tài khoản”, hàm nào chạy?

Hàm `submit()` chạy. Đoạn quan trọng:

```dart
if (busy) return;
if (!form.currentState!.validate()) return;
```

Đọc từng câu như sau:

1. Nếu đang xử lý một lần bấm trước đó thì dừng lần bấm mới.
2. Kiểm tra các ô nhập trong form.
3. Nếu có dữ liệu không hợp lệ thì dừng và để người dùng sửa.

Sau đó, phần phân nhánh:

```dart
if (registering) {
  await widget.state.register(name.text, email.text, password.text, role);
} else {
  await widget.state.login(email.text, password.text);
}
```

Đang ở chế độ đăng ký thì gọi `register()`. Đang ở chế độ đăng nhập thì gọi `login()`.

### 4.4. AppState làm gì với yêu cầu đăng ký?

[services/state/app_state.dart](../../mobile/lib/services/state/app_state.dart) cung cấp hàm `register()`, sau đó chuyển việc xử lý cho `_SessionActions.register()` trong [session_actions.dart](../../mobile/lib/services/state/session_actions.dart).

Chuỗi gọi là:

```text
LoginPage.submit()
    ↓
AppState.register(...)
    ↓
_SessionActions.register(...)
    ↓
app.api.request('/auth/register', body: ...)
    ↓
POST /api/auth/register
```

Trong dữ liệu gửi đi:

- `fullName`: họ tên.
- `email`: email đã bỏ khoảng trắng đầu và cuối.
- `password`: thông tin mật khẩu người dùng vừa nhập.
- `role`: vai trò được chuyển sang tên viết hoa như `CUSTOMER`.

Tên đường dẫn trong Flutter là `/auth/register`, nhưng API thực tế có thêm `/api`. Lớp `ApiClient` ghép tiền tố đó khi tạo URL.

### 4.5. Backend kiểm tra và lưu như thế nào?

Mở [AuthController.java](../../backend/src/main/java/com/cstore/app/controller/AuthController.java), tìm `register()`.

Backend thực hiện các bước:

1. Kiểm tra DTO: email hợp lệ, họ tên không trống, mật khẩu từ 8–72 ký tự.
2. Chỉ chấp nhận vai trò khách hoặc shipper.
3. Tìm email trong database, không phân biệt chữ hoa/thường.
4. Nếu email đã tồn tại, trả lỗi.
5. Chuẩn hóa email: bỏ khoảng trắng hai đầu, chuyển thành chữ thường.
6. Băm mật khẩu.
7. Lưu `AppUser` mới bằng `users.save(...)`.
8. Trả thông tin tài khoản vừa tạo với HTTP `201 Created`.

Phần băm mật khẩu:

```java
passwords.encode(input.password())
```

`passwords` sử dụng BCrypt theo cấu hình trong [SecurityConfig.java](../../backend/src/main/java/com/cstore/app/config/SecurityConfig.java).

**Băm mật khẩu nghĩa là gì?** Hệ thống tạo một giá trị băm từ mật khẩu để lưu. Khi cần kiểm tra đăng nhập, nó dùng hàm kiểm tra phù hợp với BCrypt. Bạn nên dùng từ “băm mật khẩu”, tránh giải thích rằng hệ thống giải mã mật khẩu đã lưu để so sánh.

Tài khoản được lưu thông qua entity [AppUser.java](../../backend/src/main/java/com/cstore/app/entity/AppUser.java), ánh xạ đến bảng `app_users`.

### 4.6. Vì sao đăng ký xong đã vào được ứng dụng?

Trong `_SessionActions.register()`, sau khi API đăng ký thành công, có đoạn:

```dart
await app.login(
  email,
  password,
);
```

Nghĩa là Flutter thực hiện thêm một yêu cầu đăng nhập.

**Phải phân biệt:** API đăng ký tạo tài khoản; API đăng nhập cấp phiên. Giao diện nối hai bước lại để người dùng sử dụng thuận tiện.

### 4.7. Câu nói mẫu khi mở code đăng ký

> “Đây là hàm submit của màn đăng ký. Hàm kiểm tra form rồi gọi AppState.register. AppState gửi thông tin đến API đăng ký. Ở backend, AuthController kiểm tra vai trò, email trùng và các ràng buộc dữ liệu. Nếu hợp lệ, mật khẩu được băm bằng BCrypt và tài khoản được lưu vào bảng app_users. Flutter tiếp tục gọi đăng nhập để đưa người dùng vào ứng dụng.”

## 5. Chức năng đăng nhập — hiểu tài khoản, JWT và phân quyền

### 5.1. Đăng nhập khác đăng ký ở đâu?

Đăng ký tạo bản ghi tài khoản mới. Đăng nhập kiểm tra một tài khoản đã tồn tại và cấp quyền sử dụng theo phiên.

Ví dụ: Lan đã đăng ký hôm qua. Hôm nay Lan mở lại app và đăng nhập bằng tài khoản cũ, không tạo thêm tài khoản mới.

### 5.2. Luồng gọi hàm đầy đủ

```text
LoginPage.submit()
    ↓
AppState.login(email, password)
    ↓
_SessionActions.login(...)
    ↓
AccountApi.login(...)
    ↓
ApiClient.request('/auth/login', body: ...)
    ↓
POST /api/auth/login
    ↓
AuthController.login(...)
    ↓
AccountService.session(user)
    ↓
Trả JWT và thông tin tài khoản
```

Hai file Flutter cần xem:

- [session_actions.dart](../../mobile/lib/services/state/session_actions.dart): cập nhật phiên và nạp dữ liệu.
- [api/account_api.dart](../../mobile/lib/services/api/account_api.dart): gọi API đăng nhập và đọc kết quả.

Lưu ý: `mobile/lib/services/account_api.dart` là file export. Phần triển khai nằm trong thư mục `services/api/`.

### 5.3. Backend kiểm tra thông tin đăng nhập

Mở `AuthController.login()`:

1. Tìm người dùng bằng email đã bỏ khoảng trắng hai đầu, không phân biệt hoa/thường.
2. Nếu không có tài khoản, trả lỗi đăng nhập.
3. Nếu tài khoản không có mật khẩu đăng nhập hợp lệ hoặc mật khẩu không khớp, trả lỗi.
4. Nếu mật khẩu khớp, gọi `accounts.session(user)`.

Dòng kiểm tra mật khẩu:

```java
passwords.matches(input.password(), user.passwordHash)
```

- `input.password()`: mật khẩu người dùng vừa nhập.
- `user.passwordHash`: giá trị băm đang lưu trong database.
- Kết quả đúng/sai cho biết mật khẩu có khớp không.

Sau đó `AccountService.session()` kiểm tra thêm tài khoản bị khóa/xóa và trường hợp tài khoản cửa hàng gắn với chi nhánh đã ngừng hoạt động.

### 5.4. JWT dùng để làm gì?

Hãy hình dung JWT là một thẻ xác nhận được backend cấp sau khi đăng nhập thành công.

Lan dùng thẻ đó khi gửi các yêu cầu cần xác định tài khoản, chẳng hạn tạo đơn hoặc xem đơn của mình. Backend kiểm tra thẻ trước khi cho xử lý.

Trong dự án, JWT có:

- Chủ thể là email tài khoản.
- Thời điểm phát hành và hết hạn.
- Vai trò tài khoản.
- Trường phiên bản `ver`, phục vụ kiểm tra hiệu lực sau thay đổi liên quan đến phiên, chẳng hạn đổi mật khẩu.

Thời hạn được đặt bằng:

```java
.expiresAt(now.plusSeconds(28800))
```

`28.800 giây = 8 giờ`.

Trong [api_client.dart](../../mobile/lib/services/api/api_client.dart), các yêu cầu có phiên sẽ gắn JWT vào header `Authorization` theo dạng Bearer.

Backend dùng Spring Security để kiểm tra token: chữ ký, hạn sử dụng và trạng thái/phiên bản tài khoản theo cấu hình hiện có.

### 5.5. Flutter nhận kết quả rồi làm gì?

Trong `AccountApi._session()`:

1. Đọc phần `user` để tạo đối tượng `Account`.
2. Giữ token trong đối tượng API.
3. Trả tài khoản về `_SessionActions.login()`.

Tiếp theo:

```dart
app.account = await app.api.login(
  email.trim(),
  password,
);
await app._loadSession();
```

`app.account` cho app biết hiện đang đăng nhập bằng tài khoản nào. `_loadSession()` tải dữ liệu khởi đầu phù hợp với phiên, ví dụ chi nhánh, vị trí giao đã lưu và danh sách đơn theo vai trò.

### 5.6. Vì sao mỗi người vào một màn hình khác nhau?

Mở [role_home.dart](../../mobile/lib/app/role_home.dart):

```dart
return switch (account.role) {
  Role.customer => CustomerHome(state: state),
  Role.store => StoreHome(state: state),
  Role.shipper => ShipperHome(state: state),
  Role.admin => AdminHome(state: state),
};
```

Đọc như sau:

- Vai trò khách → màn mua hàng.
- Vai trò cửa hàng → màn quản lý cửa hàng.
- Vai trò shipper → màn nhận và giao đơn.
- Vai trò admin → màn quản trị.

Vai trò ở đây được đọc từ thông tin tài khoản do backend trả về sau đăng nhập.

**Điều hướng và phân quyền là hai việc khác nhau.** `RoleHome` chọn màn hình cho người dùng; Spring Security và các kiểm tra trong backend quyết định người đó có được gọi API và thao tác trên bản ghi cụ thể hay không.

Ví dụ: khách không được gọi API nhận đơn của shipper; một shipper không được cập nhật đơn thuộc shipper khác.

### 5.7. Đăng xuất làm gì?

`_SessionActions.logout()` xóa token và tài khoản đang giữ trong app, dừng bộ hẹn giờ tải dữ liệu, xóa giỏ hàng, danh sách đơn và các dữ liệu phiên liên quan.

Khi `account == null`, `RoleHome` hiển thị lại màn đăng nhập.

JWT hiện chỉ được giữ trong RAM. Dự án chưa có refresh token và cơ chế lưu phiên để tự đăng nhập lại sau khi khởi động lại app. Xóa token trong app khi đăng xuất cũng không đồng nghĩa backend thu hồi ngay mọi bản sao của token đó.

### 5.8. Câu nói mẫu khi mở code đăng nhập

> “Khi người dùng đăng nhập, Flutter gửi email và mật khẩu đến AuthController. Backend tìm tài khoản, kiểm tra mật khẩu bằng BCrypt và kiểm tra trạng thái tài khoản. Nếu hợp lệ, AccountService tạo JWT thời hạn 8 giờ và trả thông tin tài khoản. Flutter lưu phiên trong RAM, nạp dữ liệu và chọn màn hình dựa vào vai trò. Những API tiếp theo gửi kèm JWT để backend xác thực và kiểm tra quyền.”

## 6. Chức năng đặt hàng — từ giỏ hàng đến đơn lưu trong database

### 6.1. Phân biệt giỏ hàng và đơn hàng

**Giỏ hàng** là danh sách khách đang chọn, còn có thể tăng giảm số lượng. Trong dự án này, giỏ hiện tại được giữ trong AppState của Flutter.

**Đơn hàng** được tạo khi backend xử lý thành công yêu cầu xác nhận đặt hàng và lưu dữ liệu vào database.

Vì vậy, thêm sản phẩm vào giỏ chưa có nghĩa là cửa hàng đã nhận một đơn, cũng chưa có nghĩa kho đã được giữ cho khách đó.

### 6.2. Giỏ hàng được biểu diễn trong code ra sao?

Trong AppState:

```dart
final cart = <int, int>{};
```

Đây là một map, gồm các cặp “mã sản phẩm → số lượng”.

Ví dụ minh họa:

```text
cart = {
  12: 2,
  25: 1
}
```

Nghĩa là khách chọn 2 sản phẩm mã 12 và 1 sản phẩm mã 25.

Hàm `_CartOrderActions.change()` trong [cart_order_actions.dart](../../mobile/lib/services/state/cart_order_actions.dart) xử lý tăng/giảm số lượng:

- Chỉ thao tác với sản phẩm thuộc chi nhánh đang chọn và còn bán.
- Số lượng trên giao diện không vượt tồn kho app đang biết.
- Nếu số lượng về 0 hoặc thấp hơn thì bỏ sản phẩm khỏi giỏ.
- Sau khi thay đổi, báo giao diện cập nhật.

Khi đổi chi nhánh bằng `_CatalogActions.select()`, app xóa giỏ hiện tại. Luồng này tổ chức một đơn theo một chi nhánh.

### 6.3. Trước khi gửi đơn, khách cần làm gì?

Mở [checkout_page.dart](../../mobile/lib/screens/customer/checkout_page.dart), class `CheckoutPage`.

Khách kiểm tra:

- Tên người nhận.
- Số điện thoại.
- Địa chỉ.
- Điểm giao đã xác nhận trên bản đồ.
- Tiền hàng, phí giao và tổng thanh toán.

Tọa độ `latitude` và `longitude` là vị trí của điểm giao, giúp backend tính tuyến đường từ chi nhánh tới khách.

`pinConfirmed` thể hiện điểm giao đã được xác nhận trong luồng ứng dụng. Đây không phải bằng chứng độc lập rằng người dùng đang đứng đúng tại điểm đó.

### 6.4. Báo giá trước khi đặt hàng hoạt động ra sao?

Hàm `loadQuote()` của `CheckoutPage` gọi:

```text
AppState.quoteDelivery(...)
    ↓
_DeliveryLocationActions.quoteDelivery(...)
    ↓
POST /api/customer/delivery-quote
    ↓
CustomerController.deliveryQuote(...)
    ↓
DeliveryService.quote(...)
```

Backend trả về khoảng cách, thời gian di chuyển ước tính và phí giao. App dùng kết quả đó để hiển thị cho khách trước khi xác nhận.

Trong `CheckoutPage.submit()`, nếu chưa xác nhận ghim hoặc chưa có báo giá thì app chưa gửi đơn.

**Báo giá chưa tạo đơn và chưa trừ tồn kho.** Backend còn tính lại báo giá khi xử lý yêu cầu tạo đơn.

### 6.5. Cách tính phạm vi và phí giao

Mở [DeliveryService.java](../../backend/src/main/java/com/cstore/app/service/DeliveryService.java), hàm `quote()`.

Backend kiểm tra tọa độ và chi nhánh, sau đó:

1. Dùng khoảng cách thẳng Haversine để sàng lọc nhanh.
2. Gọi dịch vụ định tuyến OSRM qua `RoutingService` để lấy quãng đường bộ giữa chi nhánh và điểm giao.
3. Chỉ chấp nhận quãng đường giao từ chi nhánh đến khách không quá 10 km.
4. Tính phí dựa trên quãng đường bộ.

Công thức trong source:

```java
BigDecimal.valueOf(15000 + (long) Math.ceil(route.distanceKm() * 3000))
```

Đọc dễ hiểu:

```text
Phí giao = 15.000 đồng + làm tròn lên(khoảng cách km × 3.000 đồng)
```

Ví dụ quãng đường là 3 km:

```text
Phí giao = 15.000 + 3 × 3.000 = 24.000 đồng
```

Lưu ý: code làm tròn lên số tiền của phần `km × 3.000`, không làm tròn quãng đường lên số km nguyên trước khi nhân.

Thời gian trả về là ước tính di chuyển của tuyến đường, không phải cam kết tổng thời gian khách sẽ nhận hàng vì còn bước chuẩn bị và chờ shipper.

### 6.6. Khi bấm xác nhận, app gửi những gì?

Trong `_CartOrderActions.checkout()`, app gọi `POST /api/customer/orders`.

Ví dụ cấu trúc yêu cầu, với dữ liệu minh họa:

```json
{
  "storeId": 7,
  "recipient": "Lan",
  "phone": "0900000000",
  "address": "Địa chỉ giao hàng minh họa",
  "latitude": 10.77,
  "longitude": 106.69,
  "pinConfirmed": true,
  "items": [
    {"productId": 12, "quantity": 2},
    {"productId": 25, "quantity": 1}
  ]
}
```

Các tọa độ và số điện thoại trên chỉ minh họa hình dạng dữ liệu, không dùng để liên hệ hay khẳng định nằm trong phạm vi của một chi nhánh thực tế.

Bạn cần chú ý: yêu cầu không gửi giá sản phẩm hoặc tổng thanh toán để backend tin và lưu trực tiếp. Backend tự đọc giá từ database và tính tiền.

### 6.7. Backend tạo đơn theo những bước nào?

Mở [OrderController.java](../../backend/src/main/java/com/cstore/app/controller/OrderController.java), hàm `checkout()`.

**Bước 1 — Kiểm tra dữ liệu đầu vào và quyền.**

API thuộc nhóm khách hàng nên cần phiên có quyền khách. DTO `OrderInput` yêu cầu giỏ có sản phẩm, số lượng ít nhất 1, có người nhận/địa chỉ, số điện thoại 10 chữ số bắt đầu bằng 0, tọa độ trong khoảng hợp lệ và `pinConfirmed == true`.

**Bước 2 — Tìm chi nhánh.**

Chi nhánh phải tồn tại, còn hoạt động và có tọa độ.

**Bước 3 — Tính lại tuyến đường và phí.**

Backend gọi `delivery.quote(...)`. Nếu ngoài phạm vi hoặc không lấy được tuyến cần thiết thì yêu cầu không được tiếp tục như một đơn thành công.

**Bước 4 — Xác định khách hàng.**

```java
var buyer = support.current(authentication);
```

Khách được xác định từ phiên đã xác thực. App không được tự gửi một `customerId` bất kỳ để đặt thay người khác.

**Bước 5 — Tạo đối tượng đơn và gắn thông tin giao.**

```java
var order = new CustomerOrder(buyer, store);
```

Backend gắn người nhận, số điện thoại, địa chỉ, tọa độ, quãng đường và phí giao vào đơn.

**Bước 6 — Kiểm tra từng sản phẩm.**

Với mỗi dòng hàng, backend kiểm tra:

- Mã sản phẩm không bị lặp trong yêu cầu.
- Sản phẩm tồn tại.
- Thuộc đúng chi nhánh.
- Đang bán.
- Còn đủ số lượng.

**Bước 7 — Trừ kho, lưu dòng hàng và cộng tiền.**

```java
product.stock -= item.quantity();
order.lines.add(new OrderLine(order, product, item.quantity(), product.price));
order.total = order.total.add(product.price.multiply(BigDecimal.valueOf(item.quantity())));
```

Giải thích:

- Dòng 1: giảm tồn kho theo số lượng khách đặt.
- Dòng 2: tạo dòng sản phẩm của đơn, ghi nhận giá đang có ở backend.
- Dòng 3: cộng `giá × số lượng` vào tiền hàng.

**Bước 8 — Lưu đơn chờ xác nhận.**

`CustomerOrder` khởi tạo trạng thái `PENDING`. Controller thêm sự kiện `PENDING` vào lịch sử và gọi `orders.save(order)` để lưu.

### 6.8. Ví dụ tính toán đầy đủ

Giả sử giỏ của Lan có:

| Sản phẩm | Đơn giá | Số lượng | Thành tiền |
| --- | ---: | ---: | ---: |
| Sữa | 20.000đ | 2 | 40.000đ |
| Bánh | 15.000đ | 1 | 15.000đ |
| Tiền hàng | | | 55.000đ |

Quãng đường giao là 3 km, phí giao 24.000đ:

```text
Tổng thanh toán = 55.000 + 24.000 = 79.000 đồng
```

Nếu kho sữa ban đầu có 10 hộp thì sau khi đơn được tạo thành công còn 8 hộp.

Tên trường cần đọc cẩn thận: `CustomerOrder.total` trong entity đang tích lũy tiền hàng. Khi chuyển thành dữ liệu trả API ở `CommerceViews.view()`, trường `subtotal` nhận tiền hàng đó, còn trường `total` của response nhận tiền hàng cộng phí giao.

### 6.9. Vì sao cần transaction và khóa sản phẩm?

Tình huống 1: đơn có sữa và bánh. Backend vừa trừ kho sữa thì phát hiện bánh hết hàng.

Nếu lưu rời từng bước, có thể xảy ra việc đơn không tạo được nhưng kho sữa đã bị giảm. `@Transactional` giúp các thay đổi database trong lần xử lý này đi cùng nhau: thành công thì ghi nhận; lỗi làm giao dịch thất bại thì hoàn tác.

Tình huống 2: chỉ còn 1 hộp sữa, hai khách cùng xác nhận đặt.

`products.locked(...)` dùng khóa ghi trên bản ghi sản phẩm. Một giao dịch phải chờ giao dịch đang giữ khóa hoàn tất, rồi kiểm tra tồn kho thực tế. Nhờ đó hai yêu cầu không cùng bán vượt phần tồn còn lại.

Source còn sắp xếp các sản phẩm theo ID trước khi khóa để giảm nguy cơ các giao dịch chờ khóa chéo nhau.

`busy` ở Flutter giúp hạn chế bấm lặp trên giao diện. Nó không phải cơ chế bảo đảm mọi yêu cầu tạo đơn bị gửi lại qua mạng đều được nhận diện là cùng một đơn.

### 6.10. Vì sao giá lịch sử đơn được giữ lại?

[OrderLine.java](../../backend/src/main/java/com/cstore/app/entity/OrderLine.java) lưu số lượng, đơn giá và bản chụp tên/ảnh sản phẩm lúc đặt.

Ví dụ hôm nay Lan mua sữa giá 20.000đ. Ngày mai cửa hàng sửa giá thành 22.000đ thì đơn đã đặt vẫn có đơn giá 20.000đ trên dòng hàng.

### 6.11. App làm gì sau khi đặt thành công?

`_CartOrderActions.checkout()` đọc đơn backend trả về, xóa giỏ và tải lại dữ liệu. `CheckoutPage.submit()` chuyển sang màn chi tiết đơn.

**Đặt thành công có nghĩa là đã tạo đơn chờ xử lý.** Đơn vẫn cần cửa hàng chấp nhận và shipper thực hiện các bước giao.

### 6.12. Câu nói mẫu khi mở code đặt hàng

> “Đây là luồng tạo đơn hàng. Khách chọn sản phẩm, nhập thông tin người nhận và xác nhận điểm giao. App lấy báo giá rồi gửi mã sản phẩm và số lượng đến backend. OrderController kiểm tra chi nhánh, địa chỉ, sản phẩm và tồn kho; đồng thời tự lấy giá từ database để tính tiền. Sau đó backend trừ kho, lưu các dòng hàng và tạo đơn PENDING trong cùng một transaction. App nhận kết quả, xóa giỏ và mở chi tiết đơn.”

## 7. Chức năng giao hàng — từ cửa hàng chấp nhận đến giao thành công

### 7.1. Vì sao đơn cần nhiều trạng thái?

Một đơn hàng đi qua nhiều người và nhiều công việc. Trạng thái giúp biết ai đang xử lý và bước tiếp theo được phép làm là gì.

Luồng thành công:

```text
PENDING → ACCEPTED → ASSIGNED → PICKED_UP → DELIVERING → DELIVERED
```

| Trạng thái lưu trong backend | Hiểu bằng tiếng Việt | Thao tác đưa đơn đến trạng thái này |
| --- | --- | --- |
| `PENDING` | Chờ cửa hàng xác nhận | Khách đặt thành công |
| `ACCEPTED` | Cửa hàng đã chấp nhận, chờ shipper | Cửa hàng chấp nhận |
| `ASSIGNED` | Một shipper đã nhận giao | Shipper nhận đơn |
| `PICKED_UP` | Shipper đã lấy hàng | Shipper xác nhận lấy hàng |
| `DELIVERING` | Shipper đang giao đến khách | Shipper bấm bắt đầu giao |
| `DELIVERED` | Đã giao thành công | Shipper xác nhận hoàn tất khi đủ điều kiện |
| `REJECTED` | Cửa hàng từ chối | Cửa hàng từ chối đơn đang chờ và ghi lý do |
| `CANCELLED` | Khách đã hủy | Khách hủy đơn đang chờ |

Các tên hiển thị của Flutter được ánh xạ trong [order_status.dart](../../mobile/lib/models/order_status.dart).

### 7.2. Cửa hàng chấp nhận đơn như thế nào?

Cửa hàng tải danh sách đơn bằng `GET /api/merchant/orders`.

Tên `merchant` trong URL là tên API đang dùng cho nhóm chức năng cửa hàng.

Khi nhân viên bấm chấp nhận:

```text
OrderDetail.actions(...)
    ↓
AppState.transition(..., OrderStatus.accepted, Role.store)
    ↓
_CartOrderActions.transition(...)
    ↓
PUT /api/merchant/orders/{id}/status
    ↓
OrderController.storeStatus(...)
```

Backend khóa đơn, kiểm tra đơn thuộc đúng chi nhánh của người thao tác và còn `PENDING`, rồi mới cho chuyển sang `ACCEPTED`.

### 7.3. Khách hủy hoặc cửa hàng từ chối thì sao?

Khách chỉ được hủy đơn của chính mình khi còn `PENDING`.

Cửa hàng chỉ được từ chối đơn thuộc chi nhánh của mình khi còn `PENDING`, đồng thời cần lý do.

Cả hai trường hợp đều gọi thao tác hoàn tồn trong `CommerceSupport.restore()`.

Ví dụ kho sữa giảm từ 10 xuống 8 khi Lan đặt 2 hộp. Nếu Lan hủy đúng lúc thì hệ thống cộng lại 2, kho trở về 10, với giả định không có giao dịch khác xen vào làm thay đổi kho.

Sau khi đơn đã được chấp nhận, luồng hủy của khách hiện tại không cho phép tiếp tục hủy.

### 7.4. Shipper cần làm gì trước khi nhận đơn?

Shipper cần có ảnh đại diện, bật trực tuyến và cập nhật vị trí.

Flutter gọi `_ShipperActions.setShipperPosition()` trong [shipper_actions.dart](../../mobile/lib/services/state/shipper_actions.dart), gửi:

```text
PUT /api/shipper/location
```

Thông tin gồm trạng thái online và tọa độ. Backend cũng kiểm tra yêu cầu ảnh đại diện khi bật trực tuyến.

### 7.5. Hệ thống chọn các đề nghị đơn cho shipper như thế nào?

Mở [ShipperController.java](../../backend/src/main/java/com/cstore/app/controller/ShipperController.java), hàm `offers()`.

Backend lấy các đơn:

- Đã được cửa hàng chấp nhận: `ACCEPTED`.
- Chưa gắn shipper.
- Chi nhánh còn hoạt động và có vị trí.
- Shipper đang online, có vị trí.
- Quãng đường từ shipper đến chi nhánh trong phạm vi 5 km, sau bước sàng lọc khoảng cách thẳng.

**Hai phạm vi khác nhau:** 10 km là từ cửa hàng đến khách khi báo phí giao; 5 km là từ shipper đến cửa hàng để đề nghị và nhận đơn.

Hệ thống hiển thị đề nghị phù hợp rồi shipper chủ động bấm nhận. Không nên mô tả rằng backend tự động gán đơn cho shipper gần nhất.

### 7.6. Khi shipper bấm “Nhận giao đơn này”

Flutter gọi:

```text
AppState.claim(order)
    ↓
_ShipperActions.claim(order)
    ↓
POST /api/shipper/orders/{id}/claim
    ↓
ShipperController.claim(...)
```

Backend kiểm tra lại các điều kiện nhận đơn, vì dữ liệu có thể đã đổi từ lúc danh sách đề nghị được tải.

Ví dụ Minh và một shipper khác cùng nhìn thấy một đơn. Người khác có thể nhận trước khi Minh bấm, nên không thể chỉ tin danh sách đang hiển thị trên màn hình.

Trong `claim()`, backend khóa bản ghi shipper và đơn, kiểm tra đơn chưa có người nhận và shipper chưa đủ 3 đơn thuộc nhóm `ASSIGNED`, `PICKED_UP`, `DELIVERING`.

Nếu hợp lệ:

```java
order.shipper = shipper;
support.setStatus(order, "ASSIGNED");
```

Dòng đầu gắn người giao. Dòng sau chuyển trạng thái và ghi lịch sử.

**Giới hạn 3 đơn** là số đơn đang thực hiện đồng thời, không phải shipper chỉ được giao tổng cộng 3 đơn trong ngày.

### 7.7. Đường đi trên bản đồ được lấy như thế nào?

API `GET /api/shipper/orders/{id}/route` do `navigation()` xử lý.

- Chưa lấy hàng: có tuyến đến chi nhánh lấy hàng và tuyến từ chi nhánh đến khách.
- Sau khi lấy hàng: tuyến giao có thể bắt đầu từ vị trí shipper hiện tại đến khách.

Các tuyến đường do `RoutingService` cung cấp. Thông tin bản đồ hỗ trợ shipper đi giao và giúp hiển thị khoảng cách/thời gian ước tính.

Không nên nói app tự chứng minh shipper đã tới nơi bằng GPS. Hàm chuyển trạng thái hiện tại chủ yếu kiểm tra người giao, thứ tự trạng thái và điều kiện thanh toán. Source có cả chức năng mô phỏng vị trí ở bước lấy hàng để phục vụ luồng mô phỏng.

### 7.8. Lấy hàng, bắt đầu giao và giao xong

Các nút thao tác nằm trong `actions()` của [order_detail_page.dart](../../mobile/lib/screens/orders/order_detail_page.dart).

Backend nhận yêu cầu qua `PUT /api/shipper/orders/{id}/status`, hàm `deliveryStatus()`.

Đoạn quyết định bước kế tiếp:

```java
String expected =
    switch (order.status) {
      case "ASSIGNED" -> "PICKED_UP";
      case "PICKED_UP" -> "DELIVERING";
      case "DELIVERING" -> "DELIVERED";
      default -> "";
    };
```

Đọc theo tình huống:

1. Minh vừa nhận đơn, trạng thái `ASSIGNED`. Minh chỉ được chuyển tiếp sang đã lấy hàng `PICKED_UP`.
2. Minh đã lấy hàng, trạng thái `PICKED_UP`. Bước tiếp là đang giao `DELIVERING`.
3. Minh đang giao, trạng thái `DELIVERING`. Bước tiếp là giao xong `DELIVERED`, với điều kiện đã xác nhận thu tiền.

Nếu cố chuyển thẳng từ vừa nhận đơn sang giao xong, backend trả lỗi chuyển trạng thái không đúng thứ tự.

Backend còn kiểm tra shipper thao tác chính là người được gắn với đơn.

### 7.9. Xác nhận thu COD khác xác nhận giao xong thế nào?

**Thu COD** là ghi nhận đã thu tiền. **Giao xong** là hoàn tất bước giao hàng. Trong code, đây là hai thao tác riêng.

Theo ví dụ trước, Lan cần trả 79.000đ. Khi đã nhận tiền, Minh thao tác xác nhận thu COD:

```text
AppState.pay(order, Role.shipper)
    ↓
_CartOrderActions.pay(...)
    ↓
PUT /api/shipper/orders/{id}/payment
    ↓
OrderController.payment(...)
```

Backend kiểm tra đúng người giao, đơn ở `PICKED_UP` hoặc `DELIVERING` và chưa xác nhận thanh toán, rồi ghi:

```java
order.paidAt = Instant.now();
order.paidBy = user;
```

- `paidAt`: thời điểm xác nhận thu tiền.
- `paidBy`: tài khoản xác nhận.

Sau đó, ở bước hoàn tất giao hàng, có kiểm tra:

```java
if (input.status().equals("DELIVERED") && order.paidAt == null) {
  throw bad("Cần xác nhận đã thu tiền trước khi hoàn thành");
}
```

Nếu chưa có thời điểm xác nhận thu tiền, backend chặn hoàn tất giao hàng.

Source cũng có API xác nhận thanh toán dành cho cửa hàng thuộc đúng chi nhánh, sau khi đơn được chấp nhận và không ở trạng thái hủy/từ chối. Điều kiện hoàn tất giao kiểm tra đơn đã có xác nhận thanh toán; không bắt buộc mọi đơn đều phải do chính shipper ghi nhận thanh toán.

Hiện tại đây là **ghi nhận thu tiền COD**, chưa có tích hợp cổng thanh toán online để kiểm chứng chuyển khoản hoặc tự động thu tiền.

### 7.10. Lịch sử trạng thái được ghi ở đâu?

Mở [CommerceSupport.java](../../backend/src/main/java/com/cstore/app/service/CommerceSupport.java), hàm `setStatus()`:

```java
public void setStatus(CustomerOrder o, String status) {
  o.status = status;
  o.history.add(new StatusEvent(status));
}
```

Dòng đầu cập nhật trạng thái hiện tại. Dòng sau thêm một sự kiện vào lịch sử. Giao diện dùng dữ liệu đó để hiển thị các mốc theo dõi đơn.

### 7.11. Vì sao màn khách và cửa hàng thấy được cập nhật của shipper?

Mỗi bên đọc dữ liệu từ cùng backend/database.

Sau thao tác, app thường gọi `reload()` để tải lại. Ngoài ra, `_loadSession()` tạo bộ hẹn giờ hỏi lại dữ liệu mỗi 10 giây khi phù hợp:

```dart
Timer.periodic(
  const Duration(seconds: 10),
  ...
);
```

Cách này gọi là polling. Vì phụ thuộc lịch tải và mạng, màn khác có thể thấy thay đổi sau một khoảng chờ. Source hiện chưa có push notification hoặc WebSocket để mọi thay đổi được đẩy tức thì đến các bên.

### 7.12. Câu nói mẫu khi mở code giao hàng

> “Sau khi cửa hàng chấp nhận, đơn chuyển sang ACCEPTED. Shipper trực tuyến, có ảnh đại diện, vị trí và nằm trong phạm vi phù hợp sẽ thấy đề nghị. Khi shipper nhận, backend kiểm tra lại, khóa dữ liệu để tránh tranh chấp rồi gắn shipper vào đơn và chuyển sang ASSIGNED. Các bước tiếp theo là đã lấy hàng, đang giao và giao thành công. Backend bắt buộc đi đúng thứ tự và yêu cầu xác nhận thu tiền trước khi hoàn tất. Mỗi thay đổi trạng thái đều được lưu vào lịch sử.”

## 8. File nào có vai trò gì? Mở đúng file khi thuyết trình

Các đường dẫn dưới đây tính từ thư mục gốc dự án.

| Việc muốn giải thích | File | Hàm hoặc class cần tìm |
| --- | --- | --- |
| Form đăng ký/đăng nhập, kiểm tra form | `mobile/lib/screens/auth/welcome.dart` | `LoginPage`, `submit()` |
| Điểm gọi thao tác từ giao diện | `mobile/lib/services/state/app_state.dart` | `AppState` |
| Đăng ký rồi đăng nhập, tải và xóa phiên | `mobile/lib/services/state/session_actions.dart` | `register()`, `login()`, `_loadSession()`, `logout()` |
| Gọi API đăng nhập, đọc token và tài khoản | `mobile/lib/services/api/account_api.dart` | `login()`, `_session()` |
| Gửi HTTP, JSON và header xác thực | `mobile/lib/services/api/api_client.dart` | `request()` |
| Chọn màn hình theo vai trò | `mobile/lib/app/role_home.dart` | `RoleHome.build()` |
| Backend đăng ký/đăng nhập | `backend/src/main/java/com/cstore/app/controller/AuthController.java` | `register()`, `login()` |
| Tạo JWT và kiểm tra trạng thái tài khoản | `backend/src/main/java/com/cstore/app/service/AccountService.java` | `session()` |
| BCrypt, kiểm tra JWT và phân quyền nhóm API | `backend/src/main/java/com/cstore/app/config/SecurityConfig.java` | `passwordEncoder()`, `jwtDecoder()`, `filterChain()` |
| Giỏ, gửi đơn, đổi trạng thái, xác nhận tiền | `mobile/lib/services/state/cart_order_actions.dart` | `change()`, `checkout()`, `transition()`, `pay()` |
| Form xác nhận đặt hàng | `mobile/lib/screens/customer/checkout_page.dart` | `loadQuote()`, `submit()` |
| Gọi báo giá và lưu vị trí giao | `mobile/lib/services/state/delivery_location_actions.dart` | `quoteDelivery()`, `setLocation()` |
| API báo giá, điểm giao, chi nhánh gần | `backend/src/main/java/com/cstore/app/controller/CustomerController.java` | `deliveryQuote()`, `deliveryLocation()`, `nearby()` |
| Tạo đơn, cửa hàng xác nhận, khách hủy, thu tiền | `backend/src/main/java/com/cstore/app/controller/OrderController.java` | `checkout()`, `storeStatus()`, `cancel()`, `payment()` |
| Kiểm tra phạm vi 10 km và tính phí | `backend/src/main/java/com/cstore/app/service/DeliveryService.java` | `quote()` |
| Shipper cập nhật vị trí và nhận đơn ở Flutter | `mobile/lib/services/state/shipper_actions.dart` | `setShipperPosition()`, `claim()` |
| Backend đề nghị, nhận đơn và giao hàng | `backend/src/main/java/com/cstore/app/controller/ShipperController.java` | `offers()`, `claim()`, `deliveryStatus()`, `navigation()` |
| Các nút theo vai trò/trạng thái | `mobile/lib/screens/orders/order_detail_page.dart` | `actions()` |
| Hoàn tồn và ghi lịch sử trạng thái | `backend/src/main/java/com/cstore/app/service/CommerceSupport.java` | `restore()`, `setStatus()` |
| Dữ liệu đơn hàng lưu database | `backend/src/main/java/com/cstore/app/entity/CustomerOrder.java` | `CustomerOrder` |
| Chi tiết từng sản phẩm và giá lúc đặt | `backend/src/main/java/com/cstore/app/entity/OrderLine.java` | `OrderLine` |

## 9. Trình tự mở code để trình bày mà không bị rối

Bạn có thể chuẩn bị sẵn các file cần mở trong trình soạn thảo. Mỗi lần chỉ giải thích một mục đích của đoạn code, sau đó mới sang file tiếp theo.

### Lượt 1 — Đăng ký

1. `welcome.dart` → chỉ `submit()` và nhánh `registering`.
2. `session_actions.dart` → chỉ yêu cầu `/auth/register` và đoạn gọi `app.login()` sau đó.
3. `AuthController.java` → chỉ kiểm tra email trùng, `passwords.encode()` và `users.save()`.

Kết thúc lượt này, người nghe cần hiểu tài khoản được tạo ở database và mật khẩu được băm.

### Lượt 2 — Đăng nhập

1. `AuthController.java` → `login()`, tìm email và kiểm tra mật khẩu.
2. `AccountService.java` → `session()`, thời hạn JWT.
3. `account_api.dart` trong thư mục `services/api/` → `_session()`, đọc token và user.
4. `role_home.dart` → đoạn `switch` chọn màn hình.

Kết thúc lượt này, người nghe cần hiểu kiểm tra tài khoản, tạo phiên và vào màn theo vai trò.

### Lượt 3 — Đặt hàng

1. `checkout_page.dart` → `submit()`, điều kiện form/ghim/báo giá.
2. `cart_order_actions.dart` → `checkout()`, dữ liệu gửi chỉ có mã sản phẩm và số lượng cùng thông tin giao.
3. `OrderController.java` → `checkout()`, kiểm tra tồn, trừ kho, cộng tiền và lưu đơn.
4. `DeliveryService.java` → `quote()`, giới hạn 10 km và công thức phí.

Kết thúc lượt này, người nghe cần hiểu ai quyết định giá, khi nào kho bị trừ và đơn ban đầu có trạng thái gì.

### Lượt 4 — Giao hàng

1. `OrderController.java` → `storeStatus()`, cửa hàng chấp nhận.
2. `ShipperController.java` → `offers()` và `claim()`, điều kiện nhận đơn.
3. Cũng file đó → `deliveryStatus()`, thứ tự chuyển trạng thái.
4. `OrderController.java` → `payment()`, ghi nhận thu tiền.
5. `CommerceSupport.java` → `setStatus()`, lưu lịch sử.

Kết thúc lượt này, người nghe cần hiểu cửa hàng và shipper phối hợp ra sao, vì sao không được nhảy bước, và thu tiền khác giao xong thế nào.

## 10. Những câu giảng viên dễ hỏi và cách trả lời

### “Tại sao kiểm tra trên Flutter rồi backend vẫn phải kiểm tra?”

Flutter giúp người dùng sửa lỗi nhập nhanh. Backend là nơi quyết định dữ liệu có được chấp nhận hay không, vì yêu cầu có thể được gửi từ một công cụ khác hoặc dữ liệu đã thay đổi trong lúc chờ.

Ví dụ lúc mở giỏ còn hàng, nhưng trước khi xác nhận thì một khách khác đã mua hết. Backend phải kiểm tra tồn kho lại.

### “App có được tự gửi tổng tiền không?”

Luồng tạo đơn hiện tại gửi mã sản phẩm và số lượng; backend lấy giá từ database và tính lại phí. Điều này tránh việc hệ thống tin một tổng tiền bị sửa từ phía gửi yêu cầu.

### “Đăng ký xong sao tự vào được app?”

Vì Flutter gọi thêm hàm đăng nhập sau khi API tạo tài khoản thành công.

### “Mật khẩu được lưu như thế nào?”

Lưu giá trị băm BCrypt trong `passwordHash`. Khi đăng nhập dùng `passwords.matches()` để kiểm tra mật khẩu nhập vào với giá trị băm.

### “JWT có phải mật khẩu không?”

JWT là thông tin xác nhận phiên được cấp sau đăng nhập. Các yêu cầu cần xác thực gửi kèm JWT; backend kiểm tra JWT và quyền. Mật khẩu được dùng trong bước đăng nhập để chứng minh người dùng có thông tin đăng nhập hợp lệ.

### “Chặn API bằng cách ẩn nút có đủ không?”

Ẩn nút chỉ điều khiển giao diện. Backend vẫn cần kiểm tra vai trò và quyền trên dữ liệu cụ thể. Dự án có Spring Security kiểm tra nhóm API và các controller/service kiểm tra đơn thuộc đúng khách, cửa hàng hoặc shipper.

### “Tồn kho bị trừ lúc thêm vào giỏ hay lúc đặt?”

Tồn kho được trừ khi backend xử lý tạo đơn. Thêm vào giỏ trên Flutter chưa giữ tồn kho trong database.

### “Nếu thiếu hàng ở một sản phẩm thì các sản phẩm đã trừ trước đó ra sao?”

Việc tạo đơn và trừ kho nằm trong transaction. Khi lỗi làm giao dịch thất bại, các thay đổi database trong giao dịch được hoàn tác.

### “Hai người cùng mua sản phẩm cuối cùng thì sao?”

Backend khóa bản ghi sản phẩm để kiểm tra và trừ tồn trong transaction. Giao dịch đến sau phải kiểm tra lượng còn lại sau giao dịch giữ khóa trước đó.

### “Hai shipper cùng nhận một đơn thì sao?”

Backend khóa dữ liệu và kiểm tra đơn chưa có shipper trước khi gắn người giao. Shipper nhận sau sẽ không vượt qua điều kiện nếu đơn đã được nhận.

### “Shipper được nhận đơn cách khách 5 km đúng không?”

Giới hạn 5 km trong luồng nhận đơn là khoảng cách đường bộ từ shipper đến cửa hàng. Giới hạn giao 10 km là từ cửa hàng đến khách.

### “Hệ thống tự giao đơn cho người gần nhất phải không?”

Source hiện lọc danh sách đề nghị theo điều kiện, rồi shipper chủ động nhận. Không nên mô tả thành thuật toán tự gán đơn cho người gần nhất.

### “Đã thanh toán có nghĩa đã giao xong không?”

Xác nhận tiền ghi `paidAt` và `paidBy`. Xác nhận giao xong đổi trạng thái thành `DELIVERED`. Đây là hai thông tin riêng; hoàn tất giao cần có xác nhận thu tiền trước.

### “Có thanh toán online không?”

Luồng mua hàng hiện là COD, có thao tác ghi nhận đã thu tiền. Chưa có tích hợp thanh toán online trong luồng này.

### “Khách muốn hủy sau khi cửa hàng chấp nhận được không?”

API hủy của khách hiện chỉ cho hủy đơn còn `PENDING`. Khi đã `ACCEPTED`, yêu cầu hủy theo luồng đó bị chặn.

### “Đơn hủy/từ chối có bị mất số hàng đã trừ không?”

Backend gọi `restore()` để cộng lại số lượng các dòng đơn vào kho khi hủy/từ chối hợp lệ.

### “Dữ liệu có cập nhật ngay lập tức không?”

App tải lại sau thao tác và hỏi lại định kỳ 10 giây. Có thể có độ trễ do chu kỳ tải và mạng. Source hiện chưa dùng push/WebSocket cho luồng cập nhật này.

### “GPS có bảo đảm shipper thực sự đến nơi mới bấm được không?”

Không nên khẳng định như vậy từ source hiện tại. GPS và tuyến đường hỗ trợ vị trí/điều hướng; chuyển trạng thái kiểm tra quyền, thứ tự và thanh toán, còn có chế độ mô phỏng cho bước lấy hàng. Điều đó chưa chứng minh shipper đã tới thực địa.

## 11. Tự kiểm tra xem mình đã hiểu chưa

Thử trả lời trước khi nhìn phần gợi ý:

1. Đăng ký khác đăng nhập ở điểm nào?
2. Sau đăng ký, đoạn code nào khiến người dùng được đăng nhập?
3. Backend kiểm tra mật khẩu bằng hàm gì?
4. App biết mở màn khách hay shipper từ thông tin nào?
5. Cho sản phẩm vào giỏ có làm giảm kho ngay chưa?
6. Backend lấy giá tạo đơn ở đâu?
7. Vì sao tạo đơn cần transaction?
8. Đơn mới tạo mang trạng thái nào?
9. Shipper nhận đơn khi trạng thái nào?
10. Giới hạn 5 km và 10 km khác nhau ra sao?
11. Có thể chuyển từ `ASSIGNED` thẳng sang `DELIVERED` không?
12. Muốn hoàn tất giao cần có thông tin gì về tiền?

Gợi ý đáp án:

| Câu | Ý chính |
| --- | --- |
| 1 | Tạo tài khoản mới / kiểm tra tài khoản và cấp phiên |
| 2 | `_SessionActions.register()` gọi `app.login()` sau yêu cầu đăng ký |
| 3 | `passwords.matches()` |
| 4 | Vai trò trong thông tin tài khoản do backend trả về |
| 5 | Chưa, kho trừ khi tạo đơn thành công |
| 6 | Giá sản phẩm ở database |
| 7 | Để tạo đơn và trừ kho được ghi nhận hoặc hoàn tác cùng nhau |
| 8 | `PENDING` |
| 9 | `ACCEPTED`, cùng các điều kiện nhận khác |
| 10 | Shipper đến cửa hàng / cửa hàng đến khách |
| 11 | Không, phải đúng thứ tự |
| 12 | Đơn đã có xác nhận thu tiền, tức `paidAt` khác null |

## 12. Bài thuyết trình mẫu khoảng 5–7 phút

Bạn có thể đổi cách xưng hô cho phù hợp. Khi tập, nói chậm và chỉ vào đúng hàm đang giải thích. Thời lượng thực tế phụ thuộc tốc độ nói và phần thao tác minh họa.

### Mở đầu

“Em xin trình bày bốn chức năng liên quan trực tiếp đến quá trình mua hàng của C-Store: đăng ký, đăng nhập, đặt hàng và giao hàng.

Ứng dụng có ba phần chính. Flutter hiển thị giao diện và nhận thao tác. Spring Boot tiếp nhận yêu cầu qua API và xử lý nghiệp vụ. MySQL lưu dữ liệu như tài khoản, sản phẩm và đơn hàng.

Em sẽ đi theo ví dụ một khách hàng đăng ký tài khoản, mua hàng tại chi nhánh, sau đó cửa hàng và shipper xử lý đơn.”

### Trình bày đăng ký

“Đầu tiên là đăng ký. Người dùng nhập họ tên, email, mật khẩu và chọn vai trò khách hàng hoặc shipper.

Ở file welcome.dart, hàm submit kiểm tra form rồi gọi AppState.register. Yêu cầu được gửi đến API auth/register.

Ở backend, AuthController kiểm tra dữ liệu và kiểm tra email đã được sử dụng chưa. Nếu hợp lệ, backend băm mật khẩu bằng BCrypt rồi lưu tài khoản vào database. API công khai này chỉ cho tạo khách hàng hoặc shipper.

Sau khi đăng ký thành công, Flutter gọi thêm đăng nhập, vì vậy người dùng có thể vào ứng dụng ngay.”

### Trình bày đăng nhập

“Tiếp theo là đăng nhập. Flutter gửi email và mật khẩu đến API auth/login. Backend tìm tài khoản và dùng passwords.matches để kiểm tra mật khẩu.

Sau khi thông tin hợp lệ và tài khoản được phép hoạt động, AccountService cấp JWT có thời hạn 8 giờ, kèm thông tin tài khoản.

App giữ token trong RAM và gửi kèm khi gọi các API cần xác thực. Ở RoleHome, Flutter đọc vai trò để hiển thị màn khách hàng, cửa hàng, shipper hoặc admin.

Việc chọn màn hình là phần giao diện. Backend vẫn kiểm tra quyền mỗi khi nhận yêu cầu, nên một khách hàng không thể dùng quyền của shipper chỉ bằng cách đổi màn hình.”

### Trình bày đặt hàng

“Sau khi đăng nhập, khách chọn điểm giao, chọn chi nhánh và thêm sản phẩm vào giỏ. Giỏ hàng lưu mã sản phẩm và số lượng trong AppState. Lúc thêm vào giỏ, tồn kho trong database chưa bị trừ.

Tại CheckoutPage, khách kiểm tra tên người nhận, số điện thoại, địa chỉ và xác nhận điểm giao trên bản đồ. Ứng dụng lấy báo giá giao trước khi cho xác nhận.

DeliveryService tính phí bằng quãng đường bộ OSRM, giới hạn từ cửa hàng tới khách là 10 km. Phí bằng 15.000 đồng cộng phần quãng đường nhân 3.000 đồng mỗi km, làm tròn lên phần tiền đó.

Khi xác nhận đặt, Flutter gửi mã sản phẩm và số lượng cùng thông tin giao hàng. Backend tự lấy giá từ database, kiểm tra sản phẩm, chi nhánh và tồn kho, rồi trừ kho và tạo đơn PENDING.

Các thay đổi nằm trong một transaction. Nếu có sản phẩm không đủ hàng làm yêu cầu thất bại, giao dịch được hoàn tác. Backend cũng khóa bản ghi sản phẩm khi kiểm tra và trừ kho để tránh bán vượt tồn khi nhiều người đặt cùng lúc.”

### Trình bày giao hàng

“Đơn PENDING được cửa hàng xem và chấp nhận. Khi đó đơn chuyển sang ACCEPTED và chờ shipper.

Shipper có ảnh đại diện, đang trực tuyến và có vị trí phù hợp sẽ thấy các đề nghị nhận đơn. Khoảng cách đường bộ từ shipper tới cửa hàng phải trong 5 km. Mỗi shipper được giữ tối đa 3 đơn đang thực hiện.

Khi shipper nhận đơn, backend kiểm tra lại và gắn shipper vào đơn, chuyển trạng thái thành ASSIGNED. Các bước tiếp theo là PICKED_UP, DELIVERING và DELIVERED, tương ứng đã lấy hàng, đang giao và đã giao.

Backend bắt buộc đúng người giao và đúng thứ tự trạng thái. Trước khi hoàn tất, đơn phải được xác nhận đã thu tiền COD. Thao tác thu tiền ghi thời điểm và người xác nhận; thao tác giao xong mới đổi trạng thái sang DELIVERED.

Nếu khách hủy khi đơn còn chờ, hoặc cửa hàng từ chối đơn đang chờ, backend hoàn lại tồn kho. Mỗi lần đổi trạng thái đều ghi vào lịch sử để hiển thị theo dõi đơn. Các màn hình tải lại dữ liệu sau thao tác và theo chu kỳ khoảng 10 giây.”

## 13. Phiếu nhớ nhanh trước khi lên trình bày

| Chức năng | Người dùng làm gì? | Backend kiểm tra gì? | Kết quả chính |
| --- | --- | --- | --- |
| Đăng ký | Nhập thông tin và chọn vai trò | Dữ liệu, vai trò, email trùng | Lưu tài khoản với mật khẩu băm |
| Đăng nhập | Nhập email và mật khẩu | Mật khẩu, trạng thái tài khoản | Trả JWT và tài khoản |
| Đặt hàng | Chọn hàng và xác nhận giao nhận | Chi nhánh, tuyến giao, giá, tồn kho | Trừ kho, lưu đơn `PENDING` |
| Giao hàng | Cửa hàng xác nhận, shipper nhận và giao | Điều kiện nhận, quyền sở hữu, thứ tự, tiền | Lưu tiến trình đến `DELIVERED` |

Các con số cần nhớ theo source hiện tại:

- Mật khẩu đăng ký: 8–72 ký tự theo kiểm tra đang khai báo.
- JWT: 8 giờ.
- Cửa hàng đến khách: tối đa 10 km đường bộ.
- Shipper đến cửa hàng để nhận đơn: tối đa 5 km đường bộ.
- Mỗi shipper: tối đa 3 đơn đang thực hiện đồng thời.
- Phí giao: 15.000đ + làm tròn lên(km đường bộ × 3.000đ).
- Tải lại dữ liệu định kỳ: 10 giây khi phiên đang hoạt động và điều kiện tải cho phép.

## 14. Những điều cần mô tả đúng với phiên bản hiện tại

- Có các luồng đăng nhập Google/Facebook trong source, phụ thuộc cấu hình phù hợp. Phần giải thích chi tiết ở tài liệu này tập trung đăng ký và đăng nhập email.
- Phiên app giữ trong RAM, chưa có refresh token/tự khôi phục đăng nhập sau khi khởi động lại app.
- Luồng thanh toán mua hàng hiện là COD và ghi nhận đã thu tiền, chưa có cổng thanh toán online.
- Dữ liệu cập nhật bằng tải lại/polling, chưa có cơ chế push tức thì cho toàn bộ tiến trình đơn.
- Bản đồ, dịch vụ tìm đường, địa chỉ và GPS là những thành phần khác nhau. Không suy từ việc hiển thị một tuyến đường rằng đã chứng minh vị trí thực địa của shipper.
- Các quy tắc trên được giải thích từ source. Muốn khẳng định một luồng đã chạy thành công trên emulator hoặc thiết bị thật, cần thực hiện kiểm thử tương ứng và đối chiếu log.
