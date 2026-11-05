# Hiểu từng lệnh chạy, kiểm thử và cấu hình

Các ví dụ được viết cho dự án C-Store local trên Linux. Trừ khi ghi rõ khác, chạy từ **thư mục gốc dự án**: thư mục có `README.md`, `backend/`, `mobile/`, `scripts/` và `docker-compose.yml`.

Bạn không cần chạy tất cả các lệnh trong tài liệu mỗi lần mở dự án. Chọn quy trình phù hợp ở phần 2. Các lệnh thay đổi cấu hình hoặc dừng service được giải thích riêng, để bạn biết chúng làm gì trước khi dùng.

## 1. Đọc cú pháp terminal trước

Ví dụ:

```bash
python3 scripts/run-visible.py --name "Phân tích Flutter" --cwd mobile -- flutter analyze
```

Đọc từ trái sang phải:

| Phần | Ý nghĩa |
| --- | --- |
| `python3` | Chương trình thực thi Python 3 |
| `scripts/run-visible.py` | File Python cần chạy, đường dẫn tương đối từ gốc dự án |
| `--name` | Tùy chọn của script, đặt nhãn lượt chạy |
| `"Phân tích Flutter"` | Một chuỗi có khoảng trắng; dấu nháy gom thành một đối số |
| `--cwd mobile` | Chuyển thư mục làm việc của lệnh con sang `mobile/` |
| `--` | Kết thúc tùy chọn của wrapper; phần sau là lệnh thật cần chạy |
| `flutter` | Chương trình được wrapper mở |
| `analyze` | Tác vụ phân tích mã Dart của Flutter |

`--cwd` không thay đổi terminal bên ngoài. Khi script kết thúc, terminal của bạn vẫn ở thư mục ban đầu. Việc chạy `flutter` bên trong `mobile/` giúp nó tìm đúng `pubspec.yaml`.

Các ký hiệu thường gặp:

| Ký hiệu | Cách đọc |
| --- | --- |
| `.` | Thư mục hiện tại |
| `..` | Thư mục cha |
| `./scripts/...` | File trong thư mục hiện tại; `./` giúp shell nhận ra đường dẫn chương trình |
| `/...` | Đường dẫn tuyệt đối bắt đầu từ gốc filesystem |
| `~` | Thư mục cá nhân của tài khoản đang dùng |
| `--ten-tuy-chon` | Tùy chọn dạng dài |
| `-d` | Tùy chọn dạng ngắn; ý nghĩa phụ thuộc chương trình |
| `TEN_BIEN=gia_tri lenh` | Đặt biến môi trường chỉ cho lệnh đó và các tiến trình con |
| `$TEN_BIEN` | Đọc giá trị biến trong shell |
| `$(...)` | Chạy lệnh bên trong và dùng output làm giá trị |
| `"..."` | Giữ chuỗi có khoảng trắng thành một đối số, vẫn cho phép shell đọc biến |
| `'...'` | Chuỗi nguyên văn trong shell, không thay biến bên trong |
| `\` cuối dòng | Nối dòng tiếp theo thành cùng một lệnh |
| `# ...` | Chú thích trong ví dụ shell; không phải tham số chương trình |

`<device-id>` trong phần giải thích là placeholder, không phải một tên thiết bị có thật để gõ nguyên dấu `<` và `>`. Ví dụ thực tế bên dưới dùng `emulator-5554`; hãy đối chiếu `adb devices` trên máy của bạn.

## 2. Quy trình thường ngày

### Bước A: biết máy đang chạy gì

```bash
python3 scripts/run-visible.py --name "Kiểm tra môi trường" -- bash -lc '
command -v flutter
java -version
adb devices
ss -ltnp "sport = :8080"
systemctl --user is-active cstore-mobile-backend.service
'
```

| Dòng | Tác dụng |
| --- | --- |
| `python3 ... -- bash -lc '...'` | Dùng wrapper để chạy một nhóm lệnh shell và hiện log trong Kitty |
| `command -v flutter` | Tìm đúng executable Flutter đang được chọn theo `PATH`; không tự đoán đường dẫn SDK |
| `java -version` | Xem JDK/JVM đang được dùng |
| `adb devices` | Liệt kê thiết bị Android; cột trạng thái cần là `device` để thao tác bình thường |
| `ss -ltnp "sport = :8080"` | Xem cổng TCP 8080 đang lắng nghe và thông tin tiến trình có thể đọc |
| `systemctl --user is-active ...` | Kiểm tra backend có đang chạy dưới service dự án không |

