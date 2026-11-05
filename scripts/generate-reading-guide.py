#!/usr/bin/env python3
"""Tạo chương đọc từng dòng từ source thật và chú giải biên soạn riêng.

Chỉ đọc danh sách Java/Dart được khai báo bên dưới. Không đọc cấu hình bí mật,
artifact hay toàn bộ cây dự án. Nếu câu lệnh thay đổi, dừng để người viết cập
nhật chú giải; không tự gán một lời giải thích cũ cho code mới.
"""

from dataclasses import dataclass
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'docs/huong-dan/doc-tung-dong.md'
JAVA = 'backend/src/main/java/com/cstore/app/'


def skip_comment(source, position):
    """Bỏ comment dòng hoặc block; hỗ trợ block lồng nhau của Dart."""
    if source.startswith('//', position):
        end = source.find('\n', position)
        return len(source) if end == -1 else end
    depth = 1
    cursor = position + 2
    while cursor < len(source) and depth:
        if source.startswith('/*', cursor):
            depth += 1
            cursor += 2
        elif source.startswith('*/', cursor):
            depth -= 1
            cursor += 2
        else:
            cursor += 1
    if depth:
        raise ValueError('Comment block chưa đóng')
    return cursor


def skip_string(source, position):
    """Bỏ chuỗi Java/Dart, kể cả triple quote và nội suy ${...} của Dart."""
    quote = source[position]
    delimiter = quote * 3 if source.startswith(quote * 3, position) else quote
    raw = position > 0 and source[position - 1] in 'rR' and (
        position < 2 or not (source[position - 2].isalnum() or source[position - 2] == '_')
    )
    cursor = position + len(delimiter)
    while cursor < len(source):
        if not raw and source[cursor] == '\\':
            cursor += 2
        elif not raw and source.startswith('${', cursor):
            cursor = skip_interpolation(source, cursor + 2)
        elif source.startswith(delimiter, cursor):
            return cursor + len(delimiter)
        else:
            cursor += 1
    raise ValueError('Chuỗi chưa đóng')


def skip_interpolation(source, position):
    depth = 1
    cursor = position
    while cursor < len(source) and depth:
        if source.startswith('//', cursor) or source.startswith('/*', cursor):
            cursor = skip_comment(source, cursor)
        elif source[cursor] in "\"'":
            cursor = skip_string(source, cursor)
        else:
            if source[cursor] == '{':
                depth += 1
            elif source[cursor] == '}':
                depth -= 1
            cursor += 1
    if depth:
        raise ValueError('Nội suy chuỗi chưa đóng')
    return cursor


def structural_source(source):
    """Giữ vị trí/số dòng, thay nội dung string/comment bằng khoảng trắng."""
    masked = list(source)
    cursor = 0
    while cursor < len(source):
        if source.startswith('//', cursor) or source.startswith('/*', cursor):
            end = skip_comment(source, cursor)
        elif source[cursor] in "\"'":
            end = skip_string(source, cursor)
        else:
            cursor += 1
            continue
        for index in range(cursor, end):
            if source[index] != '\n':
                masked[index] = ' '
        cursor = end
    return ''.join(masked)


def matching_end(masked, start, opening, closing):
    depth = 0
    for cursor in range(start, len(masked)):
        if masked[cursor] == opening:
            depth += 1
        elif masked[cursor] == closing:
            depth -= 1
            if depth == 0:
                return cursor
    raise ValueError(f'Không tìm được dấu đóng {closing}')


@dataclass(frozen=True)
class Chapter:
    title: str
    path: str
    signature: str | None
    purpose: str
    outcome: str
    notes: str
    declaration: bool = False


def select_source(chapter):
    path = ROOT / chapter.path
    if path.suffix not in ('.java', '.dart'):
        raise ValueError('Chỉ cho phép đọc Java/Dart trong danh sách cố định')
    source = path.read_text()
    lines = source.splitlines()
    if chapter.signature is None:
        return lines, 1
    match = re.search(chapter.signature, source, flags=re.MULTILINE)
    if match is None:
        raise ValueError(f'Không tìm thấy hàm cần đọc: {chapter.path}')
    start = source.count('\n', 0, match.start())
    # Đưa các annotation trực tiếp của method vào đoạn trích.
    while start > 0 and lines[start - 1].lstrip().startswith('@'):
        start -= 1
    masked = structural_source(source)
    first_parenthesis = masked.index('(', match.start())
    parameter_end = matching_end(masked, first_parenthesis, '(', ')')
    if chapter.declaration:
        end = masked.index(';', parameter_end)
    else:
        body_start = masked.index('{', parameter_end)
        end = matching_end(masked, body_start, '{', '}')
    last = source.count('\n', 0, end)
    return lines[start:last + 1], start + 1


def parse_notes(text):
    result = []
    for line in text.strip().splitlines():
        code, explanation = line.strip().split(' :: ', 1)
        result.append((code, explanation))
    return result


