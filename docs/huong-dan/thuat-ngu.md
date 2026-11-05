# Từ điển đọc code C-Store

Đây là bảng tra cứu cho các từ và ký hiệu xuất hiện trong source. Không cần học thuộc toàn bộ trước khi chạy app. Khi gặp từ mới trong một luồng, tìm phần tương ứng rồi quay lại source.

## 1. Từ vựng nền tảng

| Từ | Hiểu ngắn gọn | Ví dụ trong dự án |
| --- | --- | --- |
| Source code | Mã do người phát triển đọc/sửa | `.java`, `.dart`, script, cấu hình |
| Runtime | Môi trường thực thi chương trình | JVM của backend; Dart/Flutter runtime của app |
| Compile/biên dịch | Chuyển source sang dạng có thể thực thi | Maven biên dịch Java; Flutter biên dịch Dart cho bản Android |
| Build | Chuỗi công việc tạo ứng dụng/artifact | Đóng JAR hoặc tạo APK |
| Artifact | Kết quả sinh ra từ build | JAR, APK; không phải nơi chỉnh logic |
| Dependency | Thư viện/công cụ mà dự án dựa vào | Spring Web, `http`, `flutter_map` |
| Framework | Khung có quy tắc/vòng đời để viết ứng dụng | Spring Boot, Flutter |
| Library | Thư viện cung cấp API dùng trong code | Jackson, `latlong2` |
| SDK | Bộ công cụ phát triển | Flutter SDK, Android SDK, JDK |
| CLI | Chương trình điều khiển bằng terminal | `flutter`, `mvn`, `adb` |
| PATH | Danh sách thư mục shell tìm chương trình | `command -v flutter` cho biết file được chọn |
| Working directory/cwd | Thư mục hiện tại của một tiến trình | Maven chạy trong `backend/`, Flutter trong `mobile/` |
| Package | Nhóm tên/code hoặc gói dependency, tùy ngữ cảnh | Java package `...controller`; Dart package `http` |
| Module | Một phần được tổ chức có trách nhiệm rõ | Nhóm chức năng đơn hàng; không mặc nhiên là một server riêng |
| Refactor | Đổi cách tổ chức code và giữ hành vi mong muốn | Tách controller lớn thành các nhóm chức năng |
| Boilerplate | Code lặp theo cấu trúc công cụ/ngôn ngữ | Import, constructor, phần bao widget |
| Contract | Quy ước mà phần khác đang phụ thuộc | Tên endpoint, trường JSON, kiểu trả về, đường dẫn import |
| Side effect | Thay đổi bên ngoài phép tính trả kết quả | Ghi DB, upload file, gửi HTTP, thay state |
| Pure function | Hàm chỉ tính từ đầu vào, không thay bên ngoài | Hàm định dạng tiền nếu không đọc/ghi state |
| Scope | Phạm vi một tên/biến có thể dùng | Biến local trong method khác field của class |

## 2. Dữ liệu nghiệp vụ