`bash -l` chạy login shell; `-c` yêu cầu thực hiện chuỗi lệnh tiếp theo. Chuỗi nhiều dòng ở đây giúp xem một lượt môi trường. Ví dụ không bật `set -e` vì một kết quả như service `inactive` cũng là thông tin cần đọc, không nhất thiết phải bỏ qua các kiểm tra còn lại.

Nếu backend/Flutter/emulator đã chạy đúng dự án, dùng lại. Không chạy thêm một backend chỉ vì mở terminal mới. Nếu thấy cổng 8080 có server chưa biết thuộc dự án nào, xác minh trước khi dừng.

### Bước B: bật backend nếu chưa chạy

```bash
python3 scripts/run-visible.py --name "Khởi động backend" -- ./scripts/start-backend.sh
```

Script này đọc cấu hình local đã chuẩn bị, chờ MySQL, build backend và đăng ký tiến trình Java với systemd user. Nó không yêu cầu bạn mở thêm một terminal chạy `mvn spring-boot:run` song song.

### Bước C: dùng emulator hiện có

```bash
python3 scripts/run-visible.py --name "Thiết bị Android" -- adb devices
```

Nếu chưa có emulator chạy, dùng AVD `Pixel_6` đã được chọn cho dự án:

```bash
python3 scripts/run-visible.py --name "Mở Pixel_6" -- emulator -avd Pixel_6
```

`emulator` là chương trình trong Android SDK; `-avd Pixel_6` chọn cấu hình máy ảo có tên đó. Đây là lệnh chạy lâu, vì tiến trình máy ảo phải tiếp tục tồn tại để dùng app. Không chạy lại nếu `adb devices` đã có đúng máy đang hoạt động. Giữ cửa sổ emulator hiển thị khi kiểm tra UI.

### Bước D: mở ứng dụng Flutter

```bash
python3 scripts/run-visible.py --name "Ứng dụng Android" --cwd mobile -- flutter run -d emulator-5554
```

`run` build/cài/mở app debug; `-d emulator-5554` chọn thiết bị. API mặc định của app là `http://10.0.2.2:8080`. Log cho biết quá trình build, cài APK và runtime. Bản ứng dụng chạy lâu, không phải lệnh bắt buộc phải trả prompt ngay.

Khi wrapper được mở từ terminal tương tác, nó có thể chuyển input tới Flutter. Cửa sổ **C-Store — Test logs** do wrapper mở là cửa sổ xem log; gõ `r` vào cửa sổ xem log không đồng nghĩa điều khiển được Flutter. Phím điều khiển cần gửi đến terminal/phiên đang chạy lệnh Flutter.

## 3. `run-visible.py` làm gì bên trong?

File [`scripts/run-visible.py`](../../scripts/run-visible.py) là công cụ quan sát quá trình chạy, không phải test riêng của Flutter hoặc backend.

```text
Đọc tham số
  → xác định thư mục chạy
  → tạo thư mục log local riêng tư
  → kiểm tra cửa sổ Kitty viewer
  → mở viewer nếu chưa có
  → tạo PTY và chạy lệnh con
  → đọc từng phần output
  → ghi cùng nội dung ra terminal, session.log và log của lượt chạy
  → đợi tiến trình con kết thúc
  → ghi mã thoát
```

| Phần source | Tác dụng |
| --- | --- |
| `argparse` | Phân tích `--name`, `--cwd`, `--url` và lệnh sau `--` |
| `Path(__file__).resolve().parents[1]` | Tính gốc dự án dựa trên vị trí script, không phụ thuộc tên người dùng |
| `fcntl.flock` | Khóa file để nhiều lần chạy không mở trùng viewer |
| `ensure_viewer()` | Bảo đảm đã có cửa sổ Kitty trước khi chạy kiểm tra |
| `pty.openpty()` | Tạo cặp pseudo-terminal để lệnh con hoạt động giống chạy trong terminal |
| `subprocess.Popen` | Khởi động lệnh con |
| `select.select` | Đợi output/input sẵn sàng mà không phải đọc mù |
| `emit(...)` | Phản chiếu cùng output ra các nơi lưu/xem log |
| `signal` | Chuyển Ctrl-C/tín hiệu dừng tới nhóm tiến trình con của lượt chạy |
| `process.wait()` | Lấy mã kết thúc của lệnh con |
| `os.umask(0o077)` | Thiết lập quyền mặc định hạn chế cho file/thư mục được tạo |

Log ở `.local/visible-tests/`. `session.log` ghép nhiều lượt; file có timestamp/PID lưu một lượt. Mã thoát `0` thường là thành công; khác `0` cần đọc lỗi của lệnh thực tế. Nhãn bắt đầu/kết thúc giúp phân biệt test với log của app chạy lâu.

