// Đổi mật khẩu: kiểm tra ba ô nhập và chờ máy chủ xác nhận.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/widgets/common.dart';
import 'package:cstore_mobile/screens/profile/widgets/profile_colors.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, required this.state});
  final AppState state;
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final form = GlobalKey<FormState>();
  final inputs = List.generate(3, (_) => TextEditingController());
  final obscure = [true, true, true];
  bool busy = false;
  String? error;
  @override
  void dispose() {
    for (final c in inputs) {
      c.dispose();
    }
    super.dispose();
  }

  // Chờ đổi mật khẩu xong mới thông báo; token phiên mới được AccountApi xử lý.
  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.state.changePassword(inputs[0].text, inputs[1].text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Đã đổi mật khẩu. Các phiên đăng nhập cũ đã được đăng xuất.',
        ),
      ));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() =>
            error = e is StateError ? e.message : 'Chưa đổi được mật khẩu.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Đổi mật khẩu')),
        body: widget.state.account?.passwordEnabled == false
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.login_rounded,
                        size: 48, color: profileForest),
                    heading('Đăng nhập qua mạng xã hội',
                        'Mật khẩu được quản lý tại Google/Facebook mà bạn đang dùng.')
                  ],
                ),
              )
            : Form(
                key: form,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: profileSage,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              color: profileForest,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Mật khẩu mới từ 8–72 ký tự. Các thiết bị khác sẽ cần đăng nhập lại.',
                                style: TextStyle(
                                  color: profileForest,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      for (var i = 0; i < 3; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: TextFormField(
                            key: ValueKey('password-$i'),
                            controller: inputs[i],
                            enabled: !busy,
                            obscureText: obscure[i],
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: [
                                'Mật khẩu hiện tại',
                                'Mật khẩu mới',
                                'Nhập lại mật khẩu mới'
                              ][i],
                              suffixIcon: IconButton(
                                tooltip: obscure[i]
                                    ? 'Hiện mật khẩu'
                                    : 'Ẩn mật khẩu',
                                onPressed: () =>
                                    setState(() => obscure[i] = !obscure[i]),
                                icon: Icon(
                                  obscure[i]
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final v = value ?? '';
                              if (v.isEmpty) return 'Không được bỏ trống';
                              if (i == 1 &&
                                  (v.length < 8 ||
                                      v.length > 72 ||
                                      utf8.encode(v).length > 72)) {
                                return 'Mật khẩu từ 8 ký tự, vui lòng rút ngắn nếu quá dài.';
                              }
                              if (i == 2 && v != inputs[1].text) {
                                return 'Mật khẩu nhập lại chưa khớp';
                              }
                              return null;
                            },
                          ),
                        ),
                      if (error != null)
                        Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: busy ? null : save,
                        child: Text(busy ? 'Đang cập nhật…' : 'Lưu mật khẩu'),
                      )
                    ],
                  ),
                ),
              ),
      );
}