| Từ/tên | Ý nghĩa trong C-Store |
| --- | --- |
| Account/AppUser | Tài khoản nội bộ, có email, tên, role và các thông tin hồ sơ |
| Role | Vai trò quyết định nhóm chức năng: khách, cửa hàng, shipper, admin |
| Customer | Người mua hàng |
| Store/Merchant | Tài khoản quản lý bán hàng tại chi nhánh; backend có tên tương thích MERCHANT |
| Shipper | Người nhận/giao đơn |
| Admin | Người quản trị tài khoản, thương hiệu/chi nhánh và thống kê |
| Brand/thương hiệu | Nhóm nhận diện chung của các chi nhánh; xem source để hiểu cách nhóm tên |
| Branch/chi nhánh | Một địa điểm bán có ID, địa chỉ và tọa độ riêng |
| Product | Sản phẩm thuộc chi nhánh, có tên, giá, tồn và ảnh |
| Stock | Số lượng còn có thể bán theo dữ liệu backend |
| Cart | Lựa chọn sản phẩm/số lượng người mua đang chuẩn bị đặt |
| Checkout | Kiểm tra giỏ/địa điểm và gửi yêu cầu tạo đơn |
| Order | Đơn hàng đã được backend tạo và lưu |
| Order line/item | Một dòng sản phẩm trong đơn, có số lượng và giá snapshot |
| Snapshot | Bản ghi dữ liệu tại thời điểm đó; sửa giá sản phẩm sau này không tự đổi giá đã chốt trong đơn |
| Subtotal | Tiền hàng: tổng giá đơn vị nhân số lượng |
| Delivery fee | Phí giao, tính từ kết quả tuyến đường và quy tắc backend |
| Total | Tiền hàng cộng phí giao theo cấu trúc đơn |
| COD | Thu tiền khi giao hàng; ghi nhận thu tiền trong hệ thống không phải cổng thanh toán online |
| Commission/platform fee | Phần phí nền tảng; source thống kê dùng 15% tiền hàng đủ điều kiện |
| Revenue/doanh thu | Phải đọc đúng điều kiện thống kê, ví dụ đã giao và đã thanh toán; không phải mọi đơn vừa tạo |
| Offer | Đơn phù hợp để shipper có thể đề nghị nhận |
| Claim | Shipper nhận quyền giao một đơn, có kiểm tra tranh chấp |
| Active/archived/deleted | Các trạng thái hoạt động/lưu lịch sử/xóa theo nghiệp vụ; không phải lúc nào cũng DELETE hàng DB |
| Store owner/staff | Phân biệt người phụ trách chính và nhân viên theo trường/quy tắc của source |
| Pin confirmed | Người dùng đã xác nhận điểm ghim; khác với tự lấy được một tọa độ GPS |

## 3. Trạng thái đơn hàng

Tên enum giúp code kiểm tra điều kiện rõ ràng hơn dùng chuỗi tiếng Việt tự do.

| API/backend | Dart | Nhãn/ý nghĩa |
| --- | --- | --- |
| `PENDING` | `pending` | Chờ cửa hàng xác nhận |
| `ACCEPTED` | `accepted` | Cửa hàng chấp nhận; chờ shipper |
| `ASSIGNED` | `assigned` | Shipper đã nhận giao |
| `PICKED_UP` | `pickedUp` | Đã lấy hàng |
| `DELIVERING` | `delivering` | Đang giao tới khách |
| `DELIVERED` | `delivered` | Đã giao theo điều kiện backend |
| `REJECTED` | `rejected` | Bị cửa hàng từ chối |
| `CANCELLED` | `cancelled` | Đã hủy theo điều kiện cho phép |

Không phải cứ gửi bất kỳ trạng thái nào backend cũng chấp nhận. Source kiểm tra trạng thái cũ, người gọi, quyền sở hữu và điều kiện thu tiền. Tình trạng thanh toán còn được lưu riêng; không suy ra một enum đơn lẻ thay được mọi điều kiện tài chính.

## 4. Class, kiểu dữ liệu và cú pháp Dart