`--url` là tùy chọn mở URL bằng Chrome. Không cần dùng nó cho app Android này; dự án hiện chưa dùng Flutter Web. Khi không mở được Kitty, script báo lỗi và chưa chạy lệnh kiểm tra; không coi đây là một bài test đã chạy thành công.

## 4. Hiểu `start-backend.sh` từng bước

Đọc [`scripts/start-backend.sh`](../../scripts/start-backend.sh) theo thứ tự sau:

| Câu lệnh/nhóm lệnh | Giải thích |
| --- | --- |
| `#!/usr/bin/env bash` | Nhờ `env` tìm Bash trên `PATH` để chạy script |
| `set -euo pipefail` | Dừng khi lệnh cần thiết lỗi, khi dùng biến chưa đặt, hoặc khi pipeline có thành phần lỗi |
| Tính `project_dir` từ `${BASH_SOURCE[0]}` | Tìm gốc dự án theo đường dẫn script |
| `cd "$project_dir"` | Đảm bảo các đường dẫn `.env`, Compose và `backend/` đúng |
| Kiểm tra `.env` tồn tại | Dừng với hướng dẫn nếu chưa cấu hình; không tự dùng mật khẩu mặc định |
| `systemctl --user is-active --quiet ...` | Nếu đúng service đã chạy thì dùng lại và thoát thành công |
| `curl --silent --max-time 2 ...` | Kiểm tra có server trả lời trên cổng API trước khi mở thêm |
| `docker compose up -d --wait mysql` | Chạy MySQL ở nền và chờ healthy |
| Đọc major version từ `java -version` | Chọn giá trị override Maven tương ứng Java đang cài |
| `(cd backend && mvn ... -DskipTests package)` | Build JAR trong backend; thư mục đổi chỉ trong subshell; lần build này bỏ bước thực thi test |
| `systemctl --user reset-failed ...` | Xóa trạng thái lỗi cũ của đúng service nếu có |
| `systemd-run --user --unit=... --collect ...` | Tạo service user chạy Java và thu dọn unit khi hoàn tất |
| `WorkingDirectory=.../backend` | Chọn thư mục làm việc để config và upload tương đối đúng |
| `EnvironmentFile=.../.env` | Đưa cấu hình local vào môi trường backend, không cần in ra terminal |
| `--setenv=LOGGING_LEVEL_ROOT=INFO` và `DEBUG=false` | Chọn log vừa đủ cho backend chạy local |
| `java -jar ...jar` | Thực thi ứng dụng đã đóng gói |
| Vòng lặp thăm `/api/branches` | Đợi API sẵn sàng; báo nếu service dừng hoặc hết thời gian chờ |

`-DskipTests package` không chứng minh test đã đạt. Bạn vẫn phải chạy lệnh Maven `test` ở phần 6 khi cần xác nhận thay đổi. Nếu service đã chạy, script thoát sớm nên sửa `.java` rồi chỉ chạy lại script có thể vẫn đang dùng JAR cũ.

## 5. Cập nhật backend đúng service

### Xem log backend

```bash
python3 scripts/run-visible.py --name "Log backend" -- journalctl --user -u cstore-mobile-backend.service -f
```

| Tham số | Ý nghĩa |
| --- | --- |
| `journalctl` | Đọc journal do systemd quản lý |
| `--user` | Đọc service của tài khoản hiện tại |
| `-u cstore-mobile-backend.service` | Chỉ chọn service backend của dự án |
| `-f` | Theo dõi log mới liên tục |

Ctrl-C ở phiên này dừng theo dõi journal, không tự dừng backend. Nếu cần xem phần gần nhất rồi trả prompt, thay `-f` bằng `-n 80 --no-pager`.

### Khi đã sửa code/config backend và cần nạp lại

```bash
python3 scripts/run-visible.py --name "Dừng backend để cập nhật" -- systemctl --user stop cstore-mobile-backend.service
python3 scripts/run-visible.py --name "Build và chạy backend mới" -- ./scripts/start-backend.sh
```

Dòng đầu dừng đúng service dự án. Dòng sau build source mới và chạy lại. Trong khoảng giữa, app có thể hiện lỗi kết nối vì API đang dừng; dữ liệu MySQL không bị xóa bởi hai lệnh này.

Không dùng lệnh dừng toàn bộ Java/Dart trên máy. Không xóa volume dữ liệu để giải quyết lỗi build hoặc lỗi cổng. Nếu backend không chạy dưới đúng service này, xác minh tiến trình trước khi thao tác.

