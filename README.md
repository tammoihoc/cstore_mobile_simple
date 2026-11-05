# C-Store — Android app và REST API

Dự án gồm Flutter/Dart cho Android, một backend Java/Spring Boot và MySQL. Có bốn vai trò: khách hàng, cửa hàng, shipper và admin. Dữ liệu nghiệp vụ lấy từ API; logo/banner tĩnh được đóng gói cùng app.

## Bắt đầu học source

Mở **[Sổ tay C-Store bằng tiếng Việt](docs/huong-dan/README.md)**. Tài liệu được viết cho trình độ sinh viên, có lộ trình đọc thay vì phải đọc mọi file cùng lúc.

- [Kiến trúc, thư mục và luồng chạy](docs/huong-dan/kien-truc-va-luong-chay.md)
- [Công nghệ và toàn bộ thư viện đang dùng](docs/huong-dan/cong-nghe.md)
- [Giải thích lệnh terminal và cấu hình](docs/huong-dan/lenh-va-cau-hinh.md)
- [Model, API và AppState Flutter](docs/huong-dan/mobile-du-lieu.md)
- [Trang và widget giao diện theo vai trò](docs/huong-dan/mobile-giao-dien.md)
- [Tất cả các nút: file và hàm xử lý chức năng](docs/huong-dan/ban-do-cac-nut.md)
- [Hướng dẫn thuyết trình giao diện, các nút và kịch bản demo](docs/huong-dan/thuyet-trinh-giao-dien-va-cac-nut.md)
- [Backend: controller/service/repository/entity và bảo mật](docs/huong-dan/backend.md)
- [Giải thích từng dòng các luồng cốt lõi](docs/huong-dan/doc-tung-dong.md)
- [Bản đồ file/class/hàm của toàn dự án](docs/huong-dan/ban-do-source.md)
- [Thuật ngữ và ký hiệu](docs/huong-dan/thuat-ngu.md)
- [Biểu tượng ứng dụng Android và cách thay ảnh](mobile/branding/README.md)

## Cấu trúc chính

```text
backend/src/main/java/com/cstore/app/
├── CStoreApplication.java   # Điểm vào Spring Boot
├── controller/              # URL, request và response
├── service/                 # Nghiệp vụ, phiên, tuyến giao
├── repository/              # Truy vấn database và khóa bản ghi
├── entity/                  # Bảng và quan hệ JPA
├── dto/                     # Dữ liệu nhận/trả API
├── config/                  # Cấu hình Spring và bảo mật
├── security/                # Kiểm chứng Google/Facebook
├── mapper/                  # Chọn dữ liệu công khai trả API
├── support/                 # Hàm hỗ trợ nhỏ
└── exception/               # Chuyển lỗi thành HTTP response

mobile/lib/
├── main.dart                # Điểm vào Flutter
├── app/                     # Widget gốc, chọn màn theo vai trò, theme/
├── models/                  # Tài khoản, chi nhánh, sản phẩm, đơn, báo giá
├── services/
│   ├── api/                 # HTTP/JSON và endpoint cụ thể
│   └── state/               # AppState và các nhóm thao tác
├── screens/
│   ├── auth/
│   ├── admin/               # pages/, widgets/, models/
│   ├── customer/            # Cửa hàng, giỏ, checkout
│   ├── store/               # Các tab ở widgets/
│   ├── shipper/             # Nhận/giao và models/ điều hướng
│   ├── profile/             # pages/ sửa hồ sơ, mật khẩu
│   └── orders/              # Danh sách và chi tiết đơn
└── widgets/                 # Thành phần dùng chung
```

Một số đường dẫn cũ như `services/app_state.dart`, `services/account_api.dart`, `models/models.dart`, `screens/orders.dart` chỉ export các file được chia nhỏ. Giữ chúng giúp màn hình và test tiếp tục import như cũ. Không tạo thêm class cùng tên trong các file facade này.

## Chức năng hiện có

- Đăng ký khách/shipper; đăng nhập email hoặc thông qua plugin Google/Facebook khi cấu hình phù hợp. Backend kiểm chứng và cấp JWT; role do server xác định.
- Admin quản lý tài khoản, thương hiệu/chi nhánh, logo và báo cáo; chi nhánh phải xác nhận điểm trên bản đồ.
- Cửa hàng quản lý sản phẩm, tồn kho, ảnh, đơn và dashboard doanh thu; dữ liệu qua REST và MySQL.
- Khách lưu điểm giao, tìm chi nhánh gần, chọn sản phẩm và đặt COD. Server chốt giá, giữ tồn bằng transaction/khóa và lưu snapshot dòng đơn.
- Shipper cập nhật online/vị trí, nhận đề nghị phù hợp, nhận tối đa số đơn được server cho phép, lấy/giao hàng và ghi nhận thu COD.
- Backend kiểm tra quyền, thứ tự trạng thái, hoàn tồn và tranh chấp nhận đơn/checkout. Dữ liệu khách/cửa hàng/shipper được polling mỗi 10 giây; báo cáo và tài khoản admin tải riêng khi mở, làm mới hoặc có thao tác.
- Upload JPEG/PNG qua multipart; backend giải mã/kiểm tra rồi lưu PNG dưới thư mục upload. MySQL giữ URL/đường dẫn ảnh.