| Cú pháp | Giải thích |
| --- | --- |
| `class Product { ... }` | Định nghĩa một kiểu đối tượng có dữ liệu/hành vi |
| `Product(...)` | Constructor tạo đối tượng Product |
| `final int id;` | Field số nguyên chỉ được gán một lần cho đối tượng đó |
| `const` | Giá trị/constructor có thể dùng ở ngữ cảnh hằng compile-time |
| `static` | Thành viên thuộc class, không cần mỗi instance có một bản field riêng |
| `late final` | Gán một lần nhưng hoãn khởi tạo; đọc trước khi gán có thể lỗi |
| `var value = ...` | Dart suy ra kiểu từ biểu thức khởi tạo; không mặc nhiên là `dynamic` |
| `dynamic` | Cho phép truy cập động; nhiều lỗi kiểu chỉ lộ ra khi chạy |
| `Object` | Kiểu gốc chung của các đối tượng Dart không null |
| `String?` | Chuỗi hoặc null |
| `value != null` | Kiểm tra có giá trị trước khi dùng |
| `value!` | Khẳng định khác null; có thể lỗi nếu khẳng định sai |
| `account?.name` | Chỉ đọc `name` khi `account` khác null; nếu null trả null |
| `name ?? 'Bạn'` | Dùng `name` nếu khác null, còn lại dùng chuỗi dự phòng |
| `field ??= value` | Chỉ gán nếu field hiện là null |
| `condition ? a : b` | Chọn biểu thức a hoặc b theo điều kiện |
| `=> expression` | Viết ngắn một hàm/getter chỉ trả về biểu thức |
| `{required this.state}` | Named parameter bắt buộc; gán trực tiếp vào field `state` |
| `{this.size = 52}` | Named parameter tùy chọn có giá trị mặc định |
| `[String? subtitle]` | Positional parameter tùy chọn |
| `_client` | Tên bắt đầu bằng `_` là private theo Dart library |
| `get subtotal => ...` | Getter; dùng như field nhưng kết quả được tính bởi code |
| `set ...` | Setter; phần xử lý khi gán thuộc tính |
| `extends` | Kế thừa class cha |
| `implements` | Cam kết hiện thực interface của kiểu khác |
| `@override` | Đánh dấu thành viên đang hiện thực/ghi đè thành viên cha |
| `factory ...fromJson` | Constructor có thể điều khiển cách tạo object từ JSON |
| `as Map<String, dynamic>` | Ép/kiểm tra kiểu khi chạy; dữ liệu sai kiểu có thể gây lỗi |
| `is Map<String, dynamic>` | Kiểm tra kiểu rồi rẽ nhánh |
| `enum` | Tập giá trị hữu hạn có tên rõ, ví dụ Role và OrderStatus |
| `switch` | Chọn nhánh theo một giá trị; có cả statement và expression |
| `throw StateError(...)` | Dừng nhánh hiện tại bằng lỗi có thông điệp |
| `rethrow` | Ném tiếp lỗi đang bắt mà giữ thông tin lỗi gốc |

### Collection và toán tử hay gặp

| Cú pháp | Nghĩa và lưu ý |
| --- | --- |
| `List<Product>` | Danh sách các Product, có thứ tự |
| `Map<int, int>` | Ánh xạ khóa số nguyên sang số nguyên, như product ID → số lượng |
| `Set<String>` | Tập chuỗi không trùng nhau |
| `<Product>[]` | Tạo List rỗng và nêu rõ kiểu phần tử |
| `<int, int>{}` | Tạo Map rỗng và nêu rõ kiểu khóa/giá trị |
| `items.where(...)` | Chọn phần tử thỏa điều kiện |
| `items.map(...)` | Chuyển từng phần tử sang dạng khác |
| `items.toList()` | Tạo List từ Iterable |
| `items.fold(0, ...)` | Tích lũy từng phần tử thành một kết quả, ví dụ tổng tiền |
| `items.firstWhere(...)` | Lấy phần tử đầu tiên thỏa điều kiện; cần hiểu nhánh không tìm thấy |
| `firstOrNull` | Lấy phần tử đầu hoặc null khi rỗng |
| `..` | Cascade: gọi/gán nhiều thành viên trên cùng đối tượng rồi vẫn trả đối tượng đó |
| `...widgets` | Spread: chèn từng phần tử collection vào collection đang tạo |
| `if (...) widget` trong list | Chỉ đưa widget vào danh sách khi điều kiện đúng |
| `for (...) widget` trong list | Sinh nhiều phần tử theo vòng lặp |
| `'Đơn #${order.id}'` | String interpolation, chèn giá trị biểu thức vào chuỗi |
| `RegExp(...)` | Biểu thức chính quy dùng tìm/kiểm tra mẫu văn bản |
| `.round()`/`.ceil()` | Làm tròn gần nhất/lên trên; phải đọc đúng cách làm tròn đang dùng |
| `.clamp(min, max)` | Giới hạn kết quả trong khoảng |

Ví dụ cascade:

```dart
final rows = <String>[]
  ..add('Đơn A')
  ..add('Đơn B');
```

Dòng đầu tạo List rỗng. Hai dòng sau cùng gọi `add` trên List đó. Biến `rows` nhận List chứa hai chuỗi; nó không nhận kết quả `void` của `add`. Cascade gọn nhưng khi học có thể đọc thành các câu lệnh tuần tự: tạo list, thêm A, thêm B.

## 5. Flutter UI và vòng đời

| Từ/tên | Tác dụng |
| --- | --- |
| Widget tree | Cây mô tả UI: mỗi widget có thể chứa các widget con |
| `build(context)` | Trả mô tả giao diện dựa trên dữ liệu hiện tại; có thể chạy nhiều lần |
| `BuildContext` | Vị trí trong cây widget để tìm theme, navigator và các dữ liệu liên quan |
| `StatefulWidget` | Cấu hình widget có một đối tượng State đi kèm |
| `State` | Nơi giữ trạng thái UI thay đổi theo vòng đời widget |
| `StatelessWidget` | Widget không tạo State riêng |
| `initState()` | Khởi tạo một lần khi State được gắn vào cây |
| `setState(...)` | Báo rằng dữ liệu UI local đã đổi và cần build lại |
| `dispose()` | Giải phóng tài nguyên do đối tượng sở hữu khi không dùng nữa |
| `mounted` | State/context còn ở trong cây để cập nhật an toàn |
| `ChangeNotifier` | Đối tượng phát thông báo thay đổi cho các listener |
| `notifyListeners()` | Gửi thông báo cho những bên đang lắng nghe |
| `ListenableBuilder` | Dựng UI lại khi Listenable phát thông báo |
| `MaterialApp` | Cấu hình gốc app Material: theme, title, home và navigation |
| `ThemeData` | Bộ màu/chữ/kiểu control dùng chung |
| `Scaffold` | Khung màn hình có appbar/body/navigation và các vùng phổ biến |
| `SafeArea` | Tránh nội dung bị đè bởi các vùng hệ thống như thanh trạng thái |
| `Row`/`Column` | Xếp con theo chiều ngang/dọc |
| `Expanded` | Yêu cầu chiếm phần không gian còn lại theo trục của Row/Column |
| `Flexible` | Cho phép con co theo phần không gian được phân bổ |
| `Padding` | Khoảng đệm quanh child |
| `SizedBox` | Tạo kích thước/khoảng trống theo constraints |
| `ListView` | Danh sách cuộn |
| `Stack`/`Positioned` | Xếp chồng và định vị các con trong vùng Stack |
| `ClipOval`/`ClipRRect` | Giới hạn vùng nhìn thấy theo hình oval/bo góc |
| `BoxFit.cover` | Phủ kín khung bằng ảnh đúng tỉ lệ, có thể cắt phần dư |
| `BoxFit.contain` | Giữ toàn bộ ảnh trong khung, có thể còn khoảng trống |
| `Form`/`GlobalKey<FormState>` | Nhóm field và truy cập trạng thái validation của form |
| `TextEditingController` | Đọc/điều khiển nội dung field; cần dispose khi chủ sở hữu kết thúc |
| `validator` | Hàm trả thông báo lỗi hoặc null nếu đầu vào hợp lệ |
| Callback | Hàm truyền cho control, ví dụ `onPressed`, `onChanged` |
| `onPressed: null` | Nút không có hành động và thường ở trạng thái disabled |
| `Navigator.push` | Mở một route/màn hình trên stack |
| `Navigator.pop` | Đóng route trên cùng, có thể trả kết quả cho nơi gọi |
| `showDialog` | Mở route dialog |
| `SnackBar` | Thông báo ngắn trong UI |
| Key/ValueKey | Danh tính giúp Flutter/test tìm hoặc phân biệt widget |
| Semantics | Thông tin hỗ trợ công cụ đọc màn hình/trợ năng |