## 6. Maven: test và đóng gói

### Kiểm thử backend

Máy của dự án hiện có Java 25:

```bash
python3 scripts/run-visible.py --name "Backend tests" --cwd backend -- mvn -Djava.version=25 test
```

| Thành phần | Tác dụng |
| --- | --- |
| `--cwd backend` | Maven cần đứng ở thư mục có `pom.xml` |
| `mvn` | Chương trình Maven |
| `-Djava.version=25` | Đặt property `java.version` cho lần chạy này; không sửa vĩnh viễn POM |
| `test` | Chạy các giai đoạn cần thiết để biên dịch source/test và thực thi test |

Nếu máy khác dùng Java 21 tương ứng POM, dùng giá trị phù hợp môi trường đó. Không sao chép số 25 mà bỏ qua kết quả `java -version`.

Các bài test backend cấu hình H2 trong bộ nhớ và dữ liệu test riêng. Thông báo `BUILD SUCCESS` cùng kết quả test mới cho biết lượt Maven đạt; đọc cả số failed/errors/skipped. H2 không thay cho bài kiểm thử MySQL thật.

### Đóng gói backend

```bash
python3 scripts/run-visible.py --name "Đóng gói backend" --cwd backend -- mvn -Djava.version=25 package
```

`package` tạo JAR và theo lifecycle bình thường cũng chạy test. Lệnh này **chưa khởi chạy** JAR mới và **chưa thay** service đang chạy. Script khởi động backend đã làm bước package có bỏ thực thi test để không chạy lại mọi bài mỗi lần bật service.

## 7. Flutter: cài dependency, format, analyze và test

### Lấy dependency

```bash
python3 scripts/run-visible.py --name "Flutter dependencies" --cwd mobile -- flutter pub get
```

`pub get` đọc `pubspec.yaml` và lockfile để lấy các dependency phù hợp. Dùng sau khi checkout/cài máy mới hoặc thay dependency. Nó không có nghĩa bạn đã kiểm thử UI. Không xóa lockfile/cache theo thói quen khi chỉ sửa vài dòng Dart.

### Format source Dart

```bash
python3 scripts/run-visible.py --name "Định dạng Dart" --cwd mobile -- dart format lib test integration_test
```

`dart format` viết lại khoảng trắng, xuống dòng và dấu phẩy theo formatter. Các tham số sau `format` là thư mục/file cần định dạng. Lệnh có thể thay đổi file source nhưng không có mục đích đổi nghiệp vụ.

Nếu `dart` không nằm trong `PATH` mà `flutter` có, xác định đường dẫn đúng trước; không hardcode tên người dùng cũ. Phiên bản formatter phụ thuộc SDK đang cài. Nhiều dòng UI vẫn cần được tách thành widget/method có nghĩa; chỉ formatter không tự làm một file lớn trở nên dễ học.

### Phân tích tĩnh

```bash
python3 scripts/run-visible.py --name "Flutter analyze" --cwd mobile -- flutter analyze
```

Lệnh đọc source, tìm lỗi kiểu dữ liệu, import và các vấn đề theo lint. Không mở emulator và không gọi toàn bộ API nghiệp vụ chỉ vì `analyze` thành công.

### Toàn bộ unit/widget test

```bash
python3 scripts/run-visible.py --name "Flutter tests" --cwd mobile -- flutter test
```

Mặc định chạy các bài trong `mobile/test/`. Các bài có thể dùng HTTP client giả lập để kiểm tra UI và logic nhanh, nên không coi đây là bằng chứng MySQL/GPS/OAuth thật đều đã hoạt động.

### Chọn một nhóm test

```bash
python3 scripts/run-visible.py --name "Kiểm thử tài khoản" --cwd mobile -- flutter test test/account_test.dart test/profile_test.dart
```

Các đường dẫn sau `test` giới hạn file cần chạy. Đây là cách kiểm tra một phần đang sửa; báo rõ phạm vi thay vì gọi kết quả một nhóm là “toàn bộ ứng dụng đã được kiểm thử”.

## 8. Flutter run và phím cập nhật

| Phím trong phiên Flutter tương tác | Tác dụng | Dữ liệu UI trong RAM |
| --- | --- | --- |
| `r` | Hot reload code Dart phù hợp | Cố giữ đối tượng State/phiên hiện có |
| `R` | Hot restart ứng dụng Dart | Tạo lại state từ đầu; có thể phải đăng nhập lại |
| `h` | Xem trợ giúp phím | Không chủ động reset state |
| `d` | Tách Flutter CLI khỏi app đang chạy | App có thể tiếp tục chạy trên thiết bị |
| `q` | Thoát phiên và dừng app theo Flutter run | Không phải lệnh dừng MySQL/backend |

