import '../../models/models.dart';
import 'api_client.dart';

/// Các lời gọi API liên quan tài khoản, chi nhánh và tệp ảnh.
/// ApiClient xử lý HTTP chung; lớp này biết endpoint nào trả model nào.
class AccountApi extends ApiClient {
  AccountApi({super.client});

  // Giữ tên cấu hình cũ để các widget đọc URL ảnh không phải đổi cách gọi.
  static const base = ApiClient.base;

  Future<Account> login(
    String email,
    String password,
  ) async {
    final data = await request(
      '/auth/login',
      body: {'email': email, 'password': password},
    ) as Map<String, dynamic>;
    return _session(data);
  }

  Future<Map<String, bool>> socialProviders() async {
    final data = await request('/auth/providers') as Map<String, dynamic>;
    return {
      'google': data['google'] == true,
      'facebook': data['facebook'] == true
    };
  }

  Future<Account> socialLogin(
    String provider,
    String providerToken,
  ) async {
    final data = await request(
      '/auth/social',
      body: {
        'provider': provider,
        'token': providerToken,
      },
    ) as Map<String, dynamic>;
    return _session(data);
  }

  Account _session(
    Map<String, dynamic> data,
  ) {
    final account = Account.fromJson(
      data['user'] as Map<String, dynamic>,
    );
    token = data['token'] as String;
    return account;
  }

  Future<Account> profile() async => Account.fromJson(
        await request('/account/profile') as Map<String, dynamic>,
      );
  Future<Account> updateProfile(
    String name,
    String phone,
    String gender,
  ) async =>
      Account.fromJson(
        await request(
          '/account/profile',
          method: 'PUT',
          body: {'name': name, 'phone': phone, 'gender': gender},
        ) as Map<String, dynamic>,
      );
  Future<Account> uploadAvatar(
    List<int> bytes,
    String name,
  ) async {
    final session = token;
    await uploadFile(
      '/account/avatar',
      bytes,
      name,
    );
    if (token != session) {
      throw StateError('Phiên đăng nhập đã thay đổi. Vui lòng đăng nhập lại.');
    }
    return profile();
  }

  Future<void> uploadAccountAvatar(
    int accountId,
    List<int> bytes,
    String name,
  ) =>
      uploadFile(
        '/admin/accounts/$accountId/avatar',
        bytes,
        name,
      );
  Future<Account> removeAvatar() async => Account.fromJson(
        await request(
          '/account/avatar',
          method: 'DELETE',
        ) as Map<String, dynamic>,
      );
  Future<Account> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final session = token;
    final data = await request(
      '/account/password',
      method: 'PUT',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    ) as Map<String, dynamic>;
    final account = Account.fromJson(
      data['user'] as Map<String, dynamic>,
    );
    if (token == session) token = data['token'] as String;
    return account;
  }

  Future<List<Branch>> branches() async => [
        for (final j in await request('/branches') as List)
          Branch(
            j['id'] as int,
            j['name'] as String,
            j['address'] as String,
            (j['latitude'] as num).toDouble(),
            (j['longitude'] as num).toDouble(),
            brand: j['brand'] as String?,
            image: j['image'] as String? ?? '',
            open: j['open'] as bool? ?? true,
          )
      ];
  Future<List<Account>> accounts() async => [
        for (final j in await request('/admin/accounts') as List)
          Account.fromJson(
            j as Map<String, dynamic>,
          )
      ];
  Future<Map<String, dynamic>> createStore(
    Map<String, dynamic> body,
  ) async =>
      await request(
        '/admin/stores',
        body: body,
      ) as Map<String, dynamic>;

  Future<void> uploadStoreImage(
    int storeId,
    List<int> bytes,
    String name,
  ) =>
      uploadFile(
        '/admin/stores/$storeId/image',
        bytes,
        name,
      );

  Future<void> uploadImage(
    int productId,
    List<int> bytes,
    String name,
  ) async {
    await uploadFile(
      '/merchant/products/$productId/image',
      bytes,
      name,
    );
  }
}