`part`/`part of` trong Dart chia **một library** ra nhiều file; các phần vẫn chia sẻ phạm vi private `_...`. `import` đưa một library khác vào dùng; `export` cho người import file hiện tại được thấy các khai báo của library được xuất tiếp. Ba từ này không thay thế cho nhau. Tách file bằng `part` không tự tạo đối tượng State mới.

## 6. Java và Spring

| Từ/cú pháp | Ý nghĩa |
| --- | --- |
| `package ...;` | Namespace của class; đường dẫn folder nên phản ánh package |
| `import ...;` | Dùng một kiểu/tên từ package khác |
| `public` | Thành viên có thể được truy cập từ bên ngoài theo quy tắc Java |
| `private` | Chỉ dùng trực tiếp trong phạm vi class phù hợp |
| Không ghi access modifier | Package-private: truy cập trong cùng package; khác với public |
| `final` | Không gán lại biến/field sau khi đã khởi tạo; không có nghĩa đối tượng chứa bên trong bất biến hoàn toàn |
| `static` | Thành viên thuộc class |
| `record` | Kiểu mang dữ liệu có các thành phần được khai báo ở đầu; phù hợp cho nhiều DTO |
| `var` | Java suy ra kiểu biến local từ biểu thức khởi tạo |
| `Long` so với `long` | Kiểu wrapper có thể null so với kiểu nguyên thủy |
| `BigDecimal` | Số thập phân có quy tắc tính/làm tròn tường minh, phù hợp tính tiền trong backend |
| `Optional<T>` | Giá trị có thể có hoặc không, dùng thay vì giả định truy vấn luôn tìm thấy |
| `orElseThrow(...)` | Có giá trị thì lấy, không có thì tạo/ném lỗi |
| `stream()` | Chuỗi xử lý collection theo map/filter/sort/reduce… |
| `a -> ...` | Lambda: hàm truyền vào nơi cần xử lý callback/collection |
| Method reference `Type::method` | Tham chiếu trực tiếp method thay cho lambda tương ứng |
| `try` với resource | Tự đóng resource sau khối, ví dụ stream ảnh |
| Exception | Tín hiệu lỗi đi theo call stack cho đến khi được xử lý |
| Bean | Đối tượng được Spring quản lý |
| Application context | Nơi Spring giữ và kết nối các bean |
| Component scanning | Tìm class có annotation phù hợp để đăng ký bean |
| Dependency injection | Spring cung cấp dependency cho constructor/bean |
| Controller | Nhận HTTP request và xác định dữ liệu trả về |
| Service | Xử lý quy tắc nghiệp vụ và phối hợp thao tác |
| DTO | Cấu trúc dữ liệu giao tiếp vào/ra, không nhất thiết là bảng DB |
| Validation constraint | Quy tắc như `@NotBlank`, `@Email`, `@Size`, `@Min` |
| Advice/error handler | Xử lý lỗi dùng chung cho các controller |
| `ResponseEntity` | Response có status, headers và body được chỉ định rõ |

Tìm một method đang “được gọi ở đâu” không chỉ bằng các phép gọi trực tiếp. Controller có thể được Spring gọi theo mapping HTTP. Bean factory được framework gọi khi tạo context. Callback/test được công cụ gọi theo quy ước của chúng.

## 7. Database và tính nhất quán