Hot reload không áp dụng được mọi thay đổi cấu trúc class/const. Nó cũng không nạp lại plugin native, dependency Android hoặc cấu hình build. Khi cần, dùng hot restart hoặc dừng đúng phiên rồi `flutter run` lại. Đừng mở phiên Flutter thứ hai khi phiên cũ vẫn đang dùng đúng app.

### Đổi API lúc build/run

```bash
python3 scripts/run-visible.py --name "Android API local" --cwd mobile -- flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`--dart-define=TEN=GIATRI` cung cấp giá trị compile-time cho `String.fromEnvironment`. Nó không phải một HTTP header và không tự sửa `.env` backend.

| Địa chỉ | Đang nhìn từ đâu? |
| --- | --- |
| `127.0.0.1:8080` trên Linux host | Backend chạy trên chính máy phát triển |
| `10.0.2.2:8080` trong Android emulator chuẩn | Đường emulator dùng để liên hệ host |
| `127.0.0.1` trong app trên emulator | Chính emulator, không phải Linux host |
| IP LAN của máy phát triển | Có thể dùng cho điện thoại vật lý nếu mạng/server cho phép |

Cleartext HTTP local được bật ở manifest debug. Không suy ra bản release đã có cùng cấu hình mạng hoặc có thể dùng nguyên URL local để phát hành.

### Build APK mà chưa chạy app

```bash
python3 scripts/run-visible.py --name "Build Android debug" --cwd mobile -- flutter build apk --debug
```

`build apk` tạo gói Android; `--debug` chọn chế độ debug. Nó không tự chứng minh bạn đã cài, mở và kiểm tra các màn. Artifact build có thể dùng để cài/chạy, nhưng source mới là nơi đọc và chỉnh chức năng.

## 9. Kiểm thử API và Android có dữ liệu thật

### 9.1. API/MySQL

```bash
python3 scripts/run-visible.py --name "API tích hợp" -- python3 scripts/test-live.py
```

Điều kiện: backend đã sẵn sàng, MySQL hoạt động và cấu hình tài khoản admin local đúng. Python gửi HTTP đến `CSTORE_API_URL` nếu có, mặc định là `http://127.0.0.1:8080`.

Script đăng nhập admin trong bộ nhớ, tạo các bản ghi QA có tên riêng, upload ảnh, kiểm tra báo phí đường bộ, giữ/trừ/hoàn tồn, đơn COD, tranh chấp checkout/claim và quyền truy cập. Nó không reset database. Báo cáo và thông tin đăng nhập QA được ghi riêng trong `.local/`; không chép nội dung chứa mật khẩu vào chat hay commit.

### 9.2. Kiểm tra riêng một số quy tắc API

```bash
python3 scripts/run-visible.py --name "API thương hiệu" -- python3 scripts/test-admin-brands-live.py
python3 scripts/run-visible.py --name "API hồ sơ và avatar" -- python3 scripts/test-ui-refinements-live.py
```

Bài thương hiệu tạo/xóa tài nguyên QA riêng để thử vòng đời thương hiệu/chi nhánh. Bài hồ sơ tạo tài khoản QA, kiểm tra ngày tạo và đổi/xóa ảnh. Đây là thao tác API thật, không phải unit test; cần backend/MySQL đang chạy.

### 9.3. Smoke test Android không cần tài khoản QA

```bash
python3 scripts/run-visible.py --name "Android đăng nhập và cuộn" --cwd mobile -- flutter test integration_test/auth_scroll_smoke_test.dart -d emulator-5554
```

Lệnh chọn đúng file integration test và thiết bị. Bài này kiểm tra UI đăng nhập/đăng ký, cuộn, vị trí logo và validation; không thực hiện xác thực OAuth tài khoản thật.

### 9.4. Android E2E có backend thật

Sau khi bài API đã chuẩn bị dữ liệu QA:

```bash
python3 scripts/run-visible.py --name "Android luồng mua hàng" -- python3 scripts/test-android-live.py
python3 scripts/run-visible.py --name "Android admin" -- python3 scripts/test-android-live.py --admin
python3 scripts/run-visible.py --name "Android hồ sơ" -- python3 scripts/test-android-live.py --profile
python3 scripts/run-visible.py --name "Android tinh chỉnh UI" -- python3 scripts/test-android-live.py --refinements
```

