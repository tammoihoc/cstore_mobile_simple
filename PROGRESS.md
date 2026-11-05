# Tiến độ hiện tại — 31/10/2026

## Phạm vi hiện tại

Theo yêu cầu mới: tạo luồng kiểm thử với dữ liệu thật, GPS Android, khoảng cách và ảnh sản phẩm. Đã thay nguồn dữ liệu RAM bằng REST/MySQL; không còn catalog/đơn/chi nhánh được tạo từ fixtures trong app.

## Đã triển khai

- `AppState` thay `DemoState`: tải catalog/đơn/vị trí/trạng thái shipper từ API; loading/error/retry; polling 10 giây. Login và đăng ký CUSTOMER/SHIPPER thật; ADMIN cấp STORE và chi nhánh.
- Thêm/sửa/ngừng bán sản phẩm qua API, danh mục/giá/tồn riêng chi nhánh. Chọn ảnh thư viện/chụp bằng image_picker, upload multipart; backend kiểm tra ảnh, lưu PNG tên ngẫu nhiên trong `backend/uploads`, URL lưu MySQL, UI dùng Image.network.
- GPS foreground bằng geolocator, kiểm tra dịch vụ và quyền, không trả tọa độ mẫu. Map có nút GPS/độ chính xác; lỗi quyền/GPS/timeout có thông báo. Tọa độ GPS vừa lấy có thể xác nhận nếu DNS/tile OSM lỗi; điểm chạm thủ công trên nền chưa tải bị chặn. Nguồn GPS bị xóa khi chạm chỉnh điểm thủ công.
- Khoảng cách Haversine đường chim bay: backend tính lại từ tọa độ gửi tới, kiểm tra giao trong 10 km, shipper nhận trong 5 km; phí 15.000đ + 3.000đ/km làm tròn đến đồng. Chưa tính đường bộ.
- Đặt đơn giữ tồn bằng transaction/row lock theo thứ tự ID; snapshot tên/giá và thông tin giao hàng; hủy/từ chối hoàn tồn một lần. Trạng thái từ PENDING đến DELIVERED, history lưu timestamp MySQL.
- Shipper online/vị trí lưu server; claim dùng lock user + order, tối đa 3 đơn. COD ghi người/thời gian, khóa chống xác nhận trùng, chặn giao hoàn thành khi chưa ghi nhận thanh toán. Dashboard từ đơn server, đúng chi nhánh.
- Nút tạo cửa hàng và lưu sản phẩm đặt cố định cuối màn để không khuất dưới biểu mẫu dài.

## Kiểm chứng đã có

- Maven: 5 test PASS (2 AccountFlowTest, 3 CommerceFlowTest) trên H2. Bao phủ quyền đăng ký/admin, pin/tọa độ, BCrypt, gán chi nhánh, upload/đọc PNG, từ chối SVG, reserve/cancel, snapshot/tổng tiền/khoảng cách, COD đúng bước, nhận/thu tiền trùng, hai checkout tranh một tồn, cách ly chi nhánh, shipper ngoài 5 km và giới hạn 3 đơn.
- MySQL thật: `python3 scripts/test-live.py` PASS. Tạo tài khoản/chi nhánh/sản phẩm qua API, upload PNG thật và GET ảnh, checkout giữ tồn/snapshot, xa quá 10 km bị chặn, CUSTOMER gọi admin bị 403; hai shipper claim cùng đơn trả 200/409, COD đầy đủ; hai checkout stock=1 trả 200/409, tồn không âm; hủy hoàn đúng một lần.
- Report MySQL `.local/qa-report.json`: branch 3, product 1, order 1, khoảng cách 0.07071240983492448 km (tọa độ fixture API, không phải GPS thiết bị).
- Android E2E commerce cuối: PASS trên Pixel_6 Android 14. Chọn file thật qua Photo Picker Android, lưu sản phẩm/ảnh qua app, GPS từ Android LocationManager, tìm chi nhánh, checkout lưu MySQL. Lần PASS cuối đã tạo product 6, order 5; GPS nhận 10.7736,106.7034; khoảng cách 0.07071240983492448 km, tổng 42.213đ, tồn sản phẩm sau đặt = 4. Đã đọc lại các giá trị này từ API/MySQL sau khi test kết thúc; `.local/android-report.json` ghi kết quả, không chứa mật khẩu. Runner bơm vị trí mô phỏng ADB, không hardcode trong LocationService. Chưa phải kiểm tra GPS vật lý ngoài thực địa.
- Unit/widget Flutter sau đổi API: 11 PASS; `flutter analyze`: No issues found.
- Android test ADMIN tạo cửa hàng: PASS. Điền form, lấy GPS, ghim/xác nhận địa chỉ, submit, kiểm tra bản ghi tài khoản/chi nhánh từ server và login STORE vừa cấp. Log `.local/android-admin-test.log`.