| Từ | Giải thích |
| --- | --- |
| Entity | Kiểu Java mà JPA quản lý để lưu vào DB |
| Table/row/column | Bảng/bản ghi/cột trong database |
| Primary key | Khóa nhận diện bản ghi, thường là `id` |
| Foreign key | Liên kết bản ghi đến bảng khác |
| Unique constraint | Không cho phép trùng một khóa/nhóm trường theo quy tắc DB |
| Repository | Interface/thành phần truy cập dữ liệu |
| ORM | Ánh xạ đối tượng với dữ liệu quan hệ |
| JPA | API/quy tắc persistence Java được ứng dụng dùng |
| Hibernate | Thư viện thực thi JPA và sinh SQL trong dự án |
| JDBC | API kết nối/truy vấn database từ Java |
| Transaction | Nhóm thay đổi có ranh giới commit/rollback |
| Commit | Chấp nhận các thay đổi của giao dịch |
| Rollback | Hủy các thay đổi DB trong phạm vi giao dịch khi điều kiện rollback áp dụng |
| Row lock | Khóa bản ghi cho phối hợp các giao dịch đồng thời |
| Pessimistic lock | Chủ động giữ khóa khi truy cập theo kiểu được chỉ định |
| Optimistic version | Phát hiện dữ liệu thay đổi qua phiên bản; khác với JWT tokenVersion |
| Race condition | Kết quả phụ thuộc các tác vụ tranh nhau theo thời gian |
| Dirty checking | ORM theo dõi entity đang được quản lý để ghi các thay đổi phù hợp khi flush/commit |
| Flush | Đồng bộ thay đổi persistence context tới database; chưa đồng nghĩa commit giao dịch |
| Lazy loading | Chỉ tải quan hệ khi cần dùng theo cấu hình |
| Soft delete/archive | Đánh dấu trạng thái thay vì xóa sạch dữ liệu lịch sử |
| Migration | Script/version hóa thay đổi schema một cách có kiểm soát |
| H2 | Database dùng trong bài test backend ở bộ nhớ |
| MySQL | Database hệ thống local dùng lưu dữ liệu thật của dự án |

Việc gọi một API ngoài như OSRM không nằm trong transaction MySQL chỉ vì nó được gọi trong method có `@Transactional`. Khi học, luôn hỏi “tài nguyên nào đang được giao dịch quản lý?”.

## 8. API, bảo mật và danh tính

| Từ | Hiểu trong ngữ cảnh dự án |
| --- | --- |
| API | Giao diện để app và backend giao tiếp bằng request/response |
| Endpoint | Một cặp đường dẫn và HTTP method phục vụ chức năng |
| REST | Cách tổ chức API theo tài nguyên và HTTP; source cũng có endpoint hành động như claim/payment |
| Header | Metadata của HTTP request/response |
| Body | Nội dung chính của HTTP request/response |
| JSON | Định dạng văn bản chứa object/list/string/number/boolean/null |
| Serialize | Chuyển dữ liệu trong chương trình thành dạng truyền/lưu |
| Deserialize | Đọc dạng truyền/lưu thành cấu trúc chương trình |
| UTF-8 | Cách mã hóa byte cho văn bản, cần đúng để giữ tiếng Việt |
| Multipart | Định dạng request chia thành nhiều phần, thường dùng upload file |
| Authentication | Xác định người gọi là ai |
| Authorization | Xác định người gọi được làm gì |
| Bearer | Cách gửi token trong Authorization header |
| JWT | Token có cấu trúc được ký, có các claim; JWT nội bộ của C-Store dùng HS256 |
| Claim | Một trường dữ liệu trong JWT như subject, role, thời hạn, phiên bản |
| Signature/chữ ký | Dữ liệu dùng kiểm tra tính toàn vẹn/xác thực theo khóa và thuật toán |
| HS256 | HMAC-SHA256 với khóa đối xứng trong cấu hình JWT C-Store |
| JWK | Biểu diễn khóa; Google verifier dùng endpoint JWK cho xác minh token Google |
| Issuer | Bên phát hành token |
| Audience | Bên nhận/đối tượng mà token nhắm tới |
| Expiry | Thời điểm token hết hiệu lực |
| Token version | Phiên bản phiên dùng để vô hiệu hóa JWT cũ theo DB |
| BCrypt | Thuật toán hash mật khẩu được encoder backend dùng |
| Hash | Kết quả một chiều để kiểm tra dữ liệu; không phải mật khẩu gốc |
| OAuth/OIDC | Các giao thức liên quan ủy quyền/đăng nhập; SDK và verifier xử lý chứng cứ của provider |
| ID token | Chứng cứ danh tính Google SDK trả cho luồng này |
| Access token | Token truy cập provider, ví dụ Facebook classic access token |
| App Secret | Bí mật phía backend dùng với Facebook; không phải public client configuration |
| CSRF | Một nhóm nguy cơ khi thông tin xác thực được trình duyệt tự gửi; source đang cấu hình API Bearer stateless |
| Stateless | Không dùng HTTP server session để nhớ phiên trong Security; vẫn có thể kiểm tra tài khoản qua DB |
| Redact | Che nội dung nhạy cảm khi ghi log/thông báo lỗi |