| Tùy chọn | File/nhóm được chọn bởi runner |
| --- | --- |
| Không có cờ mode | `integration_test/live_commerce_test.dart` |
| `--admin` | `integration_test/create_partner_test.dart` |
| `--profile` | `integration_test/profile_test.dart` |
| `--refinements` | `integration_test/ui_refinements_test.dart` |

Runner tìm `flutter` và `adb` trên `PATH` hoặc theo biến `FLUTTER`/`ADB`, chọn thiết bị theo `ANDROID_SERIAL` hoặc mặc định emulator. Nó đọc credentials QA từ file local để truyền cho bài kiểm thử, không yêu cầu bạn gõ mật khẩu vào nhãn lệnh.

Runner cũng chép ảnh QA vào thư viện Android, chọn thumbnail khi bài kiểm thử yêu cầu và mô phỏng tọa độ emulator. Nó cố lưu/khôi phục GPS ban đầu nếu đọc được. Kết quả này không chứng minh camera/GPS trên điện thoại vật lý đã được thử.

Ví dụ chọn thiết bị khác, chỉ dùng khi ID đó có trong `adb devices`:

```bash
ANDROID_SERIAL=emulator-5554 python3 scripts/run-visible.py --name "Android thiết bị đã chọn" -- python3 scripts/test-android-live.py
```

Biến được đặt phía trước wrapper sẽ truyền vào tiến trình con. Không đặt mật khẩu/token ở vị trí tương tự trong lệnh có thể bị ghi history/log.

## 10. Docker Compose: hiểu các cờ đang dùng

```bash
python3 scripts/run-visible.py --name "MySQL sẵn sàng" -- docker compose up -d --wait mysql
```

| Phần | Ý nghĩa |
| --- | --- |
| `docker` | Docker CLI |
| `compose` | Nhóm lệnh đọc cấu hình nhiều service |
| `up` | Tạo/chạy service theo cấu hình |
| `-d` | Chạy container ở nền |
| `--wait` | Đợi service ở trạng thái chạy/healthy phù hợp |
| `mysql` | Chỉ chọn service MySQL trong file Compose của dự án |

Trong [`docker-compose.yml`](../../docker-compose.yml):

| Dòng cấu hình | Giải thích |
| --- | --- |
| `image: mysql:8.4` | Dùng image thuộc nhánh/tag được khai báo; không phải phiên bản Java |
| `container_name` | Tên container để nhận diện đúng database dự án |
| `restart: unless-stopped` | Chính sách tự chạy lại theo Docker, trừ trường hợp đã dừng chủ động |
| `environment` | Chuyển cấu hình DB vào container |
| `${TEN_BIEN:?thong-bao}` | Yêu cầu biến đã được đặt, nếu thiếu thì Compose báo lỗi |
| `127.0.0.1:3307:3306` | Cổng 3307 trên loopback host trỏ tới MySQL 3306 trong container |
| Volume tại `/var/lib/mysql` | Giữ các file dữ liệu database |
| `healthcheck.test` | Lệnh kiểm tra MySQL đang đáp ứng |
| `interval`, `timeout`, `retries` | Nhịp kiểm tra, thời gian chờ và số lần thử |

Không cần bật/tắt container sau mỗi `flutter analyze`. Lệnh kiểm tra source Dart không sử dụng MySQL. Không xóa volume khi mục tiêu chỉ là build lại backend.

## 11. Cấu hình backend: tên nào có tác dụng gì?

Không đưa giá trị bí mật vào tài liệu, ảnh chụp terminal hay nhãn `--name`. Bảng dưới chỉ mô tả **tên biến**, nơi dùng và ý nghĩa.

