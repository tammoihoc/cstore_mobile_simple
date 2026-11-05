# Đọc từng dòng source trong các luồng cốt lõi

Chương này trích **nguyên source đang có** và đánh số theo dòng thật trong file, không phải số dòng tự đặt trong ví dụ. Mỗi câu lệnh, phần xuống dòng của lời gọi và dấu đóng khối đều có chú giải riêng. Dòng trống chỉ phân tách nhóm; comment giúp đọc và không được thực thi.

Đây là phần hướng dẫn chi tiết cho các đường chạy trung tâm, không tuyên bố đã chú giải từng dòng của toàn bộ UI/native/test. Đọc cùng [bản đồ source](ban-do-source.md), [công nghệ](cong-nghe.md), [backend](backend.md), [giao diện](mobile-giao-dien.md), [lệnh chạy](lenh-va-cau-hinh.md) và [thuật ngữ](thuat-ngu.md).

Luồng đăng nhập: **main → CStoreApp/RoleHome → form → AppState.login → _SessionActions.login → AccountApi.login → ApiClient.request/_send → AuthController.login → AccountService.session → AccountApi._session → nạp phiên → RoleHome dựng lại**. Các wrapper AppState chỉ chuyển việc sang action tương ứng; không tạo một state thứ hai.

Luồng đặt hàng: **catalog → Map giỏ → _CartOrderActions.checkout → HTTP POST → OrderController.checkout → Products.locked → lưu snapshot/giảm tồn → JSON → ShopOrder → tải lại UI**. Validation/filter/mapping còn có chi tiết ở các chương chuyên đề.

Tài liệu được tạo bằng `scripts/generate-reading-guide.py`. Script chỉ đọc các file Java/Dart được liệt kê tường minh; không đọc `.env`, file cấu hình social local, token mặc định, cache hay artifact. Chú giải được biên soạn theo từng câu lệnh; nếu source khác, script dừng để cập nhật chú giải thay vì gắn giải thích cũ vào code mới.

Tạo lại từ gốc dự án, có log Kitty:

```bash
python3 scripts/run-visible.py --name "Tạo hướng dẫn từng dòng" -- python3 scripts/generate-reading-guide.py
```

## 1. Dart bắt đầu chạy ứng dụng

File: [`mobile/lib/main.dart`](../../mobile/lib/main.dart). Dòng 1–8.

**Đầu vào và trách nhiệm:** Đầu vào là tiến trình Android đã mở Flutter engine. File này nối entry point Dart với widget gốc.

**Kết quả và nhánh lỗi:** runApp gắn CStoreApp vào cây widget. Nó chưa đăng nhập hay đọc database trực tiếp.

Các số đầu dòng dưới đây là số dòng file, không phải một phần cú pháp cần chép vào IDE.

```text
   1 | import 'package:flutter/material.dart';
   2 | 
   3 | import 'app/app.dart';
   4 | 
   5 | /// Dart chạy từ đây; runApp gắn widget gốc vào màn hình Android.
   6 | void main() {
   7 |   runApp(const CStoreApp());
   8 | }
```

