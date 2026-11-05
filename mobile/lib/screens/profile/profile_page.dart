// Trang xem hồ sơ; trang sửa hồ sơ và đổi mật khẩu nằm trong pages/.

import 'package:flutter/material.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/widgets/account_avatar.dart';
import 'package:cstore_mobile/screens/profile/widgets/profile_colors.dart';
import 'package:cstore_mobile/screens/profile/widgets/profile_menu_tile.dart';
import 'package:cstore_mobile/screens/profile/pages/edit_profile_page.dart';
import 'package:cstore_mobile/screens/profile/pages/change_password_page.dart';

export 'pages/edit_profile_page.dart';
export 'pages/change_password_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage(
      {super.key, required this.state, this.embedded = false, this.onLocation});
  final AppState state;
  final bool embedded;
  final VoidCallback? onLocation;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool refreshing = false;
  String? error;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    if (refreshing) return;
    setState(() {
      refreshing = true;
      error = null;
    });
    try {
      await widget.state.refreshProfile();
    } catch (e) {
      if (mounted) {
        setState(
            () => error = e is StateError ? e.message : 'Chưa tải được hồ sơ.');
      }
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  void edit() => Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => EditProfilePage(state: widget.state)),
      );
  @override
  Widget build(BuildContext context) {
    final body = ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final account = widget.state.account;
        if (account == null) return const SizedBox();
        final shipper = account.role == Role.shipper;
        final completed = widget.state.deliveries
            .where((o) => o.status == OrderStatus.delivered && o.paid)
            .toList();
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(22),
            children: [
              if (refreshing) const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        AccountAvatar(account: account, size: 104),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Material(
                            color: profileForest,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: edit,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      account.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        color: profileForest,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      account.email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: profileMuted),
                    ),
                    const SizedBox(height: 12),
                    Chip(
                      backgroundColor: profileSage,
                      side: BorderSide.none,
                      avatar: Icon(
                        shipper
                            ? Icons.delivery_dining_rounded
                            : Icons.person_outline,
                        size: 18,
                        color: profileForest,
                      ),
                      label: Text(
                        shipper ? 'Đối tác giao hàng' : 'Khách hàng',
                        style: const TextStyle(
                          color: profileForest,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (shipper)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: account.photoRequired
                        ? const Color(0xFFFFEEE3)
                        : profileSage,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        account.photoRequired
                            ? Icons.add_a_photo_outlined
                            : Icons.portrait_rounded,
                        color: profileForest,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.photoRequired
                                  ? 'Ảnh đại diện bắt buộc'
                                  : 'Đã có ảnh nhận diện',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: profileForest,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Dùng ảnh rõ khuôn mặt của bạn để khách biết ai giao hàng.',
                              style: TextStyle(
                                color: profileMuted,
                                fontSize: 12,
                              ),
                            )
                          ],
                        ),
                      ),
                      if (account.photoRequired)
                        TextButton(
                          onPressed: edit,
                          child: const Text('Thêm ảnh'),
                        )
                    ],
                  ),
                ),
              if (shipper) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: profileForest,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PHÍ GIAO ĐÃ HOÀN TẤT',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        money(completed.fold<int>(0, (sum, o) => sum + o.fee)),
                        style: const TextStyle(
                          color: Color(0xFFE5F7A4),
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${completed.length} đơn đã giao và thanh toán',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      )
                    ],
                  ),
                )
              ],
              const SizedBox(height: 18),
              profileMenuTile(Icons.person_outline, 'Chỉnh sửa hồ sơ',
                  'Tên, số điện thoại và ảnh đại diện', edit),
              if (!shipper)
                profileMenuTile(Icons.location_on_outlined, 'Địa chỉ giao hàng',
                    widget.state.location, widget.onLocation),
              profileMenuTile(
                  Icons.lock_outline_rounded,
                  'Đổi mật khẩu',
                  account.passwordEnabled
                      ? 'Cập nhật mật khẩu đăng nhập'
                      : 'Tài khoản đăng nhập qua mạng xã hội',
                  () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) =>
                                ChangePasswordPage(state: widget.state)),
                      )),
              if (!shipper)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    account.avatar.isEmpty
                        ? 'Avatar mặc định tự thay đổi theo giới tính trong hồ sơ.'
                        : 'Ảnh riêng của bạn đang được sử dụng.',
                    style: const TextStyle(
                      color: profileMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (error != null) ...[
                Text(error!, style: const TextStyle(color: Colors.red)),
                TextButton(
                  onPressed: refresh,
                  child: const Text('Thử lại hồ sơ'),
                )
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  final navigator = Navigator.of(context);
                  navigator.popUntil((route) => route.isFirst);
                  widget.state.logout();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Đăng xuất tài khoản'),
              ),
              const SizedBox(height: 14)
            ],
          ),
        );
      },
    );
    return widget.embedded
        ? body
        : Scaffold(
            appBar: AppBar(
              title: Text(
                widget.state.account?.role == Role.shipper
                    ? 'Hồ sơ shipper'
                    : 'Hồ sơ của tôi',
              ),
            ),
            body: body,
          );
  }
}
