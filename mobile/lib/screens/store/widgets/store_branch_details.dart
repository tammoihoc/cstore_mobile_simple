// Chi nhánh: xem thông tin cửa hàng, tài khoản phụ trách và đổi mật khẩu.

import 'package:flutter/material.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/widgets/common.dart';
import 'package:cstore_mobile/widgets/account_avatar.dart';
import 'package:cstore_mobile/screens/store/widgets/store_styles.dart';
import 'package:cstore_mobile/screens/store/widgets/store_components.dart';

Widget buildStoreBranchDetails({
  required AppState state,
  required VoidCallback onChangePassword,
}) {
  final s = state;
  final branch = s.branch(s.storeBranchId);
  return RefreshIndicator(
    onRefresh: () async {
      await s.reloadBranches();
      await s.refreshProfile();
    },
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        heading(
            'Chi nhánh & tài khoản', 'Thông tin nhận diện và người phụ trách'),
        storePanel(Column(
          children: [
            AccountAvatar(path: branch.image, role: Role.store, size: 104),
            const SizedBox(height: 18),
            Text(
              branch.brand ?? branch.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: storeForest,
                fontWeight: FontWeight.w800,
                fontSize: 25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              branch.name,
              textAlign: TextAlign.center,
              style: const TextStyle(color: storeMuted),
            ),
            const SizedBox(height: 14),
            Chip(
              side: BorderSide.none,
              backgroundColor: storeSage,
              label: Text(
                'Mã chi nhánh #${branch.id}',
                style: const TextStyle(color: storeForest),
              ),
            )
          ],
        )),
        storePanel(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on_outlined, color: storeForest),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Địa chỉ chi nhánh',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(branch.address),
                  const SizedBox(height: 8),
                  Text(
                    '${branch.lat.toStringAsFixed(6)}, ${branch.lng.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 11, color: storeMuted),
                  )
                ],
              ),
            )
          ],
        )),
        storePanel(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tài khoản phụ trách',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: storeForest,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                AccountAvatar(
                  account: s.account,
                  path: branch.image,
                  role: Role.store,
                  size: 52,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.account?.name ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        s.account?.email ?? '',
                        style: const TextStyle(fontSize: 12, color: storeMuted),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        s.account?.storeOwner == true
                            ? 'Quản lý cửa hàng'
                            : 'Nhân viên chi nhánh',
                        style:
                            const TextStyle(fontSize: 11, color: storeForest),
                      )
                    ],
                  ),
                )
              ],
            )
          ],
        )),
        Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: const CircleAvatar(
              backgroundColor: storeSage,
              child: Icon(Icons.lock_outline_rounded, color: storeForest),
            ),
            title: const Text(
              'Đổi mật khẩu',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Quản lý bảo mật đăng nhập',
              style: TextStyle(fontSize: 12, color: storeMuted),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onChangePassword,
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(14),
          child: Text(
            'Liên hệ quản trị viên để cập nhật logo, thông tin chi nhánh hoặc cấp thêm tài khoản.',
            style: TextStyle(fontSize: 12, color: storeMuted),
          ),
        ),
        OutlinedButton.icon(
          onPressed: s.logout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Đăng xuất tài khoản'),
        )
      ],
    ),
  );
}