Khoảng cách giao chính thức dùng **đường bộ OSRM**; Haversine còn được dùng để sàng lọc khoảng cách hoặc tính toán phụ. App có **Nominatim reverse geocoding** để gợi ý địa chỉ, người dùng vẫn cần xác nhận. Tile OpenStreetMap, định tuyến, địa chỉ và GPS là các thành phần khác nhau; xem giới hạn và chính sách ở chương công nghệ.

## Chạy và kiểm thử với log trong Kitty

Chạy lệnh từ gốc dự án. Theo `AGENTS.md`, kiểm thử/build/check của agent phải có log trực tiếp trong Kitty. `run-visible.py` mở hoặc dùng lại một cửa sổ log, đồng thời lưu file ở `.local/visible-tests/`.

Kiểm tra tiến trình và dùng lại backend, Flutter, emulator đang chạy trước khi mở mới. Tìm Flutter bằng `command -v flutter`; Android SDK lấy từ `ANDROID_HOME`/`ANDROID_SDK_ROOT` hoặc các công cụ trên PATH. Dự án chưa cấu hình Flutter Web.

### Backend và MySQL

Chuẩn bị `.env` cục bộ theo tên biến trong `.env.example`; không gửi nội dung hoặc giá trị bí mật vào chat/log. Các chương tài liệu chỉ dùng placeholder.

```bash
python3 scripts/run-visible.py --name khoi-dong-backend -- ./scripts/start-backend.sh
```

Script chờ MySQL healthy, build JAR và chạy đúng systemd user service `cstore-mobile-backend.service`. Nếu service này đang hoạt động, script dùng lại. Khi cần nạp source Java mới, dừng đúng service rồi chạy lại script; không dừng toàn bộ Java trên máy.

- Backend: `http://127.0.0.1:8080`.
- MySQL: `127.0.0.1:3307`, database `cstore_mobile_db`, Docker volume `cstore_mobile_mysql_data`.
- Backend upload mặc định ở `backend/uploads/`; cần giữ cả ảnh và database khi sao lưu dữ liệu nghiệp vụ.
- Không xóa volume để làm mới test; các script QA tạo dữ liệu có tên riêng qua API.

### Android

```bash
adb devices
python3 scripts/run-visible.py --name app-android --cwd mobile -- flutter run -d emulator-5554
```

Thay device ID theo thiết bị thật sự đang chạy. Nếu chưa có emulator, dùng AVD `Pixel_6`. API debug Android mặc định là `http://10.0.2.2:8080`; đây là địa chỉ máy Linux nhìn từ emulator. Có thể đổi bằng `API_BASE_URL` khi build/run.

Thay source Dart thường dùng hot reload; đổi cấu trúc lớp/thư viện có thể cần hot restart. Thay native plugin hoặc cấu hình Android cần dừng và chạy lại. `r`/`R` được gửi tới tiến trình Flutter tương tác, không gõ vào cửa sổ chỉ xem log.

### Kiểm tra mã và nghiệp vụ

```bash
python3 scripts/run-visible.py --name flutter-analyze --cwd mobile -- flutter analyze
python3 scripts/run-visible.py --name flutter-tests --cwd mobile -- flutter test
python3 scripts/run-visible.py --name backend-tests --cwd backend -- mvn -Djava.version=25 test
python3 scripts/run-visible.py --name api-live -- python3 scripts/test-live.py
python3 scripts/run-visible.py --name android-live -- python3 scripts/test-android-live.py
```

POM khai báo Java 21; ví dụ `-Djava.version=25` phù hợp máy đang có Java 25. Trên máy khác, đối chiếu `java -version` và hướng dẫn toolchain trước khi chép lệnh. Maven test dùng H2; API live dùng backend/MySQL thật; Android live cần emulator và dữ liệu QA từ bài API.

Các tài khoản QA được ghi riêng trong `.local/` và không commit. Android runner có mô phỏng GPS, nên kết quả không chứng minh GPS hoặc camera trên điện thoại vật lý. Bài test không thực hiện đăng nhập OAuth bằng tài khoản bên ngoài thật.

## Cập nhật các chương tạo từ source

```bash
python3 scripts/run-visible.py --name ban-do-source -- python3 scripts/generate-source-map.py
python3 scripts/run-visible.py --name doc-tung-dong -- python3 scripts/generate-reading-guide.py
```

Bản đồ tự lấy số dòng hiện tại; tài liệu đọc từng dòng có chú giải được biên soạn cho những luồng cốt lõi. Khi đổi nghiệp vụ, cần sửa cả phần giải thích tương ứng, không chỉ tạo lại số dòng.

## Giới hạn hiện tại

JWT nằm RAM của app, chưa có refresh token/auto-login. Chưa có push notification, thanh toán online, GPS nền hoặc phân trang đầy đủ. Schema local dùng `ddl-auto: update`; source chưa có hệ thống migration Flyway. Dịch vụ bản đồ/định tuyến/địa chỉ công cộng có giới hạn và phụ thuộc mạng; xem chương công nghệ trước khi triển khai nhiều người dùng.

`PROGRESS.md` giữ ghi chép lịch sử. Để hiểu cấu trúc và chức năng hiện tại, ưu tiên source và sổ tay mới, rồi đối chiếu log kiểm thử thực tế.