CHAPTERS = [
    Chapter(
        'Dart bắt đầu chạy ứng dụng', 'mobile/lib/main.dart', None,
        'Đầu vào là tiến trình Android đã mở Flutter engine. File này nối entry point Dart với widget gốc.',
        'runApp gắn CStoreApp vào cây widget. Nó chưa đăng nhập hay đọc database trực tiếp.',
        """
import 'package:flutter/material.dart'; :: Nạp API Material/Flutter, trong đó có runApp dùng ở cuối file.
import 'app/app.dart'; :: Nạp CStoreApp do dự án định nghĩa; đây là file cấu hình widget gốc.
void main() { :: Điểm vào Dart; void cho biết hàm không trả một giá trị nghiệp vụ, dấu { mở thân hàm.
runApp(const CStoreApp()); :: Tạo cấu hình CStoreApp dạng const rồi giao cho Flutter dựng cây UI; không có HTTP nào được viết ở dòng này.
} :: Đóng main; vòng đời giao diện tiếp tục do Flutter quản lý sau lời gọi runApp.
""",
    ),
    Chapter(
        'Chọn giao diện theo phiên đăng nhập', 'mobile/lib/app/role_home.dart',
        r'^  Widget build\(BuildContext context\)',
        'RoleHome nhận AppState. build trả một widget phản ánh tài khoản hiện tại, không cấp quyền truy cập backend.',
        'Khi account đổi và state phát thông báo, builder chạy lại để chọn LoginPage hoặc màn hình đúng vai trò.',
        """
@override :: Method này hiện thực build của StatelessWidget; analyzer kiểm tra bạn đang ghi đè đúng giao diện.
Widget build(BuildContext context) { :: Nhận vị trí widget trong cây và trả một Widget; bắt đầu phần mô tả UI.
return ListenableBuilder( :: Trả widget chuyên nghe thay đổi, thay vì tự gọi build của các trang bằng tay.
listenable: state, :: Đăng ký nghe cùng AppState mà phiên đăng nhập đang cập nhật.
builder: (context, _) { :: Callback tạo UI mỗi khi cần; dấu _ nói tham số thứ hai không được dùng.
final account = state.account; :: Đọc tài khoản một lần cho lượt build hiện tại để các nhánh bên dưới dùng cùng giá trị.
if (account == null) return LoginPage(state: state); :: Chưa có tài khoản thì trả trang đăng nhập và truyền cùng state cho form sử dụng.
return switch (account.role) { :: Có tài khoản rồi thì switch expression chọn một widget theo role trả từ backend.
Role.customer => CustomerHome(state: state), :: Khách hàng được dẫn tới màn mua hàng, đơn và hồ sơ khách.
Role.store => StoreHome(state: state), :: Tài khoản cửa hàng mở giao diện quản lý chi nhánh/sản phẩm/đơn.
Role.shipper => ShipperHome(state: state), :: Shipper mở giao diện nhận đơn và giao hàng.
Role.admin => AdminHome(state: state), :: Admin mở giao diện quản trị; các API admin vẫn kiểm tra quyền độc lập.
}; :: Kết thúc switch expression và trả widget đã chọn cho callback builder.
}, :: Đóng callback builder; dấu phẩy kết thúc named argument của ListenableBuilder.
); :: Kết thúc constructor ListenableBuilder và câu return.
} :: Đóng build; hàm không lưu dữ liệu bền vững và có thể được Flutter gọi nhiều lần.
""",
    ),
    Chapter(
        'State điều phối đăng nhập email', 'mobile/lib/services/state/session_actions.dart',
        r'^  Future<void> login\(',
        '_SessionActions dùng cùng AppState. Đầu vào là email và password form gửi qua AppState.login.',
        'Thành công: có account và dữ liệu phiên được nạp. Thất bại: logout dọn phiên rồi rethrow để UI hiển thị lỗi.',
        """
Future<void> login( :: Hàm bất đồng bộ không trả model; mục tiêu của nó là cập nhật trạng thái phiên dùng chung.
String email, :: Email do form chuyển vào, chưa được trim tại vị trí khai báo tham số.
String password, :: Mật khẩu đầu vào; giữ nguyên nội dung, không in và không tự trim mật khẩu.
) async { :: Đóng danh sách tham số và bật cú pháp await trong thân hàm.
try { :: Bắt đầu nhóm thao tác mà nếu lỗi sẽ được dọn phiên ở catch.
app.account = await app.api.login( :: Chờ API xác thực; chỉ gán account khi lời gọi trả một Account thành công.
email.trim(), :: Bỏ khoảng trắng ở hai đầu email để tránh nhập dư khoảng trắng làm sai tài khoản.
password, :: Chuyển nguyên mật khẩu cho lớp API, không tự hash ở Flutter.
); :: Đóng lời gọi API và hoàn tất phép gán account sau await.
await app._loadSession(); :: Nạp chi nhánh/dữ liệu theo vai trò, vị trí đã lưu và polling; không coi chỉ nhận token là đã nạp xong phiên.
} catch (e) { :: Nếu API hoặc bước nạp phiên ném lỗi, chuyển sang nhánh xử lý lỗi này.
app.logout(); :: Dọn account/token/timer/giỏ và các dữ liệu phiên để không giữ một phiên đăng nhập dở dang.
rethrow; :: Gửi lại lỗi gốc cho nơi gọi, để form có thể hiển thị thông báo thích hợp.
} :: Đóng catch; nhánh lỗi không được chuyển thành một kết quả đăng nhập thành công giả.
} :: Đóng method login; Future hoàn tất khi mọi bước đã chạy hoặc lỗi đã được ném lại.
""",
    ),
    Chapter(
        'API tài khoản chọn endpoint đăng nhập', 'mobile/lib/services/api/account_api.dart',
        r'^  Future<Account> login\(',
        'Đầu vào là email/password. AccountApi biết endpoint và kiểu model; ApiClient xử lý phần HTTP chung.',
        'Response được đọc thành Map rồi chuyển sang _session. HTTP lỗi được ApiClient ném trước khi đến bước chuyển model.',
        """
Future<Account> login( :: Khai báo kết quả bất đồng bộ là Account, khác với method state chỉ trả Future<void>.
String email, :: Nhận email đã được nơi điều phối chuẩn bị.
String password, :: Nhận password để gửi trong body đăng nhập; không ghi log giá trị này.
) async { :: Mở thân method có await.
final data = await request( :: Gọi request kế thừa từ ApiClient và chờ response đã JSON decode.
'/auth/login', :: Chọn path đăng nhập; ApiClient nối thêm base và tiền tố /api.
body: {'email': email, 'password': password}, :: Tạo Map JSON với đúng hai trường backend Login DTO nhận; không gửi role để tự nâng quyền.
) as Map<String, dynamic>; :: Đóng request và yêu cầu kết quả là JSON object; response sai cấu trúc gây lỗi kiểu thay vì tạo Account tùy tiện.
return _session(data); :: Đọc user/token trong response bằng helper, trả Account cho state.
} :: Đóng lời gọi endpoint đăng nhập; logic HTTP lặp lại không nằm trong method này.
""",
    ),
    Chapter(
        'Đọc phiên backend trả về', 'mobile/lib/services/api/account_api.dart',
        r'^  Account _session\(',
        'Đầu vào là JSON object của response Session. Đây là nơi ghi token vào RAM của API client.',
        'Trả Account đã parse; token chỉ được dùng cho các request sau. File này không lưu token vào database/ổ đĩa.',
        """
Account _session( :: Helper đồng bộ trả Account; dấu _ giới hạn tên trong library Dart này.
Map<String, dynamic> data, :: Nhận object JSON có các trường user và token từ backend.
) { :: Đóng khai báo tham số, mở thân helper.
final account = Account.fromJson( :: Dựng model Account bằng factory parser, để UI không phải tự đọc từng khóa JSON.
data['user'] as Map<String, dynamic>, :: Lấy object user và xác nhận kiểu dữ liệu đầu vào của parser.
); :: Đóng lời gọi parser; lúc này account là model Dart.
token = data['token'] as String; :: Giữ JWT của C-Store trong field RAM, dùng cho Authorization header về sau; không in giá trị.
return account; :: Trả model người dùng cho method login và AppState.
} :: Đóng helper chuyển response thành phiên; thiếu/sai kiểu trường sẽ không âm thầm tạo phiên hợp lệ.
""",
    ),
    Chapter(
        'Gửi request và chuyển lỗi HTTP thành lỗi của app', 'mobile/lib/services/api/api_client.dart',
        r'^  Future<dynamic> request\(',
        'Đầu vào gồm path, body tùy chọn và method tùy chọn. Đầu ra có thể là Map/List/null sau JSON decode.',
        'Thành công trả dữ liệu; timeout, mạng, lỗi JSON hoặc status HTTP từ 400 trở lên tạo lỗi để lớp state/UI xử lý.',
        """
Future<dynamic> request( :: Helper HTTP tổng quát; dynamic vì các endpoint có thể trả object, list hoặc không có body.
String path, { :: Nhận path bắt buộc và mở nhóm named parameters bằng dấu { của danh sách tham số.
Map<String, dynamic>? body, :: Body JSON có thể null; null còn ảnh hưởng HTTP method mặc định.
String? method, :: Cho nơi gọi ghi đè HTTP method, như PUT hoặc DELETE.
}) async { :: Đóng nhóm named parameters, đóng tham số hàm và mở thân bất đồng bộ.
final uri = Uri.parse('$base/api$path'); :: Ghép base cấu hình, tiền tố /api và path chức năng thành Uri dùng cho HTTP client.
final headers = { :: Tạo Map header cho lần gửi hiện tại.
'Content-Type': 'application/json', :: Khai báo body gửi theo JSON, để backend đọc đúng định dạng.
if (token != null) 'Authorization': 'Bearer $token', :: Chỉ thêm Bearer header khi đang có token; không có token vẫn gọi được endpoint công khai.
}; :: Đóng Map header; đây không phải nội dung body JSON.
final requestMethod = method ?? (body == null ? 'GET' : 'POST'); :: Ưu tiên method tường minh; nếu thiếu, body null chọn GET, có body chọn POST.
final timeoutSeconds = path.startsWith('/customer/nearby') ? 60 : 20; :: Cho luồng tìm cửa hàng gần đây nhiều thời gian hơn vì có xử lý tuyến đường.
final response = await _send( :: Giao bước chọn hàm HTTP cụ thể cho _send và chờ response.
requestMethod, :: Truyền method đã xác định thay vì tính lại ở mỗi nhánh.
uri, :: Truyền URL đã ghép đúng prefix.
headers, :: Chuyển Content-Type và Bearer header nếu có.
body, :: Chuyển Map đầu vào để _send encode khi method cần body.
).timeout(Duration(seconds: timeoutSeconds)); :: Giới hạn thời gian chờ Future; timeout tạo lỗi, không tạo response thành công giả.
if (response.statusCode >= 400) { :: Rẽ nhánh khi server trả mã lỗi HTTP.
final serverMessage = _readErrorMessage(response); :: Thử đọc trường message của server; helper chịu được body không phải JSON hợp lệ.
throw StateError(_errorMessage( :: Chuyển status/path/message thành lỗi có lời nhắn dễ hiểu cho app.
response.statusCode, :: Dùng mã HTTP để phân biệt 401, 403, 409 và các trường hợp khác.
path, :: Dùng path để chọn thông báo phù hợp, ví dụ lỗi login khác lỗi phiên hết hạn.
serverMessage, :: Giữ thông điệp nghiệp vụ server nếu quy tắc helper cho phép.
)); :: Đóng lời gọi tạo thông báo và StateError; throw dừng nhánh success ở đây.
} :: Kết thúc xử lý HTTP lỗi.
if (response.body.isEmpty) return null; :: Chấp nhận response không có body, ví dụ 204; không JSON decode chuỗi rỗng.
return jsonDecode(utf8.decode(response.bodyBytes)); :: Giải mã byte UTF-8 để giữ chữ Việt, rồi parse JSON thành Map/List/giá trị Dart.
} :: Đóng request; phần HTTP dùng chung không quyết định quy tắc tồn kho hay quyền đơn hàng.
""",
    ),
    Chapter(
        'HTTP client thực sự chọn GET/POST/PUT/DELETE', 'mobile/lib/services/api/api_client.dart',
        r'^  Future<http.Response> _send\(',
        'Nhận method, Uri, header và Map body từ request. Method này chưa kiểm tra status hay chuyển JSON response.',
        'Trả Future<http.Response> cho request. Dữ liệu gửi đi được jsonEncode khi cần; response vẫn còn dạng HTTP.',
        """
Future<http.Response> _send( :: Helper private trả response HTTP thô, không trả model nghiệp vụ.
String method, :: Method đã được request chọn hoặc người gọi ghi đè.
Uri uri, :: URL đích đã parse.
Map<String, String> headers, :: Map header có giá trị chuỗi, như Content-Type và Authorization.
Map<String, dynamic>? body, :: Body trước khi encode, có thể null.
) { :: Mở thân helper; không cần async vì trả trực tiếp Future do HTTP client tạo.
String? encodedBody() => body == null ? null : jsonEncode(body); :: Hàm local đổi Map thành JSON string khi có body; giữ null nếu không có.
switch (method) { :: Chọn API client phù hợp theo chuỗi HTTP method.
case 'PUT': :: Nhánh cập nhật PUT.
return client.put( :: Trả Future của HTTP PUT ngay cho method gọi.
uri, :: Gửi đến đúng Uri đầu vào.
headers: headers, :: Gắn header của request, gồm token nếu phiên có.
body: encodedBody(), :: Encode body khi gửi PUT, không gửi nguyên đối tượng Map tùy tiện.
); :: Đóng lời gọi client.put và return của nhánh PUT.
case 'DELETE': :: Nhánh DELETE cho endpoint xóa/ngừng hoạt động.
return client.delete( :: Trả Future của DELETE.
uri, :: Chọn URL tài nguyên cần xóa/thao tác.
headers: headers, :: Vẫn gửi chứng cứ phiên; xóa không có nghĩa bỏ phân quyền.
); :: Đóng DELETE; triển khai này không gửi JSON body cho nhánh DELETE.
case 'POST': :: Nhánh POST dùng cho tạo tài nguyên hoặc hành động.
return client.post( :: Trả Future của HTTP POST.
uri, :: Chọn endpoint nhận dữ liệu.
headers: headers, :: Truyền metadata và Bearer nếu có.
body: encodedBody(), :: Serialize Map thành JSON string trước khi gửi POST.
); :: Đóng client.post và kết thúc nhánh POST.
default: :: Các method không khớp ba nhánh trên đi vào GET của triển khai hiện tại.
return client.get( :: Tạo yêu cầu đọc GET và trả Future tương ứng.
uri, :: URL có thể chứa query, ví dụ storeId khi đọc catalog.
headers: headers, :: GET vẫn có thể cần Bearer header ở endpoint riêng tư.
); :: Đóng client.get; không gắn body vào GET.
} :: Kết thúc switch; mỗi nhánh đã return một Future HTTP.
} :: Đóng _send; lỗi/status sẽ được phần request bên ngoài xử lý tiếp.
""",
    ),
    Chapter(
        'Tải catalog và bỏ phản hồi đã cũ', 'mobile/lib/services/state/catalog_actions.dart',
        r'^  Future<void> loadProducts\(',
        'Đọc sản phẩm của cửa hàng đăng nhập hoặc chi nhánh khách đã chọn. Danh sách server được dùng để điều chỉnh giỏ hiện tại.',
        'Chỉ response mới nhất cập nhật products. Giỏ bị loại/giảm các mục không còn bán hoặc vượt tồn; method điều phối bên ngoài quyết định lúc refresh UI.',
        """
Future<void> loadProducts() async { :: Method bất đồng bộ cập nhật catalog trong AppState, không trả một List riêng cho UI.
final revision = ++app._productsRevision; :: Tăng số thứ tự lần tải trước khi gọi mạng; giữ số của riêng lời gọi này.
final path = app.account?.role == Role.store :: Xem tài khoản có phải cửa hàng để chọn endpoint có đúng phạm vi dữ liệu.
? '/merchant/products' :: Cửa hàng đọc catalog riêng qua endpoint được xác thực và ràng buộc chi nhánh.
: '/products?storeId=${app.selected!.id}'; :: Khách đọc sản phẩm công khai theo ID chi nhánh đã chọn; nơi gọi phải bảo đảm selected tồn tại.
final loaded = [ :: Chuẩn bị List model mới, chưa xóa List đang hiển thị khi request còn chưa xong.
for (final j in await app.api.request(path) as List) :: Chờ API trả JSON array rồi lặp từng object sản phẩm.
productFromJson( :: Chuyển mỗi JSON object thành Product của app.
j as Map<String, dynamic>, :: Xác nhận mỗi phần tử là object có khóa chuỗi trước khi parse.
) :: Kết thúc parser cho một phần tử; kết quả được thêm vào collection đang tạo.
]; :: Hoàn thành List loaded sau khi toàn bộ response đã được parse.
if (revision != app._productsRevision) return; :: Nếu đã có lần tải mới/phiên mới vô hiệu hóa số thứ tự, bỏ response cũ để tránh ghi đè catalog mới.
app.products :: Chọn đúng List products dùng chung mà UI/state đang giữ.
..clear() :: Cascade xóa nội dung cũ sau khi biết response hợp lệ và còn mới.
..addAll(loaded); :: Thêm model mới vào cùng List, không để lại sản phẩm cũ ngoài response.
for (final id in app.cart.keys.toList()) { :: Chụp danh sách khóa trước khi lặp, để có thể remove khỏi Map cart bên trong mà không sửa collection đang duyệt.
final p = app.products.where((p) => p.id == id).firstOrNull; :: Tìm Product mới tương ứng từng mục trong giỏ; không tìm thấy thì p là null.
if (p == null || !p.active || p.stock == 0) { :: Mục đã biến mất, ngừng bán hoặc hết tồn không thể giữ nguyên trong giỏ.
app.cart.remove(id); :: Bỏ mục đó khỏi lựa chọn đang đặt của khách.
} else if (app.cart[id]! > p.stock) { :: Nếu còn bán nhưng số khách chọn lớn hơn tồn mới, chuyển sang nhánh giảm số lượng.
app.cart[id] = p.stock; :: Giới hạn số đang chọn bằng tồn server vừa trả; backend vẫn kiểm tra lại khi checkout.
} :: Đóng nhánh điều chỉnh số lượng mục hiện tại.
} :: Đóng vòng lặp đồng bộ giỏ theo catalog mới.
} :: Đóng loadProducts; refresh/hiển thị lỗi do luồng gọi nó phối hợp.
""",
    ),
    Chapter(
        'App gửi yêu cầu tạo đơn', 'mobile/lib/services/state/cart_order_actions.dart',
        r'^  Future<ShopOrder> checkout\(',
        'Nhận người nhận, điện thoại, địa chỉ và tọa độ đã xác nhận từ form. Giỏ chứa productId → quantity.',
        'Server thành công thì parse đơn, xóa giỏ và tải dữ liệu lại. Nếu request ném lỗi trước đó, chưa chạy dòng clear giỏ.',
        """
Future<ShopOrder> checkout( :: Method bất đồng bộ trả đúng ShopOrder server tạo, không tự tạo ID đơn ở điện thoại.
String name, :: Tên người nhận do form cung cấp.
String phone, :: Số điện thoại liên hệ người nhận.
String address, :: Địa chỉ chi tiết đã nhập/xác nhận.
double latitude, :: Vĩ độ điểm giao.
double longitude, :: Kinh độ điểm giao; khác vị trí tham số theo thứ tự GeoJSON ở OSRM.
) async { :: Mở thân checkout có các bước chờ HTTP và tải lại.
if (app.selected == null || app.cart.isEmpty) { :: Không cho tạo đơn khi chưa chọn chi nhánh hoặc giỏ rỗng.
throw StateError('Giỏ hàng trống'); :: Dừng trước khi gọi mạng, để UI báo lỗi có nghĩa.
} :: Kết thúc chặn đầu vào giỏ trống.
final data = await app.api.request( :: Chờ backend tạo đơn; method mặc định sẽ là POST vì có body.
'/customer/orders', :: Endpoint thuộc quyền khách hàng; backend có kiểm tra xác thực và nghiệp vụ.
body: { :: Mở JSON object dữ liệu checkout.
'storeId': app.selected!.id, :: Chỉ chi nhánh của giỏ đang chọn; dấu ! an toàn theo điều kiện đã kiểm tra trước đó trong luồng này.
'recipient': name, :: Ghi tên người nhận vào payload.
'phone': phone, :: Ghi số điện thoại cần để liên hệ giao hàng.
'address': address, :: Gửi địa chỉ người dùng xác nhận; không chỉ gửi một gợi ý geocoding mơ hồ.
'latitude': latitude, :: Gửi vĩ độ để backend kiểm tra tuyến và lưu điểm giao.
'longitude': longitude, :: Gửi kinh độ tương ứng.
'pinConfirmed': true, :: Khai báo form đã đi qua bước xác nhận ghim; đây không tự chứng minh vị trí GPS vật lý.
'items': [ :: Tạo mảng các dòng yêu cầu đặt hàng.
for (final e in app.cart.entries) :: Duyệt từng cặp mã sản phẩm và số lượng trong Map giỏ.
{'productId': e.key, 'quantity': e.value} :: Chỉ gửi ID/số lượng; không gửi giá tự khai để backend tin theo.
] :: Đóng mảng items.
}, :: Đóng JSON object checkout và named argument body.
); :: Đóng request; khi await thành công data là response đã JSON decode.
final o = orderFromJson( :: Chuyển dữ liệu đơn server về model ShopOrder.
data as Map<String, dynamic>, :: Xác nhận response tạo đơn là JSON object.
); :: Hoàn thành parse đơn, bao gồm snapshot/trạng thái/phí mà server trả.
app.cart.clear(); :: Chỉ xóa giỏ sau khi nhận và parse đơn thành công; không giữ lựa chọn để vô ý đặt lại cùng giỏ.
await app.reload(); :: Tải lại sản phẩm/đơn theo vai trò để UI theo trạng thái server mới nhất.
return o; :: Trả đơn vừa tạo cho màn hình tiếp theo như chi tiết/hóa đơn.
} :: Đóng checkout; Future có thể lỗi nếu bất kỳ bước await/parse ném exception.
""",
    ),
    Chapter(
        'Backend kiểm tra đăng nhập email', JAVA + 'controller/AuthController.java',
        r'^  public Session login\(',
        'Spring đọc JSON thành Login DTO và chạy validation. Method nhận đối tượng hợp lệ qua POST /api/auth/login.',
        'Không có user hoặc sai mật khẩu trả 401. Đúng mật khẩu chuyển sang AccountService.session để kiểm tra trạng thái và cấp JWT.',
        """
@PostMapping("/auth/login") :: Ghép với tiền tố /api của controller để nhận POST /api/auth/login.
@Transactional(readOnly = true) :: Đặt ranh giới transaction đọc cho luồng này; không đăng ký hay sửa mật khẩu trong method login.
public Session login(@Valid @RequestBody Login input) { :: Spring parse body JSON thành Login, kiểm tra constraint và gọi method; kết quả là DTO Session.
AppUser user = :: Khai báo biến entity tài khoản sẽ nhận kết quả truy vấn.
users :: Dùng repository Users được inject vào controller.
.findByEmailIgnoreCase(input.email().trim()) :: Tìm email không phân biệt hoa/thường sau khi bỏ khoảng trắng đầu/cuối.
.orElseThrow(() -> :: Nếu Optional không có tài khoản, tạo lỗi ở nhánh thiếu thay vì để user null chạy tiếp.
new ResponseStatusException( :: Tạo exception có mã HTTP và lý do để tầng xử lý lỗi chuyển thành response.
HttpStatus.UNAUTHORIZED, "Email hoặc mật khẩu không đúng")); :: Chọn 401 và thông báo chung, không tiết lộ riêng email nào tồn tại.
if (user.passwordHash == null :: Bắt đầu điều kiện từ chối khi tài khoản không có password hash.
|| user.passwordHash.startsWith("!") :: Từ chối dấu hiệu tài khoản chỉ đăng nhập social, không cố kiểm tra chuỗi đánh dấu bằng BCrypt.
|| !passwords.matches(input.password(), user.passwordHash)) { :: Dùng PasswordEncoder so mật khẩu nhập với hash lưu; không giải mã hash và không so trực tiếp hai chuỗi mật khẩu.
throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Email hoặc mật khẩu không đúng"); :: Bất kỳ điều kiện từ chối nào đúng thì kết thúc bằng 401, không phát token.
} :: Đóng nhánh mật khẩu không hợp lệ.
return accounts.session(user); :: Chuyển tài khoản đã xác minh sang service cấp phiên; service còn chặn blocked/deleted và kiểm tra chi nhánh.
} :: Đóng handler; DTO thành công sẽ được Spring/Jackson serialize thành JSON.
""",
    ),
    Chapter(
        'Backend kiểm tra trạng thái và tạo JWT', JAVA + 'service/AccountService.java',
        r'^  public Session session\(',
        'Đầu vào là AppUser đã tìm/xác minh theo luồng email hoặc social. Service không tin chỉ có đúng mật khẩu là mọi tài khoản đều được vào.',
        'Trả Session chứa JWT đã ký và DTO account an toàn. Không xuất passwordHash trong response account.',
        """
public Session session(AppUser user) { :: Method nghiệp vụ tạo phiên cho một entity tài khoản.
if (user.blocked || user.deleted) { :: Chặn tài khoản bị khóa hoặc đã xóa trước khi tạo JWT mới.
throw new ResponseStatusException( :: Tạo lỗi HTTP để caller ngừng quá trình đăng nhập.
HttpStatus.FORBIDDEN, "Tài khoản đã bị khóa hoặc xóa. Vui lòng liên hệ quản trị viên."); :: Chọn 403 kèm thông báo giới hạn tài khoản, khác với 401 sai mật khẩu.
} :: Đóng kiểm tra trạng thái tài khoản.
if ((user.role == Role.STORE || user.role == Role.MERCHANT) :: Áp dụng kiểm tra chi nhánh cho cả role cửa hàng hiện tại và role tương thích cũ.
&& user.assignedStore != null :: Chỉ truy cập chi nhánh được gán khi quan hệ này tồn tại.
&& !user.assignedStore.isActive()) { :: Nếu chi nhánh được gán đã ngừng hoạt động, không cho tạo phiên sử dụng cửa hàng đó.
throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chi nhánh đã ngừng hoạt động."); :: Dừng bằng 403 khi điều kiện chi nhánh thất bại.
} :: Đóng điều kiện cửa hàng bị ngừng hoạt động.
var now = Instant.now(); :: Chụp thời điểm hiện tại một lần để issuedAt và expiresAt dùng cùng mốc.
var claims = :: Chuẩn bị tập claim sẽ đặt trong JWT.
JwtClaimsSet.builder() :: Khởi tạo builder của Spring Security cho payload JWT.
.subject(user.email) :: Ghi email làm subject; decoder của dự án tra tài khoản theo subject này.
.issuedAt(now) :: Ghi thời điểm phát hành token.
.expiresAt(now.plusSeconds(28800)) :: Đặt hạn tám giờ sau mốc phát hành, không phải một phiên vô thời hạn.
.claim("role", user.role.name()) :: Ghi role từ entity DB, không lấy role tự khai của form login.
.claim("ver", user.version()) :: Ghi phiên bản để decoder đối chiếu và vô hiệu hóa JWT cũ khi version trong DB thay đổi.
.build(); :: Hoàn thành tập claim; bước này chưa ký và chưa tạo chuỗi JWT.
String token = :: Biến local nhận token đã được encoder ký.
jwt.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims)) :: Chọn header HS256 cùng claims rồi giao JwtEncoder đã cấu hình khóa ký thực hiện.
.getTokenValue(); :: Lấy chuỗi JWT từ kết quả encode, không in giá trị ra log.
return new Session(token, account(user)); :: Tạo DTO response có token và hồ sơ được chọn trường an toàn qua account(user).
} :: Đóng cấp phiên; kiểm tra quyền cho các request sau vẫn do filter/service thực hiện.
""",
    ),
    Chapter(
        'Backend tạo đơn và trừ tồn trong transaction', JAVA + 'controller/OrderController.java',
        r'^  public OrderView checkout\(',
        'Nhận Authentication do Security tạo và OrderInput đã validation. Phía app chỉ gửi ID/số lượng; backend tự đọc giá và tính phí.',
        'Thành công lưu đơn/snapshot/lịch sử và giảm tồn trong cùng giao dịch. Lỗi trạng thái, dữ liệu hoặc tranh tồn ném exception; không trả đơn thành công giả.',
        """
@PostMapping("/customer/orders") :: Ghép với /api để nhận POST tạo đơn của khách hàng.
@Transactional :: Cho các thay đổi DB trong checkout cùng ranh giới commit/rollback; phí đường bộ không phải phép tính của mobile.
public OrderView checkout(Authentication authentication, @Valid @RequestBody OrderInput input) { :: Nhận danh tính đã xác thực và JSON đã validation; kiểu trả về chỉ là DTO view của đơn.
var store = :: Biến sẽ nhận chi nhánh hợp lệ để toàn bộ đơn thuộc đúng một nơi bán.
stores :: Repository truy cập các chi nhánh.
.findById(input.storeId()) :: Tìm theo storeId khách gửi, không lấy một chi nhánh mặc định bất kỳ.
.filter(Store::isActive) :: Loại chi nhánh không hoạt động ngay cả khi ID vẫn còn trong database.
.orElseThrow(() -> bad("Cửa hàng đã ngừng hoạt động hoặc không tồn tại")); :: Không tìm được chi nhánh hợp lệ thì dừng bằng lỗi 400 của helper.
if (store.latitude == null || store.longitude == null) { :: Kiểm tra chi nhánh có điểm định vị trước khi tính tuyến giao.
throw bad("Chi nhánh chưa ghim vị trí"); :: Không có tọa độ hợp lệ để định tuyến thì không tạo đơn tiếp.
} :: Đóng kiểm tra vị trí chi nhánh.
var quote = delivery.quote(store, input.latitude(), input.longitude()); :: Gọi service báo phí/tuyến đường từ chi nhánh đến tọa độ khách; lỗi định tuyến sẽ dừng trước khi giảm tồn.
double km = quote.distanceKm(); :: Lấy khoảng cách đường bộ của báo giá để lưu cùng đơn.
var buyer = support.current(authentication); :: Xác định khách thực từ phiên đã xác thực, không từ customerId tự gửi trong JSON.
buyer.deliveryAddress = input.address().trim(); :: Ghi lại địa chỉ giao đã xác nhận vào hồ sơ vị trí của khách trong giao dịch.
buyer.deliveryLatitude = input.latitude(); :: Lưu vĩ độ điểm giao vào entity khách.
buyer.deliveryLongitude = input.longitude(); :: Lưu kinh độ cùng điểm giao đó.
var order = new CustomerOrder(buyer, store); :: Tạo entity đơn gắn với khách/chi nhánh đã xác định; chưa gọi repository.save tại đây.
order.recipient = input.recipient().trim(); :: Lưu tên người nhận và loại khoảng trắng thừa đầu/cuối.
order.phone = input.phone(); :: Lưu số liên hệ của đơn, để về sau thay hồ sơ không làm mất thông tin snapshot đơn.
order.address = input.address().trim(); :: Lưu địa chỉ trên chính đơn, tách với địa chỉ khách có thể sửa cho lần sau.
order.latitude = input.latitude(); :: Lưu vĩ độ điểm giao của đơn này.
order.longitude = input.longitude(); :: Lưu kinh độ điểm giao của đơn này.
order.distanceKm = km; :: Ghi khoảng cách quote vào đơn để response/thống kê dùng đúng dữ liệu đã chốt.
order.durationSeconds = quote.durationSeconds(); :: Lưu thời gian dự kiến do tuyến đường trả về.
order.distanceSource = "ROAD"; :: Đánh dấu đây là khoảng cách đường bộ, không gọi Haversine là phí định tuyến thật.
order.fee = quote.fee(); :: Ghi phí do backend tính; không tin một số fee tự khai từ app.
Set<Long> seen = new HashSet<>(); :: Tạo tập ID đã gặp để phát hiện một sản phẩm lặp lại trong payload checkout.
for (var item : :: Bắt đầu duyệt các dòng yêu cầu, mỗi lượt là một OrderItemInput.
input.items().stream().sorted(Comparator.comparing(OrderItemInput::productId)).toList()) { :: Sắp theo productId trước khi khóa, giúp các checkout lấy khóa cùng thứ tự và giảm nguy cơ chờ chéo.
if (!seen.add(item.productId())) { :: add trả false khi ID đã có; phủ định cho biết payload chứa sản phẩm trùng.
throw bad("Sản phẩm bị trùng"); :: Dừng cả đơn thay vì cộng/trừ tồn mơ hồ hai lần cùng một ID.
} :: Đóng kiểm tra dòng trùng.
var product = :: Biến giữ entity sản phẩm sau khi repository lấy khóa.
products.locked(item.productId()).orElseThrow(() -> bad("Sản phẩm không tồn tại")); :: Lấy bản ghi với khóa ghi để các giao dịch tranh tồn phải phối hợp; không có ID thì dừng.
if (!product.store.id.equals(store.id) || !product.active) { :: Bảo đảm sản phẩm thuộc đúng chi nhánh của giỏ và vẫn được bán.
throw bad("Sản phẩm không thuộc chi nhánh hoặc ngừng bán"); :: Chặn payload ghép sản phẩm chi nhánh khác hoặc mặt hàng ngừng bán.
} :: Đóng kiểm tra phạm vi sản phẩm.
if (product.stock < item.quantity()) { :: Kiểm tra tồn thật sau khi lấy khóa, không dựa vào tồn app đã tải trước đó.
throw new ResponseStatusException(HttpStatus.CONFLICT, "Không đủ tồn kho: " + product.name); :: Trả 409 khi đơn này không còn đủ hàng; transaction không được commit như một checkout thành công.
} :: Đóng kiểm tra đủ tồn.
product.stock -= item.quantity(); :: Giảm tồn trên entity đang được transaction/JPA quản lý.
order.lines.add(new OrderLine(order, product, item.quantity(), product.price)); :: Thêm dòng snapshot gắn với đơn, dùng số lượng yêu cầu và giá hiện tại đọc từ database.
order.total = order.total.add(product.price.multiply(BigDecimal.valueOf(item.quantity()))); :: Cộng tiền hàng bằng BigDecimal theo giá DB nhân số lượng; tổng này được lưu tách với trường fee.
} :: Kết thúc xử lý toàn bộ dòng hàng sau kiểm tra/giảm tồn/snapshot.
order.history.add(new StatusEvent("PENDING")); :: Ghi lịch sử ban đầu để việc tạo đơn có dấu mốc trạng thái rõ ràng.
return view(orders.save(order)); :: Lưu entity rồi chuyển thành DTO response; việc commit còn do cơ chế transaction quanh method hoàn tất.
} :: Đóng checkout; các HTTP/API ngoài và file không tự có rollback giống dữ liệu MySQL chỉ vì nằm trong giao dịch.
""",
    ),
    Chapter(
        'Repository khóa bản ghi sản phẩm', JAVA + 'repository/Products.java',
        r'^  public Optional<Product> locked\(',
        'Checkout gọi products.locked(id) bên trong transaction. Đây là khai báo repository, Spring Data tạo phần thực thi.',
        'Trả Optional<Product> với cơ chế pessimistic write lock khi có bản ghi; caller xử lý trường hợp không tồn tại.',
        """
@Lock(LockModeType.PESSIMISTIC_WRITE) :: Yêu cầu khóa ghi theo khả năng DB/JPA cho truy vấn này; các transaction tranh cùng bản ghi phải chờ/phối hợp.
@Query("select p from Product p where p.id = :id") :: JPQL truy vấn entity Product, đặt alias p và bind tham số id; đây không phải tên bảng SQL được ghép chuỗi từ input.
public Optional<Product> locked(Long id); :: Interface không viết thân hàm; Spring Data hiện thực. Optional buộc caller nghĩ tới trường hợp không có sản phẩm.
""",
        declaration=True,
    ),
    Chapter(
        'Java khởi động toàn bộ Spring Boot', JAVA + 'CStoreApplication.java', None,
        'JVM chạy main của JAR. Package ứng dụng là gốc để Spring tìm các class đã chia theo controller/service/repository/entity/dto/config/security.',
        'Application context được tạo, cấu hình và bean được nạp, web server bắt đầu lắng nghe; lỗi cấu hình/kết nối có thể khiến khởi động dừng.',
        """
package com.cstore.app; :: Đặt namespace gốc của backend; các package con nằm dưới vùng tìm kiếm ứng dụng.
import org.springframework.boot.SpringApplication; :: Nạp class có hàm run dùng để khởi tạo Spring Boot.
import org.springframework.boot.autoconfigure.SpringBootApplication; :: Nạp annotation cấu hình điểm bắt đầu ứng dụng.
@SpringBootApplication :: Bật nhóm cơ chế cấu hình/tìm component của Spring Boot từ package ứng dụng; không phải một phép gọi tuần tự trong main.
public class CStoreApplication { :: Định nghĩa class công khai chứa entry point Java của backend.
public static void main(String[] args) { :: JVM gọi main mà không cần tạo instance; args là tham số dòng lệnh truyền cho JAR.
SpringApplication.run(CStoreApplication.class, args); :: Tạo application context theo class gốc và args; Spring nối dependency, cấu hình persistence/security/web theo source.
} :: Đóng main; server tiếp tục hoạt động trên các thành phần và thread đã được Spring khởi động.
} :: Đóng class entry point; nghiệp vụ không được gom vào file khởi động này.
""",
    ),
]