Không giải mã payload JWT rồi coi dữ liệu là đã tin cậy. Cần xác minh chữ ký, thời gian và các điều kiện của ứng dụng. Không có gì trong UI Flutter được phép thay cho kiểm tra quyền của backend.

## 9. Vị trí và bản đồ

| Từ | Nghĩa |
| --- | --- |
| Latitude/vĩ độ | Vị trí bắc/nam, thường từ -90 đến 90 |
| Longitude/kinh độ | Vị trí đông/tây, thường từ -180 đến 180 |
| GPS/location service | Nguồn vị trí do thiết bị/hệ điều hành cung cấp |
| Foreground permission | Quyền vị trí cho luồng sử dụng khi app hoạt động theo cấu hình |
| Geocoding | Chuyển địa chỉ/mô tả thành tọa độ |
| Reverse geocoding | Chuyển tọa độ thành địa chỉ gợi ý |
| Nominatim | Dịch vụ mà source dùng cho reverse-geocoding |
| Tile | Một ô ảnh nền bản đồ |
| OpenStreetMap | Nguồn dữ liệu bản đồ; tile và dịch vụ định tuyến không phải cùng API |
| Marker | Dấu vị trí trên bản đồ |
| Polyline | Đường nối danh sách tọa độ để hiển thị tuyến |
| GeoJSON | Dạng dữ liệu địa lý; các mảng tọa độ OSRM dùng kinh độ trước vĩ độ |
| OSRM | Dịch vụ định tuyến đường bộ mà backend gọi |
| Waypoint/snap | Điểm dùng trong tuyến và việc gắn điểm đó tới mạng đường |
| Maneuver/step | Một bước chỉ dẫn rẽ/đi tiếp trên tuyến |
| Haversine | Công thức khoảng cách địa lý giữa hai điểm, không phải chiều dài đường chạy xe |
| Duration | Thời gian dự kiến của tuyến, không phải cam kết thời gian giao |
| Debounce | Chờ thao tác ổn định một khoảng ngắn rồi mới gửi, giảm request khi kéo/chọn nhanh |
| Cache | Nhớ lại kết quả đã có để tránh tính/gọi mạng lặp |
| TTL | Thời gian một mục cache còn được xem là dùng được |
| Queue | Hàng đợi để xử lý tuần tự |
| Simulated location | Tọa độ mô phỏng, cần phân biệt với đo GPS vật lý |
| Attribution | Ghi nhận nguồn bản đồ/dữ liệu theo yêu cầu tương ứng |

Luôn kiểm tra thứ tự tọa độ ở mỗi API. `LatLng` của UI và mảng GeoJSON không nhất thiết viết cùng thứ tự. Chuyển nhầm có thể vẫn là hai số hợp lệ nhưng chỉ tới một vị trí khác.

## 10. Hệ thống chạy và kiểm thử

