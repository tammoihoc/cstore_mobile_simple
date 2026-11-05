import 'role.dart';

/// Thông tin tài khoản dùng trong app; không chứa mật khẩu người dùng.
class Account {
  const Account(
    this.id,
    this.email,
    this.name,
    this.role,
    this.storeId, {
    this.blocked = false,
    this.deleted = false,
    this.storeOwner = false,
    this.avatar = '',
    this.gender = 'UNSPECIFIED',
    this.phone = '',
    this.passwordEnabled = true,
    this.createdAt,
  });
  final int id;
  final String email;
  final String name;
  final Role role;
  final int? storeId;
  final bool blocked;
  final bool deleted;
  final bool storeOwner;
  final bool passwordEnabled;
  final String avatar;
  final String gender;
  final String phone;
  final DateTime? createdAt;
  bool get photoRequired => role == Role.shipper && avatar.trim().isEmpty;
  factory Account.fromJson(
    Map<String, dynamic> json,
  ) =>
      Account(
        json['id'] as int,
        json['email'] as String,
        json['name'] as String,
        Role.values.byName((json['role'] as String).toLowerCase()),
        json['storeId'] as int?,
        blocked: json['blocked'] == true,
        deleted: json['deleted'] == true,
        storeOwner: json['storeOwner'] == true,
        avatar: json['avatar'] as String? ?? '',
        gender: json['gender'] as String? ?? 'UNSPECIFIED',
        phone: json['phone'] as String? ?? '',
        passwordEnabled: json['passwordEnabled'] as bool? ?? true,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}