def render():
    parts = [
        '# Đọc từng dòng source trong các luồng cốt lõi',
        '',
        'Chương này trích **nguyên source đang có** và đánh số theo dòng thật trong file, không phải số dòng tự đặt trong ví dụ. Mỗi câu lệnh, phần xuống dòng của lời gọi và dấu đóng khối đều có chú giải riêng. Dòng trống chỉ phân tách nhóm; comment giúp đọc và không được thực thi.',
        '',
        'Đây là phần hướng dẫn chi tiết cho các đường chạy trung tâm, không tuyên bố đã chú giải từng dòng của toàn bộ UI/native/test. Đọc cùng [bản đồ source](ban-do-source.md), [công nghệ](cong-nghe.md), [backend](backend.md), [giao diện](mobile-giao-dien.md), [lệnh chạy](lenh-va-cau-hinh.md) và [thuật ngữ](thuat-ngu.md).',
        '',
        'Luồng đăng nhập: **main → CStoreApp/RoleHome → form → AppState.login → _SessionActions.login → AccountApi.login → ApiClient.request/_send → AuthController.login → AccountService.session → AccountApi._session → nạp phiên → RoleHome dựng lại**. Các wrapper AppState chỉ chuyển việc sang action tương ứng; không tạo một state thứ hai.',
        '',
        'Luồng đặt hàng: **catalog → Map giỏ → _CartOrderActions.checkout → HTTP POST → OrderController.checkout → Products.locked → lưu snapshot/giảm tồn → JSON → ShopOrder → tải lại UI**. Validation/filter/mapping còn có chi tiết ở các chương chuyên đề.',
        '',
        'Tài liệu được tạo bằng `scripts/generate-reading-guide.py`. Script chỉ đọc các file Java/Dart được liệt kê tường minh; không đọc `.env`, file cấu hình social local, token mặc định, cache hay artifact. Chú giải được biên soạn theo từng câu lệnh; nếu source khác, script dừng để cập nhật chú giải thay vì gắn giải thích cũ vào code mới.',
        '',
        'Tạo lại từ gốc dự án, có log Kitty:',
        '',
        '```bash',
        'python3 scripts/run-visible.py --name "Tạo hướng dẫn từng dòng" -- python3 scripts/generate-reading-guide.py',
        '```',
        '',
    ]
    total_source = 0
    total_code = 0
    for number, chapter in enumerate(CHAPTERS, start=1):
        lines, first_line = select_source(chapter)
        notes = parse_notes(chapter.notes)
        note_index = 0
        rows = []
        for offset, line in enumerate(lines):
            source_number = first_line + offset
            stripped = line.strip()
            if not stripped:
                explanation = 'Dòng trống phân tách các nhóm câu lệnh; không tạo hành động khi chạy.'
            elif stripped.startswith('//'):
                explanation = 'Chú thích của source: ' + stripped.lstrip('/').strip() + ' Không phải câu lệnh thực thi.'
            else:
                if note_index >= len(notes) or notes[note_index][0] != stripped:
                    raise ValueError(
                        f'Chú giải cần cập nhật: {chapter.path}:{source_number}; '
                        f'mục {chapter.title}, vị trí ghi chú {note_index + 1}'
                    )
                explanation = notes[note_index][1]
                note_index += 1
                total_code += 1
            rows.append((source_number, explanation))
        if note_index != len(notes):
            raise ValueError(f'Còn chú giải không khớp source: {chapter.title}')
        total_source += len(lines)
        parts.extend([
            f'## {number}. {chapter.title}', '',
            f'File: [`{chapter.path}`](../../{chapter.path}). Dòng {first_line}–{first_line + len(lines) - 1}.', '',
            f'**Đầu vào và trách nhiệm:** {chapter.purpose}', '',
            f'**Kết quả và nhánh lỗi:** {chapter.outcome}', '',
            'Các số đầu dòng dưới đây là số dòng file, không phải một phần cú pháp cần chép vào IDE.', '',
            '```text',
        ])
        parts.extend(f'{first_line + offset:4} | {line}' for offset, line in enumerate(lines))
        parts.extend(['```', '', '| Dòng source | Giải thích chi tiết |', '| --- | --- |'])
        for line_number, explanation in rows:
            parts.append(f'| {line_number} | {explanation.replace("|", "&#124;")} |')
        parts.append('')
    parts.extend([
        '## Phạm vi đã chú giải', '',
        f'- {len(CHAPTERS)} đoạn source thuộc các luồng khởi động, phân vai, đăng nhập, giao tiếp HTTP, tải catalog, đặt đơn và khóa tồn kho.',
        f'- {total_source} dòng source được trích, gồm {total_code} dòng code/annotation/cú pháp có ghi chú riêng; comment và dòng trống cũng được đối chiếu trong bảng.',
        '- Số dòng được tính lại từ source mỗi lần chạy generator. Các file ngoài danh sách cần đọc theo bản đồ source và chương chuyên đề; không coi một giải thích ở đây là thay thế cho kiểm thử.',
        '',
    ])
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text('\n'.join(parts))
    return total_source, total_code


if __name__ == '__main__':
    source_lines, code_lines = render()
    print(f'Đã tạo: {OUTPUT.relative_to(ROOT)}')
    print(f'{len(CHAPTERS)} luồng/đoạn; {source_lines} dòng source; {code_lines} chú giải code riêng.')