| Từ | Giải thích |
| --- | --- |
| Process/PID | Tiến trình đang chạy/mã nhận diện tiến trình |
| Port | Cổng mạng; API dùng 8080, MySQL host dùng 3307 theo source |
| Host | Máy Linux đang chạy backend/Docker/tooling |
| Emulator/AVD | Chương trình giả lập Android/cấu hình thiết bị ảo |
| ADB | Công cụ giao tiếp với thiết bị Android |
| APK | Gói cài đặt Android được build |
| JAR | Gói Java; backend JAR có thể chạy bằng `java -jar` |
| Gradle | Công cụ build phần Android |
| AGP | Android Gradle Plugin, cung cấp các tác vụ build Android |
| Manifest | Khai báo app Android, activity, permission và metadata |
| Docker image | Mẫu filesystem/config dùng tạo container |
| Container | Tiến trình/môi trường chạy từ image, ở đây là MySQL |
| Volume | Vùng lưu dữ liệu Docker có vòng đời riêng với container |
| Compose service | Một thành phần trong `docker-compose.yml`, ở đây có `mysql` |
| Healthcheck | Kiểm tra chương trình trong container sẵn sàng hay chưa |
| systemd user service | Service do tài khoản người dùng quản lý, ở đây chạy backend |
| Journal | Hệ thống log của systemd |
| Kitty | Ứng dụng terminal được dùng làm cửa sổ xem log |
| PTY | Pseudo-terminal để lệnh con có môi trường terminal |
| Exit code | Mã kết thúc lệnh; `0` thường thành công |
| Environment variable | Cấu hình được truyền vào tiến trình, khác với field Java/Dart |
| Compile-time define | Cấu hình được Flutter đưa vào bản build Dart |
| Hot reload | Nạp thay đổi Dart phù hợp và cố giữ state hiện có |
| Hot restart | Khởi tạo lại phần Dart; state RAM có thể mất |
| Unit test | Kiểm tra đơn vị logic theo phạm vi của bài |
| Widget test | Kiểm tra widget/interaction trong môi trường test Flutter |
| Integration test | Kiểm tra nhiều phần phối hợp; luôn đọc bài đang dùng những phần thật/giả nào |
| E2E | Thử một luồng xuyên nhiều lớp theo góc nhìn sử dụng |
| Mock/fake | Thay một dependency bằng phiên bản kiểm soát được trong test |
| Fixture | Dữ liệu chuẩn bị cho bài test |
| Assertion/expect | Điều kiện mà bài test yêu cầu phải đúng |
| Regression | Chức năng từng đúng bị lỗi sau thay đổi |
| Smoke test | Bài thử ngắn kiểm tra một số luồng cơ bản hoạt động |
| QA data | Dữ liệu riêng do các script kiểm thử tạo qua API |
| Coverage/phạm vi | Những phần thực sự đã được bài thử kiểm tra; không suy ra từ tên lệnh |

## 11. Tập dịch một câu code thành tiếng Việt

Ví dụ Dart:

```dart
final total = lines.fold(0, (sum, line) => sum + line.price * line.quantity);
```

1. `final total`: kết quả sẽ gán một lần cho biến `total`.
2. `lines`: danh sách các dòng hàng.
3. `fold(0, ...)`: bắt đầu tổng tích lũy bằng 0.
4. `sum`: tổng trước khi xử lý dòng hiện tại.
5. `line`: dòng hàng đang xét.
6. `line.price * line.quantity`: tiền của dòng hàng đó.
7. `sum + ...`: tạo tổng mới.
8. Sau phần tử cuối, `fold` trả tổng tiền hàng; đây chưa tự cộng phí giao.

Ví dụ Java dạng rút gọn để học cơ chế:

```java
var user = users.findById(id).orElseThrow(() -> notFound());
```

1. `users`: repository đang được sử dụng.
2. `findById(id)`: yêu cầu tìm bản ghi có ID được cung cấp.
3. Kết quả `Optional`: có thể có user hoặc không.
4. `orElseThrow`: có user thì lấy ra, không có thì ném lỗi.
5. `() -> notFound()`: lambda chỉ tạo lỗi ở nhánh không có dữ liệu.
6. `var user`: Java suy ra kiểu của biến nhận kết quả.

`notFound()` ở ví dụ Java là tên minh họa, không phải khẳng định mọi repository trong dự án có một method tên đó. Khi đối chiếu source, đọc đúng hàm tạo lỗi mà method thực tế dùng.

Khi dịch bất kỳ dòng nào, tự hỏi bốn câu: **đang đọc dữ liệu gì, trả ra gì, có thay đổi gì bên ngoài không và nếu lỗi thì đi nhánh nào?** Cách này giúp bạn hiểu cả những dòng sau này chưa có chú thích.
