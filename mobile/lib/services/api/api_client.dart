import 'dart:convert';

import 'package:http/http.dart' as http;

/// Chỉ phụ trách giao tiếp HTTP: URL, JSON, mã lỗi và tải ảnh.
/// Các endpoint nghiệp vụ được đặt ở AccountApi để dễ tìm hơn.
class ApiClient {
  ApiClient({http.Client? client}) : client = client ?? http.Client();

  final http.Client client;

  // 10.0.2.2 là địa chỉ máy chủ Linux nhìn từ Android Emulator.
  static const base = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  // Phiên chỉ giữ trong RAM. Không in giá trị này ra log.
  String? token;

  Future<dynamic> request(
    String path, {
    Map<String, dynamic>? body,
    String? method,
  }) async {
    final uri = Uri.parse('$base/api$path');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    // Không có body thì mặc định đọc GET; có body thì mặc định gửi POST.
    final requestMethod = method ?? (body == null ? 'GET' : 'POST');
    final timeoutSeconds = path.startsWith('/customer/nearby') ? 60 : 20;
    final response = await _send(
      requestMethod,
      uri,
      headers,
      body,
    ).timeout(Duration(seconds: timeoutSeconds));

    if (response.statusCode >= 400) {
      final serverMessage = _readErrorMessage(response);
      throw StateError(_errorMessage(
        response.statusCode,
        path,
        serverMessage,
      ));
    }

    if (response.body.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) {
    String? encodedBody() => body == null ? null : jsonEncode(body);

    switch (method) {
      case 'PUT':
        return client.put(
          uri,
          headers: headers,
          body: encodedBody(),
        );
      case 'DELETE':
        return client.delete(
          uri,
          headers: headers,
        );
      case 'POST':
        return client.post(
          uri,
          headers: headers,
          body: encodedBody(),
        );
      default:
        return client.get(
          uri,
          headers: headers,
        );
    }
  }

  String? _readErrorMessage(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return (data as Map<String, dynamic>)['message'] as String?;
    } catch (_) {
      // Server có thể trả HTML/rỗng khi lỗi mạng; vẫn cần thông báo dễ hiểu.
      return null;
    }
  }

  String _errorMessage(
    int statusCode,
    String path,
    String? serverMessage,
  ) {
    if (statusCode == 401) {
      if (path == '/auth/login') return 'Email hoặc mật khẩu không đúng.';
      if (path == '/auth/social') {
        return 'Không xác minh được đăng nhập. Vui lòng thử lại.';
      }
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }

    if (statusCode == 403) {
      return serverMessage ?? 'Tài khoản không có quyền thực hiện.';
    }

    if (statusCode == 409) {
      return serverMessage ?? 'Dữ liệu đã thay đổi hoặc email đã được sử dụng.';
    }

    return serverMessage ??
        'Không thể xử lý yêu cầu ($statusCode). Kiểm tra thông tin và thử lại.';
  }

  /// Multipart gửi dữ liệu nhị phân của ảnh, không chuyển ảnh thành chuỗi JSON.
  Future<void> uploadFile(
    String path,
    List<int> bytes,
    String name,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$base/api$path'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: name,
      ));

    final response = await client.send(request).timeout(
          const Duration(seconds: 30),
        );

    if (response.statusCode >= 400) {
      await response.stream.drain<void>();
      throw StateError(
        'Không tải được ảnh (${response.statusCode}). Chọn ảnh JPEG/PNG dưới 5 MB.',
      );
    }

    await response.stream.drain<void>();
  }

  String imageUrl(String path) => Uri.parse(base).resolve(path).toString();

  void close() => client.close();
}