| Dòng source | Giải thích chi tiết |
| --- | --- |
| 1 | Nạp API Material/Flutter, trong đó có runApp dùng ở cuối file. |
| 2 | Dòng trống phân tách các nhóm câu lệnh; không tạo hành động khi chạy. |
| 3 | Nạp CStoreApp do dự án định nghĩa; đây là file cấu hình widget gốc. |
| 4 | Dòng trống phân tách các nhóm câu lệnh; không tạo hành động khi chạy. |
| 5 | Chú thích của source: Dart chạy từ đây; runApp gắn widget gốc vào màn hình Android. Không phải câu lệnh thực thi. |
| 6 | Điểm vào Dart; void cho biết hàm không trả một giá trị nghiệp vụ, dấu { mở thân hàm. |
| 7 | Tạo cấu hình CStoreApp dạng const rồi giao cho Flutter dựng cây UI; không có HTTP nào được viết ở dòng này. |
| 8 | Đóng main; vòng đời giao diện tiếp tục do Flutter quản lý sau lời gọi runApp. |

## 2. Chọn giao diện theo phiên đăng nhập

File: [`mobile/lib/app/role_home.dart`](../../mobile/lib/app/role_home.dart). Dòng 18–34.

**Đầu vào và trách nhiệm:** RoleHome nhận AppState. build trả một widget phản ánh tài khoản hiện tại, không cấp quyền truy cập backend.

**Kết quả và nhánh lỗi:** Khi account đổi và state phát thông báo, builder chạy lại để chọn LoginPage hoặc màn hình đúng vai trò.

Các số đầu dòng dưới đây là số dòng file, không phải một phần cú pháp cần chép vào IDE.

```text
  18 |   @override
  19 |   Widget build(BuildContext context) {
  20 |     return ListenableBuilder(
  21 |       listenable: state,
  22 |       builder: (context, _) {
  23 |         final account = state.account;
  24 |         if (account == null) return LoginPage(state: state);
  25 | 
  26 |         return switch (account.role) {
  27 |           Role.customer => CustomerHome(state: state),
  28 |           Role.store => StoreHome(state: state),
  29 |           Role.shipper => ShipperHome(state: state),
  30 |           Role.admin => AdminHome(state: state),
  31 |         };
  32 |       },
  33 |     );
  34 |   }
```

| Dòng source | Giải thích chi tiết |
| --- | --- |
| 18 | Method này hiện thực build của StatelessWidget; analyzer kiểm tra bạn đang ghi đè đúng giao diện. |
| 19 | Nhận vị trí widget trong cây và trả một Widget; bắt đầu phần mô tả UI. |
| 20 | Trả widget chuyên nghe thay đổi, thay vì tự gọi build của các trang bằng tay. |
| 21 | Đăng ký nghe cùng AppState mà phiên đăng nhập đang cập nhật. |
| 22 | Callback tạo UI mỗi khi cần; dấu _ nói tham số thứ hai không được dùng. |
| 23 | Đọc tài khoản một lần cho lượt build hiện tại để các nhánh bên dưới dùng cùng giá trị. |
| 24 | Chưa có tài khoản thì trả trang đăng nhập và truyền cùng state cho form sử dụng. |
| 25 | Dòng trống phân tách các nhóm câu lệnh; không tạo hành động khi chạy. |
| 26 | Có tài khoản rồi thì switch expression chọn một widget theo role trả từ backend. |
| 27 | Khách hàng được dẫn tới màn mua hàng, đơn và hồ sơ khách. |
| 28 | Tài khoản cửa hàng mở giao diện quản lý chi nhánh/sản phẩm/đơn. |
| 29 | Shipper mở giao diện nhận đơn và giao hàng. |
| 30 | Admin mở giao diện quản trị; các API admin vẫn kiểm tra quyền độc lập. |
| 31 | Kết thúc switch expression và trả widget đã chọn cho callback builder. |
| 32 | Đóng callback builder; dấu phẩy kết thúc named argument của ListenableBuilder. |
| 33 | Kết thúc constructor ListenableBuilder và câu return. |
| 34 | Đóng build; hàm không lưu dữ liệu bền vững và có thể được Flutter gọi nhiều lần. |

## 3. State điều phối đăng nhập email

File: [`mobile/lib/services/state/session_actions.dart`](../../mobile/lib/services/state/session_actions.dart). Dòng 10–24.

**Đầu vào và trách nhiệm:** _SessionActions dùng cùng AppState. Đầu vào là email và password form gửi qua AppState.login.

**Kết quả và nhánh lỗi:** Thành công: có account và dữ liệu phiên được nạp. Thất bại: logout dọn phiên rồi rethrow để UI hiển thị lỗi.

Các số đầu dòng dưới đây là số dòng file, không phải một phần cú pháp cần chép vào IDE.

```text
  10 |   Future<void> login(
  11 |     String email,
  12 |     String password,
  13 |   ) async {
  14 |     try {
  15 |       app.account = await app.api.login(
  16 |         email.trim(),
  17 |         password,
  18 |       );
  19 |       await app._loadSession();
  20 |     } catch (e) {
  21 |       app.logout();
  22 |       rethrow;
  23 |     }
  24 |   }
```

| Dòng source | Giải thích chi tiết |
| --- | --- |
| 10 | Hàm bất đồng bộ không trả model; mục tiêu của nó là cập nhật trạng thái phiên dùng chung. |
| 11 | Email do form chuyển vào, chưa được trim tại vị trí khai báo tham số. |
| 12 | Mật khẩu đầu vào; giữ nguyên nội dung, không in và không tự trim mật khẩu. |
| 13 | Đóng danh sách tham số và bật cú pháp await trong thân hàm. |
| 14 | Bắt đầu nhóm thao tác mà nếu lỗi sẽ được dọn phiên ở catch. |
| 15 | Chờ API xác thực; chỉ gán account khi lời gọi trả một Account thành công. |
| 16 | Bỏ khoảng trắng ở hai đầu email để tránh nhập dư khoảng trắng làm sai tài khoản. |
| 17 | Chuyển nguyên mật khẩu cho lớp API, không tự hash ở Flutter. |
| 18 | Đóng lời gọi API và hoàn tất phép gán account sau await. |
| 19 | Nạp chi nhánh/dữ liệu theo vai trò, vị trí đã lưu và polling; không coi chỉ nhận token là đã nạp xong phiên. |
| 20 | Nếu API hoặc bước nạp phiên ném lỗi, chuyển sang nhánh xử lý lỗi này. |
| 21 | Dọn account/token/timer/giỏ và các dữ liệu phiên để không giữ một phiên đăng nhập dở dang. |
| 22 | Gửi lại lỗi gốc cho nơi gọi, để form có thể hiển thị thông báo thích hợp. |
| 23 | Đóng catch; nhánh lỗi không được chuyển thành một kết quả đăng nhập thành công giả. |
| 24 | Đóng method login; Future hoàn tất khi mọi bước đã chạy hoặc lỗi đã được ném lại. |

## 4. API tài khoản chọn endpoint đăng nhập

File: [`mobile/lib/services/api/account_api.dart`](../../mobile/lib/services/api/account_api.dart). Dòng 12–21.

**Đầu vào và trách nhiệm:** Đầu vào là email/password. AccountApi biết endpoint và kiểu model; ApiClient xử lý phần HTTP chung.

**Kết quả và nhánh lỗi:** Response được đọc thành Map rồi chuyển sang _session. HTTP lỗi được ApiClient ném trước khi đến bước chuyển model.

Các số đầu dòng dưới đây là số dòng file, không phải một phần cú pháp cần chép vào IDE.

```text
  12 |   Future<Account> login(
  13 |     String email,
  14 |     String password,
  15 |   ) async {
  16 |     final data = await request(
  17 |       '/auth/login',
  18 |       body: {'email': email, 'password': password},
  19 |     ) as Map<String, dynamic>;
  20 |     return _session(data);
  21 |   }
```

| Dòng source | Giải thích chi tiết |
| --- | --- |
| 12 | Khai báo kết quả bất đồng bộ là Account, khác với method state chỉ trả Future<void>. |
| 13 | Nhận email đã được nơi điều phối chuẩn bị. |
| 14 | Nhận password để gửi trong body đăng nhập; không ghi log giá trị này. |
| 15 | Mở thân method có await. |
| 16 | Gọi request kế thừa từ ApiClient và chờ response đã JSON decode. |
| 17 | Chọn path đăng nhập; ApiClient nối thêm base và tiền tố /api. |
| 18 | Tạo Map JSON với đúng hai trường backend Login DTO nhận; không gửi role để tự nâng quyền. |
| 19 | Đóng request và yêu cầu kết quả là JSON object; response sai cấu trúc gây lỗi kiểu thay vì tạo Account tùy tiện. |
| 20 | Đọc user/token trong response bằng helper, trả Account cho state. |
| 21 | Đóng lời gọi endpoint đăng nhập; logic HTTP lặp lại không nằm trong method này. |

## 5. Đọc phiên backend trả về

File: [`mobile/lib/services/api/account_api.dart`](../../mobile/lib/services/api/account_api.dart). Dòng 45–53.

**Đầu vào và trách nhiệm:** Đầu vào là JSON object của response Session. Đây là nơi ghi token vào RAM của API client.

**Kết quả và nhánh lỗi:** Trả Account đã parse; token chỉ được dùng cho các request sau. File này không lưu token vào database/ổ đĩa.

Các số đầu dòng dưới đây là số dòng file, không phải một phần cú pháp cần chép vào IDE.

```text
  45 |   Account _session(
  46 |     Map<String, dynamic> data,
  47 |   ) {
  48 |     final account = Account.fromJson(
  49 |       data['user'] as Map<String, dynamic>,
  50 |     );
  51 |     token = data['token'] as String;
  52 |     return account;
  53 |   }
```

| Dòng source | Giải thích chi tiết |
| --- | --- |
| 45 | Helper đồng bộ trả Account; dấu _ giới hạn tên trong library Dart này. |
| 46 | Nhận object JSON có các trường user và token từ backend. |
| 47 | Đóng khai báo tham số, mở thân helper. |
| 48 | Dựng model Account bằng factory parser, để UI không phải tự đọc từng khóa JSON. |
| 49 | Lấy object user và xác nhận kiểu dữ liệu đầu vào của parser. |
| 50 | Đóng lời gọi parser; lúc này account là model Dart. |
| 51 | Giữ JWT của C-Store trong field RAM, dùng cho Authorization header về sau; không in giá trị. |
| 52 | Trả model người dùng cho method login và AppState. |
| 53 | Đóng helper chuyển response thành phiên; thiếu/sai kiểu trường sẽ không âm thầm tạo phiên hợp lệ. |

## 6. Gửi request và chuyển lỗi HTTP thành lỗi của app

File: [`mobile/lib/services/api/api_client.dart`](../../mobile/lib/services/api/api_client.dart). Dòng 21–53.

**Đầu vào và trách nhiệm:** Đầu vào gồm path, body tùy chọn và method tùy chọn. Đầu ra có thể là Map/List/null sau JSON decode.

**Kết quả và nhánh lỗi:** Thành công trả dữ liệu; timeout, mạng, lỗi JSON hoặc status HTTP từ 400 trở lên tạo lỗi để lớp state/UI xử lý.

Các số đầu dòng dưới đây là số dòng file, không phải một phần cú pháp cần chép vào IDE.

```text
  21 |   Future<dynamic> request(
  22 |     String path, {
  23 |     Map<String, dynamic>? body,
  24 |     String? method,
  25 |   }) async {
  26 |     final uri = Uri.parse('$base/api$path');
  27 |     final headers = {
  28 |       'Content-Type': 'application/json',
  29 |       if (token != null) 'Authorization': 'Bearer $token',
  30 |     };
  31 | 
  32 |     // Không có body thì mặc định đọc GET; có body thì mặc định gửi POST.
  33 |     final requestMethod = method ?? (body == null ? 'GET' : 'POST');
  34 |     final timeoutSeconds = path.startsWith('/customer/nearby') ? 60 : 20;
  35 |     final response = await _send(
  36 |       requestMethod,
  37 |       uri,
  38 |       headers,
  39 |       body,
  40 |     ).timeout(Duration(seconds: timeoutSeconds));
  41 | 
  42 |     if (response.statusCode >= 400) {
  43 |       final serverMessage = _readErrorMessage(response);
  44 |       throw StateError(_errorMessage(
  45 |         response.statusCode,
  46 |         path,
  47 |         serverMessage,
  48 |       ));
  49 |     }
  50 | 
  51 |     if (response.body.isEmpty) return null;
  52 |     return jsonDecode(utf8.decode(response.bodyBytes));
  53 |   }
```

| Dòng source | Giải thích chi tiết |
| --- | --- |
| 21 | Helper HTTP tổng quát; dynamic vì các endpoint có thể trả object, list hoặc không có body. |
| 22 | Nhận path bắt buộc và mở nhóm named parameters bằng dấu { của danh sách tham số. |
| 23 | Body JSON có thể null; null còn ảnh hưởng HTTP method mặc định. |
| 24 | Cho nơi gọi ghi đè HTTP method, như PUT hoặc DELETE. |
| 25 | Đóng nhóm named parameters, đóng tham số hàm và mở thân bất đồng bộ. |
| 26 | Ghép base cấu hình, tiền tố /api và path chức năng thành Uri dùng cho HTTP client. |
| 27 | Tạo Map header cho lần gửi hiện tại. |
| 28 | Khai báo body gửi theo JSON, để backend đọc đúng định dạng. |
| 29 | Chỉ thêm Bearer header khi đang có token; không có token vẫn gọi được endpoint công khai. |
| 30 | Đóng Map header; đây không phải nội dung body JSON. |
| 31 | Dòng trống phân tách các nhóm câu lệnh; không tạo hành động khi chạy. |
| 32 | Chú thích của source: Không có body thì mặc định đọc GET; có body thì mặc định gửi POST. Không phải câu lệnh thực thi. |
| 33 | Ưu tiên method tường minh; nếu thiếu, body null chọn GET, có body chọn POST. |
| 34 | Cho luồng tìm cửa hàng gần đây nhiều thời gian hơn vì có xử lý tuyến đường. |
| 35 | Giao bước chọn hàm HTTP cụ thể cho _send và chờ response. |
| 36 | Truyền method đã xác định thay vì tính lại ở mỗi nhánh. |
| 37 | Truyền URL đã ghép đúng prefix. |
| 38 | Chuyển Content-Type và Bearer header nếu có. |
| 39 | Chuyển Map đầu vào để _send encode khi method cần body. |
| 40 | Giới hạn thời gian chờ Future; timeout tạo lỗi, không tạo response thành công giả. |
| 41 | Dòng trống phân tách các nhóm câu lệnh; không tạo hành động khi chạy. |
| 42 | Rẽ nhánh khi server trả mã lỗi HTTP. |
| 43 | Thử đọc trường message của server; helper chịu được body không phải JSON hợp lệ. |
| 44 | Chuyển status/path/message thành lỗi có lời nhắn dễ hiểu cho app. |
| 45 | Dùng mã HTTP để phân biệt 401, 403, 409 và các trường hợp khác. |
| 46 | Dùng path để chọn thông báo phù hợp, ví dụ lỗi login khác lỗi phiên hết hạn. |
| 47 | Giữ thông điệp nghiệp vụ server nếu quy tắc helper cho phép. |
| 48 | Đóng lời gọi tạo thông báo và StateError; throw dừng nhánh success ở đây. |
| 49 | Kết thúc xử lý HTTP lỗi. |
| 50 | Dòng trống phân tách các nhóm câu lệnh; không tạo hành động khi chạy. |
| 51 | Chấp nhận response không có body, ví dụ 204; không JSON decode chuỗi rỗng. |
| 52 | Giải mã byte UTF-8 để giữ chữ Việt, rồi parse JSON thành Map/List/giá trị Dart. |
| 53 | Đóng request; phần HTTP dùng chung không quyết định quy tắc tồn kho hay quyền đơn hàng. |

## 7. HTTP client thực sự chọn GET/POST/PUT/DELETE

File: [`mobile/lib/services/api/api_client.dart`](../../mobile/lib/services/api/api_client.dart). Dòng 55–87.

**Đầu vào và trách nhiệm:** Nhận method, Uri, header và Map body từ request. Method này chưa kiểm tra status hay chuyển JSON response.

**Kết quả và nhánh lỗi:** Trả Future<http.Response> cho request. Dữ liệu gửi đi được jsonEncode khi cần; response vẫn còn dạng HTTP.

Các số đầu dòng dưới đây là số dòng file, không phải một phần cú pháp cần chép vào IDE.

```text
  55 |   Future<http.Response> _send(
  56 |     String method,
  57 |     Uri uri,
  58 |     Map<String, String> headers,
  59 |     Map<String, dynamic>? body,
  60 |   ) {
  61 |     String? encodedBody() => body == null ? null : jsonEncode(body);
  62 | 
  63 |     switch (method) {
  64 |       case 'PUT':
  65 |         return client.put(
  66 |           uri,
  67 |           headers: headers,
  68 |           body: encodedBody(),
  69 |         );
  70 |       case 'DELETE':
  71 |         return client.delete(
  72 |           uri,
  73 |           headers: headers,
  74 |         );
  75 |       case 'POST':
  76 |         return client.post(
  77 |           uri,
  78 |           headers: headers,
  79 |           body: encodedBody(),
  80 |         );
  81 |       default:
  82 |         return client.get(
  83 |           uri,
  84 |           headers: headers,
  85 |         );
  86 |     }
  87 |   }
```

| Dòng source | Giải thích chi tiết |
| --- | --- |
| 55 | Helper private trả response HTTP thô, không trả model nghiệp vụ. |
| 56 | Method đã được request chọn hoặc người gọi ghi đè. |
| 57 | URL đích đã parse. |
| 58 | Map header có giá trị chuỗi, như Content-Type và Authorization. |
| 59 | Body trước khi encode, có thể null. |
| 60 | Mở thân helper; không cần async vì trả trực tiếp Future do HTTP client tạo. |
| 61 | Hàm local đổi Map thành JSON string khi có body; giữ null nếu không có. |
| 62 | Dòng trống phân tách các nhóm câu lệnh; không tạo hành động khi chạy. |
| 63 | Chọn API client phù hợp theo chuỗi HTTP method. |
| 64 | Nhánh cập nhật PUT. |
| 65 | Trả Future của HTTP PUT ngay cho method gọi. |
| 66 | Gửi đến đúng Uri đầu vào. |
| 67 | Gắn header của request, gồm token nếu phiên có. |
| 68 | Encode body khi gửi PUT, không gửi nguyên đối tượng Map tùy tiện. |
| 69 | Đóng lời gọi client.put và return của nhánh PUT. |
| 70 | Nhánh DELETE cho endpoint xóa/ngừng hoạt động. |
| 71 | Trả Future của DELETE. |
| 72 | Chọn URL tài nguyên cần xóa/thao tác. |
| 73 | Vẫn gửi chứng cứ phiên; xóa không có nghĩa bỏ phân quyền. |
| 74 | Đóng DELETE; triển khai này không gửi JSON body cho nhánh DELETE. |
| 75 | Nhánh POST dùng cho tạo tài nguyên hoặc hành động. |
| 76 | Trả Future của HTTP POST. |
| 77 | Chọn endpoint nhận dữ liệu. |
| 78 | Truyền metadata và Bearer nếu có. |
| 79 | Serialize Map thành JSON string trước khi gửi POST. |
| 80 | Đóng client.post và kết thúc nhánh POST. |
| 81 | Các method không khớp ba nhánh trên đi vào GET của triển khai hiện tại. |
| 82 | Tạo yêu cầu đọc GET và trả Future tương ứng. |
| 83 | URL có thể chứa query, ví dụ storeId khi đọc catalog. |
| 84 | GET vẫn có thể cần Bearer header ở endpoint riêng tư. |
| 85 | Đóng client.get; không gắn body vào GET. |
| 86 | Kết thúc switch; mỗi nhánh đã return một Future HTTP. |
| 87 | Đóng _send; lỗi/status sẽ được phần request bên ngoài xử lý tiếp. |

## 8. Tải catalog và bỏ phản hồi đã cũ

File: [`mobile/lib/services/state/catalog_actions.dart`](../../mobile/lib/services/state/catalog_actions.dart). Dòng 70–95.

**Đầu vào và trách nhiệm:** Đọc sản phẩm của cửa hàng đăng nhập hoặc chi nhánh khách đã chọn. Danh sách server được dùng để điều chỉnh giỏ hiện tại.

**Kết quả và nhánh lỗi:** Chỉ response mới nhất cập nhật products. Giỏ bị loại/giảm các mục không còn bán hoặc vượt tồn; method điều phối bên ngoài quyết định lúc refresh UI.

Các số đầu dòng dưới đây là số dòng file, không phải một phần cú pháp cần chép vào IDE.

```text
  70 |   Future<void> loadProducts() async {
  71 |     // Mỗi lần tải có số thứ tự. Chỉ kết quả mới nhất được ghi vào products.
  72 |     final revision = ++app._productsRevision;
  73 |     final path = app.account?.role == Role.store
  74 |         ? '/merchant/products'
  75 |         : '/products?storeId=${app.selected!.id}';
  76 |     final loaded = [
  77 |       for (final j in await app.api.request(path) as List)
  78 |         productFromJson(
  79 |           j as Map<String, dynamic>,
  80 |         )
  81 |     ];
  82 |     if (revision != app._productsRevision) return;
  83 |     app.products
  84 |       ..clear()
  85 |       ..addAll(loaded);
  86 |     // Tồn kho server có thể đã đổi; bỏ hoặc giảm số lượng giỏ không còn hợp lệ.
  87 |     for (final id in app.cart.keys.toList()) {
  88 |       final p = app.products.where((p) => p.id == id).firstOrNull;
  89 |       if (p == null || !p.active || p.stock == 0) {
  90 |         app.cart.remove(id);
  91 |       } else if (app.cart[id]! > p.stock) {
  92 |         app.cart[id] = p.stock;
  93 |       }
  94 |     }
  95 |   }
```

| Dòng source | Giải thích chi tiết |
| --- | --- |
| 70 | Method bất đồng bộ cập nhật catalog trong AppState, không trả một List riêng cho UI. |
| 71 | Chú thích của source: Mỗi lần tải có số thứ tự. Chỉ kết quả mới nhất được ghi vào products. Không phải câu lệnh thực thi. |
| 72 | Tăng số thứ tự lần tải trước khi gọi mạng; giữ số của riêng lời gọi này. |
| 73 | Xem tài khoản có phải cửa hàng để chọn endpoint có đúng phạm vi dữ liệu. |
| 74 | Cửa hàng đọc catalog riêng qua endpoint được xác thực và ràng buộc chi nhánh. |
| 75 | Khách đọc sản phẩm công khai theo ID chi nhánh đã chọn; nơi gọi phải bảo đảm selected tồn tại. |
| 76 | Chuẩn bị List model mới, chưa xóa List đang hiển thị khi request còn chưa xong. |
| 77 | Chờ API trả JSON array rồi lặp từng object sản phẩm. |
| 78 | Chuyển mỗi JSON object thành Product của app. |
| 79 | Xác nhận mỗi phần tử là object có khóa chuỗi trước khi parse. |
| 80 | Kết thúc parser cho một phần tử; kết quả được thêm vào collection đang tạo. |
| 81 | Hoàn thành List loaded sau khi toàn bộ response đã được parse. |
| 82 | Nếu đã có lần tải mới/phiên mới vô hiệu hóa số thứ tự, bỏ response cũ để tránh ghi đè catalog mới. |
| 83 | Chọn đúng List products dùng chung mà UI/state đang giữ. |
| 84 | Cascade xóa nội dung cũ sau khi biết response hợp lệ và còn mới. |
| 85 | Thêm model mới vào cùng List, không để lại sản phẩm cũ ngoài response. |
| 86 | Chú thích của source: Tồn kho server có thể đã đổi; bỏ hoặc giảm số lượng giỏ không còn hợp lệ. Không phải câu lệnh thực thi. |
| 87 | Chụp danh sách khóa trước khi lặp, để có thể remove khỏi Map cart bên trong mà không sửa collection đang duyệt. |
| 88 | Tìm Product mới tương ứng từng mục trong giỏ; không tìm thấy thì p là null. |
| 89 | Mục đã biến mất, ngừng bán hoặc hết tồn không thể giữ nguyên trong giỏ. |
| 90 | Bỏ mục đó khỏi lựa chọn đang đặt của khách. |
| 91 | Nếu còn bán nhưng số khách chọn lớn hơn tồn mới, chuyển sang nhánh giảm số lượng. |
| 92 | Giới hạn số đang chọn bằng tồn server vừa trả; backend vẫn kiểm tra lại khi checkout. |
| 93 | Đóng nhánh điều chỉnh số lượng mục hiện tại. |
| 94 | Đóng vòng lặp đồng bộ giỏ theo catalog mới. |
| 95 | Đóng loadProducts; refresh/hiển thị lỗi do luồng gọi nó phối hợp. |

## 9. App gửi yêu cầu tạo đơn

File: [`mobile/lib/services/state/cart_order_actions.dart`](../../mobile/lib/services/state/cart_order_actions.dart). Dòng 25–58.

**Đầu vào và trách nhiệm:** Nhận người nhận, điện thoại, địa chỉ và tọa độ đã xác nhận từ form. Giỏ chứa productId → quantity.

**Kết quả và nhánh lỗi:** Server thành công thì parse đơn, xóa giỏ và tải dữ liệu lại. Nếu request ném lỗi trước đó, chưa chạy dòng clear giỏ.

Các số đầu dòng dưới đây là số dòng file, không phải một phần cú pháp cần chép vào IDE.

```text
  25 |   Future<ShopOrder> checkout(
  26 |     String name,
  27 |     String phone,
  28 |     String address,
  29 |     double latitude,
  30 |     double longitude,
  31 |   ) async {
  32 |     if (app.selected == null || app.cart.isEmpty) {
  33 |       throw StateError('Giỏ hàng trống');
  34 |     }
  35 |     // Chỉ gửi mã sản phẩm và số lượng. Backend tự chốt giá và giữ tồn kho.
  36 |     final data = await app.api.request(
  37 |       '/customer/orders',
  38 |       body: {
  39 |         'storeId': app.selected!.id,
  40 |         'recipient': name,
  41 |         'phone': phone,
  42 |         'address': address,
  43 |         'latitude': latitude,
  44 |         'longitude': longitude,
  45 |         'pinConfirmed': true,
  46 |         'items': [
  47 |           for (final e in app.cart.entries)
  48 |             {'productId': e.key, 'quantity': e.value}
  49 |         ]
  50 |       },
  51 |     );
  52 |     final o = orderFromJson(
  53 |       data as Map<String, dynamic>,
  54 |     );
  55 |     app.cart.clear();
  56 |     await app.reload();
  57 |     return o;
  58 |   }
```

| Dòng source | Giải thích chi tiết |
| --- | --- |
| 25 | Method bất đồng bộ trả đúng ShopOrder server tạo, không tự tạo ID đơn ở điện thoại. |
| 26 | Tên người nhận do form cung cấp. |
| 27 | Số điện thoại liên hệ người nhận. |
| 28 | Địa chỉ chi tiết đã nhập/xác nhận. |
| 29 | Vĩ độ điểm giao. |
| 30 | Kinh độ điểm giao; khác vị trí tham số theo thứ tự GeoJSON ở OSRM. |
| 31 | Mở thân checkout có các bước chờ HTTP và tải lại. |
| 32 | Không cho tạo đơn khi chưa chọn chi nhánh hoặc giỏ rỗng. |
| 33 | Dừng trước khi gọi mạng, để UI báo lỗi có nghĩa. |
| 34 | Kết thúc chặn đầu vào giỏ trống. |
| 35 | Chú thích của source: Chỉ gửi mã sản phẩm và số lượng. Backend tự chốt giá và giữ tồn kho. Không phải câu lệnh thực thi. |
| 36 | Chờ backend tạo đơn; method mặc định sẽ là POST vì có body. |
| 37 | Endpoint thuộc quyền khách hàng; backend có kiểm tra xác thực và nghiệp vụ. |
| 38 | Mở JSON object dữ liệu checkout. |
| 39 | Chỉ chi nhánh của giỏ đang chọn; dấu ! an toàn theo điều kiện đã kiểm tra trước đó trong luồng này. |
| 40 | Ghi tên người nhận vào payload. |
| 41 | Ghi số điện thoại cần để liên hệ giao hàng. |
| 42 | Gửi địa chỉ người dùng xác nhận; không chỉ gửi một gợi ý geocoding mơ hồ. |
| 43 | Gửi vĩ độ để backend kiểm tra tuyến và lưu điểm giao. |
| 44 | Gửi kinh độ tương ứng. |
| 45 | Khai báo form đã đi qua bước xác nhận ghim; đây không tự chứng minh vị trí GPS vật lý. |
| 46 | Tạo mảng các dòng yêu cầu đặt hàng. |
| 47 | Duyệt từng cặp mã sản phẩm và số lượng trong Map giỏ. |
| 48 | Chỉ gửi ID/số lượng; không gửi giá tự khai để backend tin theo. |
| 49 | Đóng mảng items. |
| 50 | Đóng JSON object checkout và named argument body. |
| 51 | Đóng request; khi await thành công data là response đã JSON decode. |
| 52 | Chuyển dữ liệu đơn server về model ShopOrder. |
| 53 | Xác nhận response tạo đơn là JSON object. |
| 54 | Hoàn thành parse đơn, bao gồm snapshot/trạng thái/phí mà server trả. |
| 55 | Chỉ xóa giỏ sau khi nhận và parse đơn thành công; không giữ lựa chọn để vô ý đặt lại cùng giỏ. |
| 56 | Tải lại sản phẩm/đơn theo vai trò để UI theo trạng thái server mới nhất. |
| 57 | Trả đơn vừa tạo cho màn hình tiếp theo như chi tiết/hóa đơn. |
| 58 | Đóng checkout; Future có thể lỗi nếu bất kỳ bước await/parse ném exception. |

## 10. Backend kiểm tra đăng nhập email

File: [`backend/src/main/java/com/cstore/app/controller/AuthController.java`](../../backend/src/main/java/com/cstore/app/controller/AuthController.java). Dòng 66–81.

**Đầu vào và trách nhiệm:** Spring đọc JSON thành Login DTO và chạy validation. Method nhận đối tượng hợp lệ qua POST /api/auth/login.

**Kết quả và nhánh lỗi:** Không có user hoặc sai mật khẩu trả 401. Đúng mật khẩu chuyển sang AccountService.session để kiểm tra trạng thái và cấp JWT.

Các số đầu dòng dưới đây là số dòng file, không phải một phần cú pháp cần chép vào IDE.

```text
  66 |   @PostMapping("/auth/login")
  67 |   @Transactional(readOnly = true)
  68 |   public Session login(@Valid @RequestBody Login input) {
  69 |     AppUser user =
  70 |         users
  71 |             .findByEmailIgnoreCase(input.email().trim())
  72 |             .orElseThrow(() ->
  73 |                 new ResponseStatusException(
  74 |                     HttpStatus.UNAUTHORIZED, "Email hoặc mật khẩu không đúng"));
  75 |     if (user.passwordHash == null
  76 |         || user.passwordHash.startsWith("!")
  77 |         || !passwords.matches(input.password(), user.passwordHash)) {
  78 |       throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Email hoặc mật khẩu không đúng");
  79 |     }
  80 |     return accounts.session(user);
  81 |   }
```

| Dòng source | Giải thích chi tiết |
| --- | --- |
| 66 | Ghép với tiền tố /api của controller để nhận POST /api/auth/login. |
| 67 | Đặt ranh giới transaction đọc cho luồng này; không đăng ký hay sửa mật khẩu trong method login. |
| 68 | Spring parse body JSON thành Login, kiểm tra constraint và gọi method; kết quả là DTO Session. |
| 69 | Khai báo biến entity tài khoản sẽ nhận kết quả truy vấn. |
| 70 | Dùng repository Users được inject vào controller. |
| 71 | Tìm email không phân biệt hoa/thường sau khi bỏ khoảng trắng đầu/cuối. |
| 72 | Nếu Optional không có tài khoản, tạo lỗi ở nhánh thiếu thay vì để user null chạy tiếp. |
| 73 | Tạo exception có mã HTTP và lý do để tầng xử lý lỗi chuyển thành response. |
| 74 | Chọn 401 và thông báo chung, không tiết lộ riêng email nào tồn tại. |
| 75 | Bắt đầu điều kiện từ chối khi tài khoản không có password hash. |
| 76 | Từ chối dấu hiệu tài khoản chỉ đăng nhập social, không cố kiểm tra chuỗi đánh dấu bằng BCrypt. |
| 77 | Dùng PasswordEncoder so mật khẩu nhập với hash lưu; không giải mã hash và không so trực tiếp hai chuỗi mật khẩu. |
| 78 | Bất kỳ điều kiện từ chối nào đúng thì kết thúc bằng 401, không phát token. |
| 79 | Đóng nhánh mật khẩu không hợp lệ. |
| 80 | Chuyển tài khoản đã xác minh sang service cấp phiên; service còn chặn blocked/deleted và kiểm tra chi nhánh. |
| 81 | Đóng handler; DTO thành công sẽ được Spring/Jackson serialize thành JSON. |

## 11. Backend kiểm tra trạng thái và tạo JWT

File: [`backend/src/main/java/com/cstore/app/service/AccountService.java`](../../backend/src/main/java/com/cstore/app/service/AccountService.java). Dòng 67–91.

**Đầu vào và trách nhiệm:** Đầu vào là AppUser đã tìm/xác minh theo luồng email hoặc social. Service không tin chỉ có đúng mật khẩu là mọi tài khoản đều được vào.

**Kết quả và nhánh lỗi:** Trả Session chứa JWT đã ký và DTO account an toàn. Không xuất passwordHash trong response account.

Các số đầu dòng dưới đây là số dòng file, không phải một phần cú pháp cần chép vào IDE.

```text
  67 |   public Session session(AppUser user) {
  68 |     if (user.blocked || user.deleted) {
  69 |       throw new ResponseStatusException(
  70 |           HttpStatus.FORBIDDEN, "Tài khoản đã bị khóa hoặc xóa. Vui lòng liên hệ quản trị viên.");
  71 |     }
  72 |     if ((user.role == Role.STORE || user.role == Role.MERCHANT)
  73 |         && user.assignedStore != null
  74 |         && !user.assignedStore.isActive()) {
  75 |       throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chi nhánh đã ngừng hoạt động.");
  76 |     }
  77 |     // Token có hạn 8 giờ; ver giúp vô hiệu hóa token cũ sau khi đổi mật khẩu.
  78 |     var now = Instant.now();
  79 |     var claims =
  80 |         JwtClaimsSet.builder()
  81 |             .subject(user.email)
  82 |             .issuedAt(now)
  83 |             .expiresAt(now.plusSeconds(28800))
  84 |             .claim("role", user.role.name())
  85 |             .claim("ver", user.version())
  86 |             .build();
  87 |     String token =
  88 |         jwt.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims))
  89 |             .getTokenValue();
  90 |     return new Session(token, account(user));
  91 |   }
```

| Dòng source | Giải thích chi tiết |
| --- | --- |
| 67 | Method nghiệp vụ tạo phiên cho một entity tài khoản. |
| 68 | Chặn tài khoản bị khóa hoặc đã xóa trước khi tạo JWT mới. |
| 69 | Tạo lỗi HTTP để caller ngừng quá trình đăng nhập. |
| 70 | Chọn 403 kèm thông báo giới hạn tài khoản, khác với 401 sai mật khẩu. |
| 71 | Đóng kiểm tra trạng thái tài khoản. |
| 72 | Áp dụng kiểm tra chi nhánh cho cả role cửa hàng hiện tại và role tương thích cũ. |
| 73 | Chỉ truy cập chi nhánh được gán khi quan hệ này tồn tại. |
| 74 | Nếu chi nhánh được gán đã ngừng hoạt động, không cho tạo phiên sử dụng cửa hàng đó. |
| 75 | Dừng bằng 403 khi điều kiện chi nhánh thất bại. |
| 76 | Đóng điều kiện cửa hàng bị ngừng hoạt động. |
| 77 | Chú thích của source: Token có hạn 8 giờ; ver giúp vô hiệu hóa token cũ sau khi đổi mật khẩu. Không phải câu lệnh thực thi. |
| 78 | Chụp thời điểm hiện tại một lần để issuedAt và expiresAt dùng cùng mốc. |
| 79 | Chuẩn bị tập claim sẽ đặt trong JWT. |
| 80 | Khởi tạo builder của Spring Security cho payload JWT. |
| 81 | Ghi email làm subject; decoder của dự án tra tài khoản theo subject này. |
| 82 | Ghi thời điểm phát hành token. |
| 83 | Đặt hạn tám giờ sau mốc phát hành, không phải một phiên vô thời hạn. |
| 84 | Ghi role từ entity DB, không lấy role tự khai của form login. |
| 85 | Ghi phiên bản để decoder đối chiếu và vô hiệu hóa JWT cũ khi version trong DB thay đổi. |
| 86 | Hoàn thành tập claim; bước này chưa ký và chưa tạo chuỗi JWT. |
| 87 | Biến local nhận token đã được encoder ký. |
| 88 | Chọn header HS256 cùng claims rồi giao JwtEncoder đã cấu hình khóa ký thực hiện. |
| 89 | Lấy chuỗi JWT từ kết quả encode, không in giá trị ra log. |
| 90 | Tạo DTO response có token và hồ sơ được chọn trường an toàn qua account(user). |
| 91 | Đóng cấp phiên; kiểm tra quyền cho các request sau vẫn do filter/service thực hiện. |

## 12. Backend tạo đơn và trừ tồn trong transaction

File: [`backend/src/main/java/com/cstore/app/controller/OrderController.java`](../../backend/src/main/java/com/cstore/app/controller/OrderController.java). Dòng 64–114.

**Đầu vào và trách nhiệm:** Nhận Authentication do Security tạo và OrderInput đã validation. Phía app chỉ gửi ID/số lượng; backend tự đọc giá và tính phí.

**Kết quả và nhánh lỗi:** Thành công lưu đơn/snapshot/lịch sử và giảm tồn trong cùng giao dịch. Lỗi trạng thái, dữ liệu hoặc tranh tồn ném exception; không trả đơn thành công giả.

Các số đầu dòng dưới đây là số dòng file, không phải một phần cú pháp cần chép vào IDE.

```text
  64 |   @PostMapping("/customer/orders")
  65 |   @Transactional
  66 |   public OrderView checkout(Authentication authentication, @Valid @RequestBody OrderInput input) {
  67 |     var store =
  68 |         stores
  69 |             .findById(input.storeId())
  70 |             .filter(Store::isActive)
  71 |             .orElseThrow(() -> bad("Cửa hàng đã ngừng hoạt động hoặc không tồn tại"));
  72 |     if (store.latitude == null || store.longitude == null) {
  73 |       throw bad("Chi nhánh chưa ghim vị trí");
  74 |     }
  75 |     // Phí lấy từ tuyến đường thực tế trước khi bắt đầu trừ tồn kho.
  76 |     var quote = delivery.quote(store, input.latitude(), input.longitude());
  77 |     double km = quote.distanceKm();
  78 |     var buyer = support.current(authentication);
  79 |     buyer.deliveryAddress = input.address().trim();
  80 |     buyer.deliveryLatitude = input.latitude();
  81 |     buyer.deliveryLongitude = input.longitude();
  82 |     var order = new CustomerOrder(buyer, store);
  83 |     order.recipient = input.recipient().trim();
  84 |     order.phone = input.phone();
  85 |     order.address = input.address().trim();
  86 |     order.latitude = input.latitude();
  87 |     order.longitude = input.longitude();
  88 |     order.distanceKm = km;
  89 |     order.durationSeconds = quote.durationSeconds();
  90 |     order.distanceSource = "ROAD";
  91 |     order.fee = quote.fee();
  92 |     Set<Long> seen = new HashSet<>();
  93 |     // Khóa sản phẩm theo cùng thứ tự ID để hai giỏ hàng không chờ khóa chéo nhau.
  94 |     // Mọi thay đổi tồn kho và dòng đơn đều nằm trong giao dịch @Transactional này.
  95 |     for (var item :
  96 |         input.items().stream().sorted(Comparator.comparing(OrderItemInput::productId)).toList()) {
  97 |       if (!seen.add(item.productId())) {
  98 |         throw bad("Sản phẩm bị trùng");
  99 |       }
 100 |       var product =
 101 |           products.locked(item.productId()).orElseThrow(() -> bad("Sản phẩm không tồn tại"));
 102 |       if (!product.store.id.equals(store.id) || !product.active) {
 103 |         throw bad("Sản phẩm không thuộc chi nhánh hoặc ngừng bán");
 104 |       }
 105 |       if (product.stock < item.quantity()) {
 106 |         throw new ResponseStatusException(HttpStatus.CONFLICT, "Không đủ tồn kho: " + product.name);
 107 |       }
 108 |       product.stock -= item.quantity();
 109 |       order.lines.add(new OrderLine(order, product, item.quantity(), product.price));
 110 |       order.total = order.total.add(product.price.multiply(BigDecimal.valueOf(item.quantity())));
 111 |     }
 112 |     order.history.add(new StatusEvent("PENDING"));
 113 |     return view(orders.save(order));
 114 |   }
```

| Dòng source | Giải thích chi tiết |
| --- | --- |
| 64 | Ghép với /api để nhận POST tạo đơn của khách hàng. |
| 65 | Cho các thay đổi DB trong checkout cùng ranh giới commit/rollback; phí đường bộ không phải phép tính của mobile. |
| 66 | Nhận danh tính đã xác thực và JSON đã validation; kiểu trả về chỉ là DTO view của đơn. |
| 67 | Biến sẽ nhận chi nhánh hợp lệ để toàn bộ đơn thuộc đúng một nơi bán. |
| 68 | Repository truy cập các chi nhánh. |
| 69 | Tìm theo storeId khách gửi, không lấy một chi nhánh mặc định bất kỳ. |
| 70 | Loại chi nhánh không hoạt động ngay cả khi ID vẫn còn trong database. |
| 71 | Không tìm được chi nhánh hợp lệ thì dừng bằng lỗi 400 của helper. |
| 72 | Kiểm tra chi nhánh có điểm định vị trước khi tính tuyến giao. |
| 73 | Không có tọa độ hợp lệ để định tuyến thì không tạo đơn tiếp. |
| 74 | Đóng kiểm tra vị trí chi nhánh. |
| 75 | Chú thích của source: Phí lấy từ tuyến đường thực tế trước khi bắt đầu trừ tồn kho. Không phải câu lệnh thực thi. |
| 76 | Gọi service báo phí/tuyến đường từ chi nhánh đến tọa độ khách; lỗi định tuyến sẽ dừng trước khi giảm tồn. |
| 77 | Lấy khoảng cách đường bộ của báo giá để lưu cùng đơn. |
| 78 | Xác định khách thực từ phiên đã xác thực, không từ customerId tự gửi trong JSON. |
| 79 | Ghi lại địa chỉ giao đã xác nhận vào hồ sơ vị trí của khách trong giao dịch. |
| 80 | Lưu vĩ độ điểm giao vào entity khách. |
| 81 | Lưu kinh độ cùng điểm giao đó. |
| 82 | Tạo entity đơn gắn với khách/chi nhánh đã xác định; chưa gọi repository.save tại đây. |
| 83 | Lưu tên người nhận và loại khoảng trắng thừa đầu/cuối. |
| 84 | Lưu số liên hệ của đơn, để về sau thay hồ sơ không làm mất thông tin snapshot đơn. |
| 85 | Lưu địa chỉ trên chính đơn, tách với địa chỉ khách có thể sửa cho lần sau. |
| 86 | Lưu vĩ độ điểm giao của đơn này. |
| 87 | Lưu kinh độ điểm giao của đơn này. |
| 88 | Ghi khoảng cách quote vào đơn để response/thống kê dùng đúng dữ liệu đã chốt. |
| 89 | Lưu thời gian dự kiến do tuyến đường trả về. |
| 90 | Đánh dấu đây là khoảng cách đường bộ, không gọi Haversine là phí định tuyến thật. |
| 91 | Ghi phí do backend tính; không tin một số fee tự khai từ app. |
| 92 | Tạo tập ID đã gặp để phát hiện một sản phẩm lặp lại trong payload checkout. |
| 93 | Chú thích của source: Khóa sản phẩm theo cùng thứ tự ID để hai giỏ hàng không chờ khóa chéo nhau. Không phải câu lệnh thực thi. |
| 94 | Chú thích của source: Mọi thay đổi tồn kho và dòng đơn đều nằm trong giao dịch @Transactional này. Không phải câu lệnh thực thi. |
| 95 | Bắt đầu duyệt các dòng yêu cầu, mỗi lượt là một OrderItemInput. |
| 96 | Sắp theo productId trước khi khóa, giúp các checkout lấy khóa cùng thứ tự và giảm nguy cơ chờ chéo. |
| 97 | add trả false khi ID đã có; phủ định cho biết payload chứa sản phẩm trùng. |
| 98 | Dừng cả đơn thay vì cộng/trừ tồn mơ hồ hai lần cùng một ID. |
| 99 | Đóng kiểm tra dòng trùng. |
| 100 | Biến giữ entity sản phẩm sau khi repository lấy khóa. |
| 101 | Lấy bản ghi với khóa ghi để các giao dịch tranh tồn phải phối hợp; không có ID thì dừng. |
| 102 | Bảo đảm sản phẩm thuộc đúng chi nhánh của giỏ và vẫn được bán. |
| 103 | Chặn payload ghép sản phẩm chi nhánh khác hoặc mặt hàng ngừng bán. |
| 104 | Đóng kiểm tra phạm vi sản phẩm. |
| 105 | Kiểm tra tồn thật sau khi lấy khóa, không dựa vào tồn app đã tải trước đó. |
| 106 | Trả 409 khi đơn này không còn đủ hàng; transaction không được commit như một checkout thành công. |
| 107 | Đóng kiểm tra đủ tồn. |
| 108 | Giảm tồn trên entity đang được transaction/JPA quản lý. |
| 109 | Thêm dòng snapshot gắn với đơn, dùng số lượng yêu cầu và giá hiện tại đọc từ database. |
| 110 | Cộng tiền hàng bằng BigDecimal theo giá DB nhân số lượng; tổng này được lưu tách với trường fee. |
| 111 | Kết thúc xử lý toàn bộ dòng hàng sau kiểm tra/giảm tồn/snapshot. |
| 112 | Ghi lịch sử ban đầu để việc tạo đơn có dấu mốc trạng thái rõ ràng. |
| 113 | Lưu entity rồi chuyển thành DTO response; việc commit còn do cơ chế transaction quanh method hoàn tất. |
| 114 | Đóng checkout; các HTTP/API ngoài và file không tự có rollback giống dữ liệu MySQL chỉ vì nằm trong giao dịch. |

## 13. Repository khóa bản ghi sản phẩm

File: [`backend/src/main/java/com/cstore/app/repository/Products.java`](../../backend/src/main/java/com/cstore/app/repository/Products.java). Dòng 15–17.

**Đầu vào và trách nhiệm:** Checkout gọi products.locked(id) bên trong transaction. Đây là khai báo repository, Spring Data tạo phần thực thi.

**Kết quả và nhánh lỗi:** Trả Optional<Product> với cơ chế pessimistic write lock khi có bản ghi; caller xử lý trường hợp không tồn tại.

Các số đầu dòng dưới đây là số dòng file, không phải một phần cú pháp cần chép vào IDE.

```text
  15 |   @Lock(LockModeType.PESSIMISTIC_WRITE)
  16 |   @Query("select p from Product p where p.id = :id")
  17 |   public Optional<Product> locked(Long id);
```

| Dòng source | Giải thích chi tiết |
| --- | --- |
| 15 | Yêu cầu khóa ghi theo khả năng DB/JPA cho truy vấn này; các transaction tranh cùng bản ghi phải chờ/phối hợp. |
| 16 | JPQL truy vấn entity Product, đặt alias p và bind tham số id; đây không phải tên bảng SQL được ghép chuỗi từ input. |
| 17 | Interface không viết thân hàm; Spring Data hiện thực. Optional buộc caller nghĩ tới trường hợp không có sản phẩm. |

## 14. Java khởi động toàn bộ Spring Boot

File: [`backend/src/main/java/com/cstore/app/CStoreApplication.java`](../../backend/src/main/java/com/cstore/app/CStoreApplication.java). Dòng 1–11.

**Đầu vào và trách nhiệm:** JVM chạy main của JAR. Package ứng dụng là gốc để Spring tìm các class đã chia theo controller/service/repository/entity/dto/config/security.

**Kết quả và nhánh lỗi:** Application context được tạo, cấu hình và bean được nạp, web server bắt đầu lắng nghe; lỗi cấu hình/kết nối có thể khiến khởi động dừng.

Các số đầu dòng dưới đây là số dòng file, không phải một phần cú pháp cần chép vào IDE.

```text
   1 | package com.cstore.app;
   2 | 
   3 | import org.springframework.boot.SpringApplication;
   4 | import org.springframework.boot.autoconfigure.SpringBootApplication;
   5 | 
   6 | @SpringBootApplication
   7 | public class CStoreApplication {
   8 |   public static void main(String[] args) {
   9 |     SpringApplication.run(CStoreApplication.class, args);
  10 |   }
  11 | }
```

| Dòng source | Giải thích chi tiết |
| --- | --- |
| 1 | Đặt namespace gốc của backend; các package con nằm dưới vùng tìm kiếm ứng dụng. |
| 2 | Dòng trống phân tách các nhóm câu lệnh; không tạo hành động khi chạy. |
| 3 | Nạp class có hàm run dùng để khởi tạo Spring Boot. |
| 4 | Nạp annotation cấu hình điểm bắt đầu ứng dụng. |
| 5 | Dòng trống phân tách các nhóm câu lệnh; không tạo hành động khi chạy. |
| 6 | Bật nhóm cơ chế cấu hình/tìm component của Spring Boot từ package ứng dụng; không phải một phép gọi tuần tự trong main. |
| 7 | Định nghĩa class công khai chứa entry point Java của backend. |
| 8 | JVM gọi main mà không cần tạo instance; args là tham số dòng lệnh truyền cho JAR. |
| 9 | Tạo application context theo class gốc và args; Spring nối dependency, cấu hình persistence/security/web theo source. |
| 10 | Đóng main; server tiếp tục hoạt động trên các thành phần và thread đã được Spring khởi động. |
| 11 | Đóng class entry point; nghiệp vụ không được gom vào file khởi động này. |

## Phạm vi đã chú giải

- 14 đoạn source thuộc các luồng khởi động, phân vai, đăng nhập, giao tiếp HTTP, tải catalog, đặt đơn và khóa tồn kho.
- 291 dòng source được trích, gồm 273 dòng code/annotation/cú pháp có ghi chú riêng; comment và dòng trống cũng được đối chiếu trong bảng.
- Số dòng được tính lại từ source mỗi lần chạy generator. Các file ngoài danh sách cần đọc theo bản đồ source và chương chuyên đề; không coi một giải thích ở đây là thay thế cho kiểm thử.
