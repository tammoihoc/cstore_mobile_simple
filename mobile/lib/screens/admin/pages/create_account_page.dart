// Tạo tài khoản theo vai trò và tải ảnh nhận diện nếu cần.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/widgets/common.dart';
import 'package:cstore_mobile/widgets/account_avatar.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_colors.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_ui.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key, required this.state});
  final AppState state;
  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  Role role = Role.customer;
  int? storeId, createdId;
  Uint8List? photo;
  String? photoName, error;
  bool busy = false;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 88);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw StateError('Ảnh phải nhỏ hơn 5 MB.');
      }
      if (mounted) {
        setState(() {
          photo = bytes;
          photoName = picked.name;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => error = e is StateError ? e.message : 'Chưa chọn được ảnh.');
      }
    }
  }

  // Chỉ tạo tài khoản khi chưa có createdId; lần thử lại không tạo bản ghi trùng.
  Future<void> save() async {
    if (busy) return;
    if (createdId == null) {
      if (!form.currentState!.validate()) return;
      if (role == Role.shipper && photo == null) {
        setState(() => error =
            'Ảnh đại diện shipper bắt buộc. Vui lòng chọn ảnh nhận diện.');
        return;
      }
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (createdId == null) {
        final data = await widget.state.api.request('/admin/accounts', body: {
          'fullName': name.text.trim(),
          'email': email.text.trim(),
          'password': password.text,
          'role': role.name.toUpperCase(),
          'storeId': role == Role.store ? storeId : null
        }) as Map<String, dynamic>;
        createdId = data['id'] as int;
      }
      if (photo != null && role != Role.store) {
        await widget.state.api
            .uploadAccountAvatar(createdId!, photo!, photoName ?? 'avatar.jpg');
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => error = createdId == null
            ? e is StateError
                ? e.message
                : 'Chưa tạo được tài khoản.'
            : 'Tài khoản đã tạo. Bấm thử tải ảnh lại để hoàn tất.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = busy || createdId != null;
    final store =
        widget.state.branchList.where((b) => b.id == storeId).firstOrNull;
    return Scaffold(
      backgroundColor: adminPaper,
      appBar: AppBar(title: const Text('Thêm tài khoản')),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton(
            onPressed: busy ? null : save,
            child: Text(
              busy
                  ? 'Đang tạo…'
                  : createdId == null
                      ? 'Tạo tài khoản'
                      : 'Thử tải ảnh lại',
            ),
          ),
        ),
      ),
      body: Form(
        key: form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading('Một thành viên mới', 'Đúng vai trò, đúng ảnh nhận diện'),
              DropdownButtonFormField<Role>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Vai trò'),
                  items: [
                    for (final r in Role.values)
                      DropdownMenuItem(
                        value: r,
                        child: Row(
                          children: [
                            Icon(
                              accountRoleIcon(r),
                              color: adminForest,
                              size: 21,
                            ),
                            const SizedBox(width: 12),
                            Text(accountRoleName(r))
                          ],
                        ),
                      )
                  ],
                  onChanged: locked
                      ? null
                      : (r) => setState(() {
                            role = r!;
                            photo = null;
                            photoName = null;
                          })),
              const SizedBox(height: 18),
              if (role == Role.store) ...[
                DropdownButtonFormField<int>(
                    initialValue: storeId,
                    isExpanded: true,
                    itemHeight: 64,
                    decoration: const InputDecoration(
                      labelText: 'Chi nhánh quản lý',
                    ),
                    items: [
                      for (final b in widget.state.branchList)
                        DropdownMenuItem(
                          value: b.id,
                          child: Row(
                            children: [
                              AccountAvatar(
                                path: b.image,
                                role: Role.store,
                                size: 34,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  b.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            ],
                          ),
                        )
                    ],
                    onChanged:
                        locked ? null : (id) => setState(() => storeId = id),
                    validator: (id) =>
                        id == null ? 'Chọn chi nhánh quản lý' : null),
                const SizedBox(height: 16),
                Center(
                  child: AccountAvatar(
                    path: store?.image ?? '',
                    role: Role.store,
                    size: 90,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Tài khoản cửa hàng dùng logo của thương hiệu được gán.',
                    style: TextStyle(
                      color: adminMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      photo == null
                          ? AccountAvatar(role: role, size: 88)
                          : ClipOval(
                              child: Image.memory(
                                photo!,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                              ),
                            ),
                      const SizedBox(height: 12),
                      Text(
                        role == Role.shipper
                            ? 'Ảnh đại diện bắt buộc'
                            : 'Ảnh đại diện tùy chọn',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: adminForest,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (role == Role.shipper)
                        const Text(
                          'Dùng ảnh rõ khuôn mặt của người giao hàng.',
                          style: TextStyle(
                            color: adminMuted,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      TextButton.icon(
                        onPressed: busy ? null : pickPhoto,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(
                          photo == null ? 'Chọn ảnh đại diện' : 'Đổi ảnh',
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              adminFormField(name, 'Họ và tên', enabled: !locked),
              adminFormField(email, 'Email đăng nhập',
                  enabled: !locked, email: true),
              adminFormField(password, 'Mật khẩu ban đầu',
                  enabled: !locked, secret: true),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20)
            ],
          ),
        ),
      ),
    );
  }
}
