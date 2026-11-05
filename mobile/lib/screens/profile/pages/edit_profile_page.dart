// Chỉnh hồ sơ: quản lý controller, chọn ảnh và gửi dữ liệu đến AppState.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/widgets/common.dart';
import 'package:cstore_mobile/widgets/account_avatar.dart';
import 'package:cstore_mobile/screens/profile/widgets/profile_colors.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.state});
  final AppState state;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final form = GlobalKey<FormState>();
  late final name =
      TextEditingController(text: widget.state.account?.name ?? '');
  late final phone =
      TextEditingController(text: widget.state.account?.phone ?? '');
  late String gender = widget.state.account?.gender ?? 'UNSPECIFIED';
  bool busy = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  // Bộ chọn ảnh trả Future; kiểm tra mounted trước khi cập nhật màn hình.
  Future<void> photo() async {
    if (busy) return;
    try {
      final image = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 88);
      if (image == null || !mounted) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw StateError('Ảnh phải nhỏ hơn 5 MB.');
      }
      setState(() {
        busy = true;
        error = null;
      });
      await widget.state.uploadAvatar(bytes, image.name);
    } catch (e) {
      if (mounted) {
        setState(() => error =
            e is StateError ? e.message : 'Chưa tải được ảnh đại diện.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  // validate kiểm tra form tại máy; AppState gửi và đồng bộ hồ sơ từ máy chủ.
  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    if (widget.state.account?.photoRequired == true) {
      setState(() =>
          error = 'Thêm ảnh rõ khuôn mặt của bạn trước khi lưu hồ sơ shipper.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.state
          .updateProfile(name.text.trim(), phone.text.trim(), gender);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(
            () => error = e is StateError ? e.message : 'Chưa lưu được hồ sơ.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) {
          final account = widget.state.account;
          final shipper = account?.role == Role.shipper;
          return Scaffold(
            appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
                child: FilledButton(
                  onPressed: busy ? null : save,
                  child: Text(busy ? 'Đang lưu…' : 'Lưu hồ sơ'),
                ),
              ),
            ),
            body: Form(
              key: form,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: AccountAvatar(
                        account: account,
                        gender: gender,
                        size: 114,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: busy ? null : photo,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Chọn ảnh đại diện'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        shipper
                            ? 'Bắt buộc dùng ảnh thật, rõ khuôn mặt của bạn. Ảnh sẽ được hiển thị cho khách trong đơn giao.'
                            : 'Ảnh cá nhân là tùy chọn. Khi chưa có ảnh riêng, avatar tự đổi theo giới tính. Ảnh riêng được giữ khi bạn đổi giới tính.',
                        style: const TextStyle(
                          color: profileMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextFormField(
                      key: const ValueKey('profile-name'),
                      controller: name,
                      enabled: !busy,
                      decoration: const InputDecoration(labelText: 'Họ và tên'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Nhập họ và tên'
                          : v.trim().length > 100
                              ? 'Tên tối đa 100 ký tự'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('profile-phone'),
                      controller: phone,
                      enabled: !busy,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                      ),
                      validator: (v) => v == null ||
                              v.isEmpty ||
                              RegExp(r'^0[0-9]{9}$').hasMatch(v.trim())
                          ? null
                          : 'Nhập 10 chữ số, bắt đầu bằng 0',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: account?.email,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email đăng nhập',
                        suffixIcon: Icon(Icons.lock_outline, size: 18),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                        key: ValueKey(gender),
                        initialValue: gender,
                        decoration: const InputDecoration(
                          labelText: 'Giới tính (tùy chọn)',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'UNSPECIFIED',
                            child: Text('Không cung cấp'),
                          ),
                          DropdownMenuItem(
                            value: 'MALE',
                            child: Text('Nam'),
                          ),
                          DropdownMenuItem(
                            value: 'FEMALE',
                            child: Text('Nữ'),
                          )
                        ],
                        onChanged: busy
                            ? null
                            : (value) => setState(() => gender = value!)),
                    if (!shipper && account?.avatar.isNotEmpty == true)
                      TextButton.icon(
                        onPressed: busy
                            ? null
                            : () async {
                                setState(() => busy = true);
                                await attempt(
                                    context, widget.state.removeAvatar);
                                if (mounted) {
                                  setState(() => busy = false);
                                }
                              },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Xóa ảnh đại diện'),
                      ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 20)
                  ],
                ),
              ),
            ),
          );
        },
      );
}
