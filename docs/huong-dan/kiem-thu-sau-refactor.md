# Kết quả kiểm tra sau khi chia lại source

Ngày kiểm tra: **03/11/2026** theo giờ Việt Nam. Đây là bằng chứng của đợt tổ chức lại code, không phải cam kết cho mọi thay đổi trong tương lai.

| Phần | Kết quả thực tế | Log từ gốc dự án |
| --- | --- | --- |
| Java/Spring Boot | 42 test đạt; không lỗi hoặc test bỏ qua trong lượt final | `.local/visible-tests/20261103-133524-92809.log` |
| Flutter | Analyze không có vấn đề; 57 test đạt | `.local/visible-tests/20261103-134450-109437.log` |
| Backend/MySQL thật | Build JAR, restart đúng service và API QA đều đạt | `.local/visible-tests/20261103-134932-117620.log` |
| Android emulator | Bài UI bốn vai trò đạt, thư viện ảnh native và các trang sau khi tách hoạt động | `.local/visible-tests/20261103-135147-121659.log` |
| Tài liệu | Generator source chạy được; code fences và liên kết nội bộ hợp lệ; không chép giá trị cấu hình provider vào sổ tay | `.local/visible-tests/` có lượt `kiem-tra-so-tay-final` và `kiem-tra-so-tay-chot` |

API QA đã kiểm tra đăng nhập/phân quyền, upload ảnh, lưu điểm giao, báo giá đường bộ, snapshot giá, tranh tồn kho giữa hai checkout, tranh nhận đơn giữa hai shipper, chuyển trạng thái, COD, hoàn tồn, quản trị tài khoản và doanh thu. Script tạo dữ liệu QA có tên riêng; không reset database.

Android QA đã đi qua khách hàng, shipper, cửa hàng và admin: hồ sơ, ưu tiên ảnh riêng, ảnh theo lựa chọn giới tính, gọi đúng người liên quan, lịch sử/bộ lọc ngày, dashboard/tồn kho/đơn/chi nhánh và bộ lọc tài khoản admin. Ảnh chụp và báo cáo nằm trong `.local/qa-screenshots/`, `.local/android-refinements-report.json`.

Chưa chạy lại trên điện thoại vật lý, chưa xác thực OAuth bằng tài khoản nhà cung cấp thật và chưa kiểm tra camera vật lý. Test H2, MySQL QA và emulator có phạm vi khác nhau; không thay thế nhau.

Backend mới được giữ chạy; app thường được mở lại trên emulator sau bài tích hợp. Dữ liệu màn hình được tải từ server, không từ fixtures trong source.