| Tên/cấu hình | Nơi dùng | Ý nghĩa |
| --- | --- | --- |
| `MYSQL_ROOT_PASSWORD` | Docker Compose | Mật khẩu tài khoản quản trị MySQL trong container |
| `MYSQL_PASSWORD` | Compose và Spring datasource | Mật khẩu user DB của ứng dụng |
| `JWT_SECRET` | Backend security | Khóa chữ ký JWT C-Store; source yêu cầu tối thiểu 32 ký tự |
| `ADMIN_EMAIL` | Bootstrap backend và runner QA | Email admin cần tạo nếu chưa tồn tại |
| `ADMIN_PASSWORD` | Bootstrap backend và runner QA | Mật khẩu admin khi tạo ban đầu; source kiểm tra 12–72 ký tự |
| `UPLOAD_DIR` | Backend lưu ảnh | Thư mục chứa file upload; mặc định tương đối `./uploads` |
| `ROUTING_BASE_URL` | Backend định tuyến | OSRM endpoint; có mặc định trong source |
| `GOOGLE_CLIENT_ID` | Backend xác minh Google | Audience/client được chấp nhận |
| `CSTORE_GOOGLE_CLIENT_ID` | Backend | Tên fallback của cấu hình Google theo source |
| `FACEBOOK_APP_ID` | Backend xác minh Facebook | App Facebook tương ứng |
| `FACEBOOK_APP_SECRET` | Chỉ backend | Bí mật để kiểm tra chứng cứ Facebook; không đưa vào app |
| `CSTORE_FACEBOOK_CLIENT_ID` | Backend | Tên fallback của App ID |
| `CSTORE_FACEBOOK_CLIENT_SECRET` | Backend | Tên fallback của App Secret |
| `FACEBOOK_GRAPH_VERSION` | Backend | Phiên bản đường dẫn Graph API; source có mặc định |
| `DEBUG` | Spring Boot | Bật/tắt chế độ debug logging của framework |
| `LOGGING_LEVEL_ROOT` | Spring Boot | Mức log gốc theo cấu hình môi trường |

`application.yml` khai báo `spring.config.import: optional:file:../.env[.properties]`. Khi backend làm việc trong thư mục `backend/`, đường dẫn này tìm `.env` ở gốc dự án. `optional` cho phép vị trí import không tồn tại; các cấu hình bắt buộc khác vẫn có thể khiến ứng dụng khởi động lỗi nếu thiếu.

`start-backend.sh` còn chuyển file đó vào service qua `EnvironmentFile`. Đổi `.env` không tự thay môi trường của tiến trình Java đã khởi động: cần khởi động lại đúng service. Dữ liệu admin đã tồn tại không bị đổi mật khẩu chỉ vì đổi biến bootstrap; xem luồng bootstrap để biết điều kiện tạo tài khoản.

Các giá trị không bí mật trong YAML gồm cổng API 8080, URL datasource host 3307, tên database, user DB, giới hạn multipart 5 MB/file và 6 MB/request. Giới hạn request lớn hơn file vì multipart còn có metadata.

## 12. Cấu hình app và runner

| Tên | Đọc ở đâu/lúc nào? | Tác dụng |
| --- | --- | --- |
| `API_BASE_URL` | Dart, compile-time | Gốc API; client tự nối `/api` và path chức năng |
| `MAP_TILE_URL` | Dart, compile-time | Mẫu URL tile nền bản đồ |
| `GEOCODING_URL` | Dart, compile-time | Endpoint reverse-geocoding |
| `GOOGLE_SERVER_CLIENT_ID` | Dart, compile-time | Server client ID Google dùng trong đăng nhập native |
| `FACEBOOK_APP_ID` | Dart và Gradle | Cấu hình nhận diện Facebook app |
| `FACEBOOK_CLIENT_TOKEN` | Dart và resource Android | Cấu hình client cần cho SDK; không phải App Secret backend |
| `ANDROID_SERIAL` | Runner Python/ADB | Chọn thiết bị Android |
| `FLUTTER` | Runner Python | Tên/đường dẫn executable Flutter nếu không dùng mặc định `PATH` |
| `ADB` | Runner Python | Tên/đường dẫn executable ADB |
| `ANDROID_HOME`/`ANDROID_SDK_ROOT` | Công cụ Android | Vị trí Android SDK khi môi trường cần |
| `CSTORE_API_URL` | Bài API Python | API nhìn từ máy host; khác với URL nhìn từ emulator |

Không dùng `.env` backend để mong `String.fromEnvironment` trong app tự đổi. Flutter cần nhận đúng cấu hình build. Những biến compile-time không được cập nhật chỉ bằng đổi nội dung một file bên ngoài app đang chạy.

Khi sử dụng một file cấu hình public client riêng:

```bash
python3 scripts/run-visible.py --name "Android cấu hình local" --cwd mobile -- flutter run -d emulator-5554 --dart-define-from-file=social-auth.local.json
```

File trên thuộc `mobile/` và đã được gitignore. Lệnh chỉ nêu **tên file**, không in nội dung hay giá trị cấu hình vào terminal. Không đưa App Secret backend vào file compile-time của ứng dụng.

## 13. ADB: các lệnh thường gặp trong dự án

