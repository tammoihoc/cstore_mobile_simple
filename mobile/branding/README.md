# Biểu tượng ứng dụng Android

Ảnh gốc: [app.png](app.png), sao chép nguyên bản từ `Pictures/app.png` do người dùng cung cấp ngày **03/11/2026**. Lưu ảnh trong dự án để build không phụ thuộc thư mục Pictures trên một máy cụ thể.

## Các tài nguyên được tạo

`mobile/android/app/src/main/AndroidManifest.xml` dùng `android:icon="@mipmap/ic_launcher"`. Android tự chọn ảnh theo mật độ màn hình:

| Mật độ | Kích thước PNG | Đường dẫn từ `mobile/android/app/src/main/res/` |
| --- | --- | --- |
| mdpi | 48 × 48 px | `mipmap-mdpi/ic_launcher.png` |
| hdpi | 72 × 72 px | `mipmap-hdpi/ic_launcher.png` |
| xhdpi | 96 × 96 px | `mipmap-xhdpi/ic_launcher.png` |
| xxhdpi | 144 × 144 px | `mipmap-xxhdpi/ic_launcher.png` |
| xxxhdpi | 192 × 192 px | `mipmap-xxxhdpi/ic_launcher.png` |

Đây là bộ launcher icon bitmap theo cấu hình hiện có. Khung/cách bo của biểu tượng có thể khác giữa các launcher Android. Logo ngang trong giao diện Flutter dùng asset riêng `mobile/assets/images/cstore-logo.png`.

## Thay ảnh và tạo lại icon

1. Thay `mobile/branding/app.png` bằng ảnh PNG mới. Nên dùng ảnh vuông để không có khoảng trống ngoài ý muốn.
2. Từ gốc dự án, chạy:

```bash
python3 scripts/run-visible.py --name tao-icon-android -- java -Djava.awt.headless=true scripts/GenerateAppIcons.java
```

Giải thích từng phần:

- `python3 scripts/run-visible.py`: chạy công cụ hiện log trong Kitty và lưu log riêng.
- `--name tao-icon-android`: đặt nhãn lượt chạy, không phải tên ứng dụng.
- `--`: kết thúc tham số của công cụ log, phần sau là lệnh cần chạy.
- `java`: dùng JDK đã có cho backend.
- `-Djava.awt.headless=true`: xử lý ảnh không cần mở cửa sổ đồ họa Java; log vẫn hiện trong Kitty.
- `scripts/GenerateAppIcons.java`: chế độ chạy một file Java, không phải thêm lớp này vào backend Spring.

Công cụ đọc PNG bằng `ImageIO`, tính tỉ lệ vừa khung vuông, vẽ lại với nội suy bicubic và giữ alpha, rồi ghi đủ năm kích thước. Công cụ chỉ thay các file `ic_launcher.png`, không sửa ảnh gốc, dữ liệu hay logic app. Nó không cần thư viện ngoài.

## Build và cài lên Android

```bash
python3 scripts/run-visible.py --name build-icon-android --cwd mobile -- flutter build apk --debug
adb devices
python3 scripts/run-visible.py --name cai-icon-android -- adb -s emulator-5554 install -r mobile/build/app/outputs/flutter-apk/app-debug.apk
```

Dùng đúng ID từ `adb devices`. `install -r` cập nhật ứng dụng đã có và giữ dữ liệu; không cần gỡ app. Cũng có thể chạy `flutter run -d emulator-5554` trong `mobile/` qua công cụ log để build/cài và mở app. Dừng đúng phiên Flutter cũ trước khi chạy lại cấu hình native.

Hot reload chỉ cập nhật Dart, không thay launcher icon. Sau khi cài mới, về màn hình chính/danh sách ứng dụng để kiểm tra biểu tượng C-Store. Không cần reset database hoặc xóa dữ liệu app.


## Kiểm chứng ngày 03/11/2026

- Ảnh lưu trong dự án khớp nguyên bản `Pictures/app.png`; đủ năm PNG đúng kích thước.
- Bản Android debug đã build/cài thành công và mở trên AVD Pixel_6.
- Đã xem icon mới trong màn thông tin ứng dụng C-Store của Android.
- Log build/cài: `.local/visible-tests/20261103-190749-99599.log`.
- Log kiểm tra kích thước/tài liệu: `.local/visible-tests/20261103-190751-99727.log`.
- Ảnh xác nhận: `.local/qa-screenshots/app-icon-android.png`.

Chưa kiểm tra trên điện thoại vật lý hoặc các launcher khác. Đợt này thay tài nguyên icon, không thay logic Dart/backend nên không chạy lại bộ kiểm thử nghiệp vụ.
