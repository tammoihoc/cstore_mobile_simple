# Sổ tay học và quản lý dự án C-Store

Tài liệu này dành cho người đã học lập trình cơ bản và muốn hiểu **source đang có trong dự án**, từ lúc bấm chạy đến lúc đơn hàng được lưu vào MySQL. Các tên file là tên thật sau đợt chia lại code. Khi đọc, mở tài liệu và file tương ứng cạnh nhau trong trình soạn thảo.

## Đọc theo thứ tự nào?

| Thứ tự | Tài liệu | Bạn sẽ hiểu gì? |
| --- | --- | --- |
| 1 | [Bức tranh tổng thể và cách lần theo chức năng](kien-truc-va-luong-chay.md) | App, API, database, thư mục và trình tự chạy |
| 2 | [Tất cả công nghệ và thư viện đang dùng](cong-nghe.md) | Công nghệ nào làm việc gì, được khai báo ở đâu, giới hạn thực tế |
| 3 | [Lệnh chạy, kiểm thử và cấu hình](lenh-va-cau-hinh.md) | Từng thành phần của câu lệnh terminal và kết quả dự kiến |
| 4 | [Cách đọc dữ liệu và logic Flutter](mobile-du-lieu.md) | Model, HTTP, AppState, async, phiên đăng nhập, giỏ và đơn |
| 5 | [Giao diện Flutter theo từng vai trò](mobile-giao-dien.md) | Screen, widget, form, điều hướng và nơi sửa từng phần UI |
| Tra nút | [Tất cả các nút: chức năng code ở đâu?](ban-do-cac-nut.md) | Tên nút → file giao diện → hàm xử lý → nghiệp vụ/API |
| Thuyết trình | [Giao diện, các nút và kịch bản demo](thuyet-trinh-giao-dien-va-cac-nut.md) | Mở từng màn, thao tác, lời nói mẫu và cách giải thích code UI |
| 6 | [Backend theo lớp trách nhiệm](backend.md) | Controller, service, repository, entity, DTO, security và transaction |
| 7 | [Đọc từng dòng các luồng cốt lõi](doc-tung-dong.md) | Source thật có số dòng, diễn giải từng câu lệnh và dấu ngoặc |
| 8 | [Bản đồ toàn bộ mã nguồn](ban-do-source.md) | Tra cứu file, class, hàm và các mốc dòng trong source |
| Kiểm chứng | [Kết quả kiểm thử sau refactor](kiem-thu-sau-refactor.md) | Những phần đã/chưa kiểm tra và nơi đọc log |
| Nhận diện app | [Biểu tượng Android](../../mobile/branding/README.md) | Ảnh gốc, các kích thước launcher icon và cách cập nhật |
| Tra cứu | [Thuật ngữ và ký hiệu](thuat-ngu.md) | Từ vựng Java, Dart, Flutter, SQL, HTTP và các dấu thường gặp |

Phần “từng dòng” tập trung giải thích đầy đủ những luồng làm xương sống: khởi động, chọn màn theo vai trò, HTTP, đăng nhập, tải catalog, đặt đơn và backend lưu đơn. Giao diện có nhiều thuộc tính lặp lại như `padding`, `color`, `children`: chương giao diện giải thích quy tắc đọc, còn bản đồ source chỉ tới từng widget. Bạn không cần học thuộc hàng nghìn dòng thiết lập giao diện để hiểu luồng dữ liệu.

## Những việc đã thay đổi trong source

- Backend có các Java package thật: `controller`, `service`, `repository`, `entity`, `dto`, `config`, `security`, `mapper`, `support`, `exception`.
- Các entity/repository trước đây nằm chung file được tách riêng. Điểm vào Spring Boot vẫn ở package cha `com.cstore.app` để quét được các package con.
- Flutter tách model theo loại dữ liệu; HTTP chung ở `services/api`; trạng thái và nhóm thao tác ở `services/state`; theme ở `app/theme`.
- Các màn lớn được tách theo trang, tab và widget có tên rõ. Một số file cũ chỉ còn `export` để giữ đường dẫn import hiện có.
- Bố cục code dùng thụt lề và dấu phẩy cuối tham số để dễ nhìn cặp ngoặc và cây widget. Chú thích tiếng Việt giải thích các chốt quan trọng.

Đây là tổ chức lại source. Không có chủ đích thay API, cấu trúc bảng, phép tính phí hay giao diện đã thống nhất. Đừng suy từ việc một nút bị ẩn trên app rằng server đã bảo vệ quyền: quyền vẫn được kiểm tra ở backend.

## Cách tự học một chức năng

Ví dụ bạn muốn hiểu nút “Đăng nhập”:

1. Tìm `submit` trong `mobile/lib/screens/auth/welcome.dart`.
2. Xem lệnh gọi `state.login(...)` và các bước bật/tắt biến `busy`.
3. Theo tới `services/state/app_state.dart`, rồi `state/session_actions.dart`.
4. Theo tiếp `api/account_api.dart` và `api/api_client.dart` để xem URL và JSON.
5. Tới `backend/.../controller/AuthController.java`, đọc DTO `AuthDtos.Login`.
6. Xem `Users`, `AppUser`, `AccountService` và `SecurityConfig` để hiểu truy vấn, mật khẩu, JWT và quyền.
7. Quay lại `RoleHome`: sau khi `account` đổi và phát thông báo, app chọn màn mới.

Nếu chưa hiểu một ký hiệu, tra thuật ngữ trước rồi quay lại đúng câu lệnh. Tránh đọc lần lượt mọi file theo thứ tự thư mục mà không có câu hỏi cụ thể.

## Cập nhật tài liệu khi sửa code

`ban-do-source.md` và `doc-tung-dong.md` được tạo từ source bằng các script tương ứng trong `scripts/`. Khi di chuyển hoặc thêm dòng code, chạy công cụ qua `run-visible.py` như hướng dẫn ở đầu tài liệu để cập nhật số dòng. Các chương giải thích nghiệp vụ cần được sửa bằng tay khi bạn đổi chức năng; công cụ không tự suy ra quy tắc kinh doanh mới.

Không sao chép nội dung `.env`, tệp tài khoản QA, mật khẩu hoặc token vào bài thuyết trình. Tài liệu chỉ dùng tên biến cấu hình và ví dụ không có thông tin đăng nhập thật.
