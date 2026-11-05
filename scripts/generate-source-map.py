#!/usr/bin/env python3
"""Tạo bản đồ file/class/hàm từ source; không duyệt artifact hoặc đọc .env."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'docs/huong-dan/ban-do-source.md'


def purpose(path):
    """Mô tả trách nhiệm thư mục, không suy đoán nội dung nghiệp vụ của hàm."""
    value = str(path)
    if value.startswith(('backend/src/test/', 'mobile/test/')):
        return 'Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.'
    if value.startswith('mobile/integration_test/'):
        return 'Test tích hợp chạy trên thiết bị/emulator.'
    if value.startswith('mobile/android/'):
        return 'Cấu hình hoặc mã nền tảng Android.'
    if value.endswith('CStoreApplication.java'):
        return 'Điểm vào Java: khởi tạo ứng dụng Spring Boot và quét các package con.'
    if value == 'mobile/lib/main.dart':
        return 'Điểm vào Dart: gắn widget gốc của Flutter vào màn hình.'
    groups = {
        '/controller/': 'Điểm vào REST API: URL, request và response.',
        '/service/': 'Xử lý nghiệp vụ hoặc dịch vụ dùng lại trên server.',
        '/repository/': 'Truy vấn database và các khóa bản ghi.',
        '/entity/': 'Ánh xạ đối tượng Java sang bảng và quan hệ database.',
        '/dto/': 'Kiểu dữ liệu truyền vào/ra API.',
        '/config/': 'Đăng ký và cấu hình các thành phần Spring.',
        '/security/': 'Kiểm chứng danh tính đăng nhập nhà cung cấp.',
        '/mapper/': 'Dựng dữ liệu công khai trả về client.',
        '/support/': 'Hàm hỗ trợ nhỏ dùng chung.',
        '/exception/': 'Chuyển ngoại lệ thành phản hồi HTTP.',
        '/models/': 'Kiểu dữ liệu ứng dụng hoặc model của một màn hình.',
        '/services/state/': 'Dữ liệu RAM và nhóm thao tác của AppState.',
        '/services/api/': 'Giao tiếp HTTP/JSON, endpoint và upload.',
        '/services/': 'Dịch vụ ứng dụng hoặc file export tương thích.',
        '/app/theme/': 'Giao diện chung: màu, font, khoảng cách, kiểu widget.',
        '/app/': 'Widget gốc và điều hướng theo phiên/vai trò.',
        '/screens/': 'Trang giao diện, tab hoặc thành phần của trang.',
        '/widgets/': 'Thành phần giao diện có thể dùng lại.',
        '/test/': 'Test tự động; không phải dữ liệu nghiệp vụ khi app chạy.',
        '/integration_test/': 'Test tích hợp chạy trên thiết bị/emulator.',
        '/android/': 'Cấu hình hoặc mã nền tảng Android.',
    }
    for marker, description in groups.items():
        if marker in '/' + value:
            return description
    if value.startswith('scripts/'):
        return 'Công cụ terminal: chạy, kiểm thử hoặc tạo tài liệu.'
    if value.startswith('database/'):
        return 'Script SQL; đọc trước khi thực thi vì có thể thay dữ liệu.'
    if path.suffix in ('.yml', '.yaml', '.xml', '.properties', '.kts'):
        return 'Cấu hình build, thư viện hoặc dịch vụ.'
    return 'Điểm khởi động hoặc cấu hình ở gốc thành phần.'


def declarations(text, suffix):
    """Chỉ lấy tên khai báo, không chép giá trị cấu hình/token ra tài liệu."""
    found = []
    for number, line in enumerate(text.splitlines(), 1):
        if suffix in ('.dart', '.java'):
            for match in re.finditer(r'\b(class|enum|record|interface)\s+(\w+)', line):
                if line.lstrip().startswith(('//', '*')):
                    continue
                found.append((number, match.group(1) + ' ' + match.group(2)))
            getter = re.match(r'^\s*[\w<>?,.\[\] ]+\s+get\s+(\w+)\s*(?:=>|\{)', line)
            if getter:
                found.append((number, 'getter ' + getter.group(1)))
            if suffix == '.dart':
                method = re.match(r'^\s*(?:[\w$<>?,.\[\]]+\s+)+(\w+)\s*\(', line)
            else:
                method = re.match(r'^\s*(?:(?:public|protected|private|static|final|synchronized|abstract|default)\s+)*(?:[\w$<>?,.\[\]]+\s+)+(\w+)\s*\(', line)
            if method and line.strip().split()[0] not in {
                'return', 'throw', 'new', 'await', 'yield', 'case', 'else', 'const'
            }:
                found.append((number, method.group(1) + '()'))
        elif suffix == '.py':
            match = re.match(r'^(?:async\s+)?def\s+(\w+)\s*\(', line)
            if match:
                found.append((number, match.group(1) + '()'))
    return found


def files():
    selected = set()
    for folder, suffixes in (
        ('backend/src', {'.java', '.yml', '.yaml', '.properties'}),
        ('mobile/lib', {'.dart'}),
        ('mobile/test', {'.dart'}),
        ('mobile/integration_test', {'.dart'}),
        ('database', {'.sql'}),
    ):
        for path in (ROOT / folder).rglob('*'):
            if path.is_file() and path.suffix in suffixes:
                selected.add(path)
    for path in (ROOT / 'scripts').iterdir():
        if path.is_file() and path.suffix in ('.py', '.sh', '.java'):
            selected.add(path)
    for name in ('backend/pom.xml', 'mobile/pubspec.yaml', 'mobile/analysis_options.yaml', 'docker-compose.yml'):
        path = ROOT / name
        if path.is_file():
            selected.add(path)
    android = ROOT / 'mobile/android'
    for name in ('build.gradle.kts', 'settings.gradle.kts', 'gradle.properties', 'app/build.gradle.kts'):
        path = android / name
        if path.is_file():
            selected.add(path)
    for folder in ('app/src/main', 'app/src/debug', 'app/src/profile'):
        for path in (android / folder).rglob('*'):
            if path.is_file() and path.suffix in ('.kt', '.java', '.xml'):
                selected.add(path)
    return sorted(selected)


def main():
    paths = files()
    content = [
        '# Bản đồ toàn bộ mã nguồn',
        '',
        'Tệp này được sinh từ source hiện tại. Số dòng là mốc để mở file, không phải thứ tự thực thi.',
        'Danh sách khai báo là công cụ tìm nhanh; chương backend/mobile giải thích nghiệp vụ của chúng.',
        'Bộ nhận diện liệt kê các khai báo đặt tên trong source, không phải trình phân tích cú pháp đầy đủ cho mọi lambda/biểu thức ẩn danh.',
        'File chỉ có `export` là điểm import chung, không phải chức năng bị xóa.',
        '',
        'Cập nhật từ gốc dự án:',
        '',
        '```bash',
        'python3 scripts/run-visible.py --name cap-nhat-ban-do-source -- python3 scripts/generate-source-map.py',
        '```',
        '',
        f'Tổng cộng **{len(paths)} file source/cấu hình**. Không bao gồm ảnh nhị phân, .env, QA credentials hoặc artifact sinh tự động.',
        '',
    ]
    for path in paths:
        relative = path.relative_to(ROOT)
        text = path.read_text()
        content += [
            '## ' + str(relative),
            '',
            f'[Mở source](../../{relative.as_posix()}) · {len(text.splitlines())} dòng.',
            '',
            purpose(relative),
            '',
        ]
        names = declarations(text, path.suffix)
        if names:
            content += ['| Dòng | Khai báo để tìm |', '| --- | --- |']
            content += [f'| {line} | `{name}` |' for line, name in names]
            content.append('')
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text('\n'.join(content))
    print(f'Đã tạo {OUTPUT.relative_to(ROOT)}: {len(paths)} file.')


if __name__ == '__main__':
    main()
