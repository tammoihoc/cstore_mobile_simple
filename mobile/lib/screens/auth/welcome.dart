import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../services/social_sign_in.dart';
import '../../models/models.dart';
import '../../widgets/cstore_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.state});
  final AppState state;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController();
  bool busy = false, hidden = true, registering = false;
  Role role = Role.customer;
  String? error;
  String? notice;
  SocialProvider? activeProvider;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  // Bước 1: kiểm tra form. Bước 2: gọi AppState. Bước 3: hiển thị lỗi/kết thúc chờ.
  Future<void> submit() async {
    if (busy) return;
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
      notice = null;
    });
    try {
      if (registering) {
        await widget.state.register(name.text, email.text, password.text, role);
      } else {
        await widget.state.login(email.text, password.text);
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e is StateError
            ? e.message
            : 'Không kết nối được máy chủ. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> socialLogin(SocialProvider provider) async {
    if (busy) return;
    setState(() {
      busy = true;
      activeProvider = provider;
      error = null;
      notice = null;
    });
    try {
      final signedIn = await widget.state.loginSocial(provider);
      if (!signedIn && mounted) {
        setState(() => notice = 'Đã hủy đăng nhập ${provider.label}.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e is StateError
            ? e.message
            : 'Không kết nối được máy chủ. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          activeProvider = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: ListView(
            key: const ValueKey('login-scroll'),
            children: [
              hero(),
              Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        registering ? 'Tạo tài khoản' : 'Mừng bạn trở lại',
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Mua sắm tiện lợi. Kết nối cửa hàng gần bạn.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 24),
                      if (registering) ...[
                        TextFormField(
                          controller: name,
                          decoration:
                              const InputDecoration(labelText: 'Họ và tên'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nhập họ tên'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Role>(
                            initialValue: role,
                            decoration: const InputDecoration(
                              labelText: 'Loại tài khoản',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: Role.customer,
                                child: Text('Khách hàng'),
                              ),
                              DropdownMenuItem(
                                value: Role.shipper,
                                child: Text('Shipper'),
                              )
                            ],
                            onChanged:
                                busy ? null : (v) => setState(() => role = v!)),
                        const SizedBox(height: 16)
                      ],
                      TextFormField(
                        controller: email,
                        enabled: !busy,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (v) => v == null ||
                                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(v)
                            ? 'Nhập email hợp lệ'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: password,
                        enabled: !busy,
                        obscureText: hidden,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => hidden = !hidden),
                            icon: Icon(
                              hidden
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Nhập mật khẩu'
                            : registering && (v.length < 8 || v.length > 72)
                                ? 'Mật khẩu 8–72 ký tự'
                                : null,
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      if (notice != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            notice!,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: busy ? null : submit,
                        child: busy && activeProvider == null
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                registering ? 'Tạo tài khoản' : 'Đăng nhập',
                              ),
                      ),
                      if (!registering) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'hoặc tiếp tục với',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                              Expanded(child: Divider())
                            ],
                          ),
                        ),
                        socialButton(SocialProvider.google),
                        const SizedBox(height: 12),
                        socialButton(SocialProvider.facebook),
                        const SizedBox(height: 10),
                        const Text(
                          'Lần đầu đăng nhập sẽ tạo tài khoản khách hàng.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                      const SizedBox(height: 6),
                      TextButton(
                        key: const ValueKey('login-register-toggle'),
                        onPressed: busy
                            ? null
                            : () => setState(() {
                                  registering = !registering;
                                  error = null;
                                  notice = null;
                                }),
                        child: Text(
                          registering
                              ? 'Đã có tài khoản? Đăng nhập'
                              : 'Chưa có tài khoản? Đăng ký',
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      );

  Widget socialButton(SocialProvider provider) => OutlinedButton.icon(
        key: ValueKey('login-${provider.name}'),
        onPressed: busy ? null : () => socialLogin(provider),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          foregroundColor: const Color(0xFF172B25),
          side: const BorderSide(color: Color(0xFFDCE2DF)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: activeProvider == provider
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : provider == SocialProvider.facebook
                ? const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 24)
                : Image.asset(
                    'assets/images/google.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(width: 24, height: 24),
                  ),
        label: Text('Tiếp tục với ${provider.label}'),
      );
  Widget hero() => Container(
        height: 190,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Color(0xFFEAF1E9),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -40,
              child: Image.asset(
                'assets/images/orange.webp',
                height: 190,
                width: 190,
                fit: BoxFit.cover,
              ),
            ),
            const Positioned(
              left: 28,
              top: 18,
              child: CStoreLogo(width: 172, height: 64),
            ),
            const Positioned(
              left: 28,
              top: 100,
              child: Text(
                'Tươi ngon.\nNgay gần bạn.',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF214E3E),
                ),
              ),
            )
          ],
        ),
      );
}