| Lệnh | Đọc như thế nào? |
| --- | --- |
| `adb devices` | Liệt kê thiết bị kết nối |
| `adb -s emulator-5554 ...` | Chỉ định thiết bị cho thao tác sau |
| `adb shell ...` | Chạy lệnh bên trong Android |
| `adb push <file-host> <file-android>` | Chép file từ host tới Android |
| `adb pull <file-android> <file-host>` | Chép file từ Android về host |
| `adb exec-out screencap -p` | Xuất ảnh màn hình PNG ra stdout, cần lưu nhị phân đúng cách |
| `adb shell pm grant ...` | Cấp quyền cho package trong điều kiện hệ thống cho phép |
| `adb emu geo fix <kinh-do> <vi-do>` | Gửi tọa độ mô phỏng cho emulator; chú ý thứ tự |
| `adb shell uiautomator dump ...` | Lưu cây UI native để runner tìm phần tử, ví dụ thumbnail ảnh |

Không gõ nguyên placeholder có dấu `<...>` vào shell. Runner đã thực hiện những bước cần thiết cho các bài Android, nên không phải tự cấp quyền/bơm GPS thủ công trước mọi lượt.

## 14. Đọc kết quả và tìm lỗi theo tầng

| Hiện tượng | Kiểm tra phần nào trước? |
| --- | --- |
| Không mở được Kitty | Cài executable/phiên đồ họa; wrapper chưa chạy bài test |
| `flutter`/`adb` not found | `PATH` và vị trí SDK; dùng `command -v` |
| Cổng 8080 đã bị chiếm | Xác minh service/PID/cwd, dùng lại đúng backend nếu phù hợp |
| Backend khởi động lỗi datasource | MySQL healthy, cổng 3307, cấu hình và log service |
| Build Java không hỗ trợ release | `java -version` và property `-Djava.version` |
| App báo không kết nối API | Backend có chạy, URL nhìn từ emulator, manifest debug và mạng |
| 401 | Phiên/thông tin đăng nhập/token hết hiệu lực; không vội sửa quyền endpoint |
| 403 | Vai trò, tài khoản bị hạn chế hoặc điều kiện nghiệp vụ |
| 409 khi tranh hàng/nhận đơn | Có thể là kết quả đúng bảo vệ dữ liệu; đọc test/response cụ thể |
| Tile không tải nhưng GPS có tọa độ | Nền bản đồ và GPS là hai nguồn độc lập |
| Không lấy được phí/tuyến | Dịch vụ OSRM, timeout, vị trí ghim gần đường; không tự thay bằng khoảng cách chim bay |
| Hot reload rejected | Thay đổi class/native không phù hợp; đọc thông báo để chọn restart cần thiết |
| Widget test đạt nhưng Android lỗi plugin | Test widget không thực thi đầy đủ native SDK; kiểm tra integration test/log thiết bị |

Khi báo kết quả, ghi tên bài kiểm tra, thành công/thất bại, đường dẫn log và phần chưa thử. Không lấy một dòng “Built APK” làm bằng chứng mọi chức năng đã chạy đúng.

## 15. Một buổi học source có thể đi như sau

1. Mở [mục lục hướng dẫn](README.md) và chọn một luồng, ví dụ đăng nhập.
2. Mở widget có nút tương ứng, tìm callback của nút.
3. Theo method state/API đến endpoint backend và service.
4. Đọc DTO/entity/repository liên quan; ghi lại dữ liệu vào/ra.
5. Chạy nhóm test liên quan qua `run-visible.py` và đọc cả nhãn lẫn kết quả.
6. Thử đổi nhỏ một thông báo hoặc tên biến có phạm vi rõ, format/analyze/test lại.
7. Khi chưa hiểu một ký hiệu, tra [thuật ngữ](thuat-ngu.md) thay vì đoán từ tên tiếng Anh.

Mục tiêu là hiểu một thao tác đi qua các lớp như thế nào. Khi biết rõ vai trò mỗi file, bạn có thể đọc sâu từng câu lệnh mà không bị lẫn code dựng giao diện với code ghi dữ liệu.


## Tạo lại biểu tượng Android từ ảnh mới

Ảnh nguồn nằm ở `mobile/branding/app.png`. Từ gốc dự án:

```bash
python3 scripts/run-visible.py --name tao-icon-android -- java -Djava.awt.headless=true scripts/GenerateAppIcons.java
```

Công cụ log nhận phần trước `--`; Java nhận phần sau. `-Djava.awt.headless=true` cho phép xử lý ảnh bằng JDK mà không mở cửa sổ Java. File Java được chạy trực tiếp và ghi năm PNG `ic_launcher.png` vào các thư mục `mipmap-*`. Sau đó cần build/cài lại Android; hot reload Dart không cập nhật icon native. Không cần gỡ ứng dụng hoặc reset dữ liệu. Giải thích từng bước và kích thước ở [tài liệu icon](../../mobile/branding/README.md).
