# Quy ước làm việc với dự án C-Store

## Kiểm thử phải quan sát được

- Người dùng muốn xem quá trình chạy và đọc log trực tiếp trong **Kitty**. Trước khi chạy kiểm thử, build hoặc kiểm tra mã nguồn, mở cửa sổ log Kitty hoặc dùng lại cửa sổ log của dự án đang mở. Không chạy kiểm thử âm thầm rồi chỉ báo kết quả cuối cùng.
- Dùng `python3 scripts/run-visible.py --name <ten-kiem-tra> -- <lenh> ...` từ gốc dự án để vừa hiện log trong Kitty, vừa lưu log cho agent đọc. Với Flutter, dùng `--cwd mobile`. Các thao tác đọc file, sửa code và kiểm tra cú pháp của chính công cụ này không cần mở GUI.
- Người dùng đã chọn **máy ảo Android hiện có** để xem và kiểm thử ứng dụng. Ưu tiên thiết bị đang chạy; nếu chưa có thì mở AVD `Pixel_6`. Giữ cửa sổ máy ảo hiển thị khi kiểm thử giao diện.
- Dự án hiện chưa hỗ trợ Flutter Web. Chỉ mở Chrome để chạy ứng dụng khi người dùng yêu cầu chuyển sang web và đã có cấu hình tương ứng; không cần mở Chrome trắng khi kiểm thử Android.
- Trước mỗi đợt kiểm thử, nói ngắn gọn bằng tiếng Việt đang kiểm tra gì. Sau đó báo kết quả thực tế, đường dẫn log và những phần chưa kiểm tra. Không đưa mật khẩu, token hoặc nội dung `.env` vào chat hay nhãn lệnh/log.

## Dùng lại tiến trình và khởi động lại

- Kiểm tra backend, cổng 8080, thiết bị `adb devices` và phiên Flutter đang có trước khi khởi chạy. Nếu người dùng đã mở và tiến trình hoạt động đúng với dự án này, dùng lại; không mở backend, máy ảo hoặc phiên Flutter trùng lặp.
- Cửa sổ Kitty của công cụ `run-visible.py` được dùng lại giữa các lần chạy. Với terminal người dùng mở thủ công, đọc log hiện có hoặc gắn luồng log vào cửa sổ dự án nếu có thể; không giả định có thể đọc ngược toàn bộ nội dung terminal bất kỳ.
- Có thể sửa code, dừng và chạy lại tiến trình của dự án khi cần để hoàn thành công việc đã được yêu cầu. Dùng hot reload/hot restart khi phù hợp; khởi động lại khi thay dependency/native plugin, cấu hình hoặc mã backend.
- Dừng bằng Ctrl-C, PID đã xác minh hoặc đúng service `cstore-mobile-backend.service`. Không dùng `pkill java`, `pkill dart`, `killall`, hay đóng các cửa sổ/tiến trình không thuộc công việc. Nếu không xác định được tiến trình đang chiếm cổng, kiểm tra trước khi dừng.
- Sau khi hoàn thành, giữ backend, Kitty và máy ảo cần thiết để người dùng kiểm tra tiếp, trừ khi được yêu cầu dừng. Khi dừng tiến trình, thông báo rõ phần nào đã dừng.
- Nếu sandbox chặn GUI, Docker, ADB, mạng hoặc ghi cache SDK, dùng cơ chế xin quyền thực thi ngoài sandbox cho lệnh cụ thể; không lách quyền và không tiếp tục kiểm thử ẩn khi không mở được Kitty.

## Các lệnh của dự án

- Chỉ đọc mã nguồn, cấu hình cần thiết và log hiển thị trong Kitty. Không quét/đọc `backend/target`, `mobile/build`, `.dart_tool`, cache hay artifact sinh tự động để tìm hiểu dự án. Tự build từ source khi cần; chỉ sử dụng artifact để chạy/cài ứng dụng.

- Backend/MySQL: `./scripts/start-backend.sh`; log service: `journalctl --user -u cstore-mobile-backend.service -f`. Không dùng `docker compose down -v` vì sẽ xóa dữ liệu.
- Flutter: xác định đường dẫn bằng `command -v flutter`, không hardcode tên người dùng cũ. Android SDK lấy từ `ANDROID_HOME`/`ANDROID_SDK_ROOT` hoặc công cụ trên `PATH`.
- App Android: chạy `flutter run -d <device-id>` trong `mobile/`, có log hiện trong Kitty. API mặc định là `http://10.0.2.2:8080`.
- Flutter checks: `flutter analyze`, `flutter test`. Backend: `mvn -Djava.version=<Java-dang-cai> test` trong `backend/`.
- API tích hợp: `python3 scripts/test-live.py`, cần backend/MySQL sẵn sàng. Script tạo bản ghi QA riêng qua API, không reset dữ liệu.
- Android tích hợp: `python3 scripts/test-android-live.py`, hoặc thêm `--admin`; cần dữ liệu từ bài API, backend và máy ảo. Chọn thiết bị bằng `ANDROID_SERIAL` nếu cần. Bài này mô phỏng tọa độ GPS trên emulator, không chứng minh GPS trên thiết bị thật.
- Log kiểm thử nằm trong `.local/visible-tests/`; file QA có thông tin đăng nhập nằm trong `.local/` đã gitignore, không đưa vào commit/chat.