## Runtime

Backend cũ do người dùng chạy trong Kitty đã được xác định đúng project ở cổng 8080, dừng có kiểm soát để nạp bản mới. Hiện backend chạy bằng systemd user `cstore-mobile-backend.service`, MySQL riêng healthy tại 3307. Không sửa/dừng database/container của NewFolder. Xem log trong Kitty: `journalctl --user -u cstore-mobile-backend.service -f`. Có thể chuyển về Maven foreground theo README, nhưng không chạy hai server cùng cổng.

## Tài khoản và dữ liệu QA

`scripts/test-live.py` chỉ thêm bản ghi QA có tên riêng qua API, không reset dữ liệu. Mật khẩu ngẫu nhiên trong `.local/qa-accounts.json` quyền 600, thư mục quyền 700 đã gitignore; không ghi token/mật khẩu vào báo cáo. Script Android `scripts/test-android-live.py` đọc các tài khoản này và ghi log private tại `.local/`.

## Lỗi thực tế và giới hạn

- Backend trước đây dừng sau phiên làm việc làm không tạo được cửa hàng; script systemd user hiện giữ runtime ngoài vòng đời tool.
- E2E phát hiện DNS không resolve `tile.openstreetmap.org`, khiến xác nhận bị khóa dù GPS có dữ liệu. Đã cho phép vị trí GPS thực dùng được khi nền map lỗi; không giả vờ map đã tải, vẫn báo lỗi DNS/kết nối. Chưa sửa DNS hệ thống của người dùng.
- Chưa có định tuyến đường bộ, geocoding/tìm địa chỉ tự động, GPS nền; chưa thử camera vật lý/điện thoại thật. Brands vẫn lưu tên trên Store; manager/staff, migration Flyway, phân trang, refresh token và xóa ảnh cũ chưa triển khai. `ddl-auto:update` chỉ local. JWT nằm RAM.
- Ảnh QA sử dụng logo PNG thật được chọn từ thư viện emulator để kiểm tra truyền file; không giả làm ảnh hàng hóa thương mại. Asset marketing vẫn có ở màn chào; ảnh sản phẩm luôn là URL server.

## File chính thay đổi

Backend: Entities, Repositories, ApiController, ImageController, ApiErrors, SecurityConfig, application.yml; CommerceFlowTest. Flutter: services/app_state.dart/account_api.dart/location_service.dart, models, widget ProductImage/SyncStatus, auth/admin/customer/store/shipper/orders, quyền Android, dependencies; xóa demo_state.dart và fixtures. Test: unit/widget điều chỉnh REST và integration_test/create_partner_test.dart/live_commerce_test.dart. Scripts: start-backend.sh, test-live.py, test-android-live.py; README và .gitignore.

## Lượt kiểm tra cuối

Android commerce đã chạy lại PASS sau sửa xử lý lỗi tile, với điểm giao cách chi nhánh khoảng 70,7 m để quan sát khoảng cách. Một lượt kiểm tra trước bị lệnh force-stop từ ngoài app cắt ngang (Android exit-info USER REQUESTED / FORCE STOP, không có crash); người dùng đã đồng ý để emulator yên trong lượt chạy cuối. Không tính lượt bị ngắt là PASS.

## Trạng thái bàn giao cuối

Đã hoàn thành hai Android E2E (ADMIN và commerce), 5 test Java H2 và 11 test Flutter. `flutter analyze` No issues found. API/MySQL concurrency test PASS. Backend systemd user active và GET /api/branches HTTP 200, MySQL healthy. Đã build APK debug ứng dụng bình thường (không mang dart-define mật khẩu QA), cài lại thành công và mở app trên emulator. Build còn cảnh báo native access Java/Gradle và source Java 8 của geolocator nhưng không lỗi.

Tài khoản thử dùng `.local/qa-accounts.json`; đơn 5 vẫn PENDING để tiếp tục thử STORE chấp nhận → SHIPPER giao/COD từ ứng dụng. Script API đã thử trọn COD đến DELIVERED + PAID riêng. Giữ đúng phân biệt: Android E2E xác nhận GPS/ảnh/checkout và admin; full COD/concurrency đã kiểm tra ở API/MySQL, chưa chạy toàn bộ thao tác giao COD qua UI Android.
