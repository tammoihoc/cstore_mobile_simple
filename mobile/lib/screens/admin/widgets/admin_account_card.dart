// Một thẻ tài khoản và menu chọn thao tác quản lý.

import 'package:flutter/material.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/widgets/account_avatar.dart';
import 'package:cstore_mobile/widgets/date_filter.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_colors.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_ui.dart';

Widget buildAdminAccountCard({
  required Account user,
  required AppState state,
  required bool mutating,
  required ValueChanged<String> onAction,
}) {
  final self = state.account?.id == user.id;
  final branch =
      state.branchList.where((b) => b.id == user.storeId).firstOrNull;
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 4, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccountAvatar(
            account: user,
            path: user.role == Role.store
                ? (branch?.image.isNotEmpty == true
                    ? branch!.image
                    : user.avatar)
                : null,
            size: 58,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.role == Role.store ? branch?.name ?? user.name : user.name}${self ? ' (Bạn)' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: adminForest,
                    fontSize: 16,
                  ),
                ),
                if (user.role == Role.store)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      user.name,
                      style: const TextStyle(
                        color: adminMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 5),
                Text(
                  user.email,
                  style: const TextStyle(color: adminMuted, fontSize: 12),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    user.createdAt == null
                        ? 'Chưa có ngày tạo'
                        : 'Tạo ngày ${displayDay(user.createdAt!)}',
                    style: const TextStyle(
                      color: adminMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (user.phone.isNotEmpty)
                  Text(
                    user.phone,
                    style: const TextStyle(color: adminMuted, fontSize: 12),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    adminBadge(
                        user.storeOwner
                            ? 'Quản lý cửa hàng'
                            : accountRoleName(user.role),
                        adminForest),
                    adminBadge(
                        user.blocked ? 'Đã cấm đăng nhập' : 'Đang hoạt động',
                        user.blocked ? Colors.red : const Color(0xFF437047)),
                    if (user.photoRequired)
                      adminBadge('Cần ảnh đại diện', const Color(0xFF9B581C))
                  ],
                )
              ],
            ),
          ),
          if (!self)
            PopupMenuButton<String>(
                enabled: !mutating,
                tooltip: 'Quản lý tài khoản',
                onSelected: onAction,
                itemBuilder: (_) => [
                      if (user.role != Role.store)
                        const PopupMenuItem(
                          value: 'avatar',
                          child: Text('Cập nhật ảnh đại diện'),
                        ),
                      PopupMenuItem(
                        value: 'status',
                        child: Text(
                          user.blocked ? 'Cho phép đăng nhập' : 'Cấm đăng nhập',
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          user.storeOwner
                              ? 'Xóa cửa hàng và tài khoản'
                              : 'Xóa tài khoản',
                        ),
                      )
                    ])
        ],
      ),
    ),
  );
}
