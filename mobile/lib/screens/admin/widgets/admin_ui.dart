// Nhãn, trường nhập và phép đổi dữ liệu nhỏ của giao diện quản trị.

import 'package:flutter/material.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_colors.dart';

List<Map<String, dynamic>> adminRows(dynamic value) =>
    value is List ? value.whereType<Map<String, dynamic>>().toList() : [];

int adminAmount(dynamic value) => (value as num?)?.round() ?? 0;
String accountRoleName(Role role) => switch (role) {
      Role.customer => 'Khách hàng',
      Role.store => 'Cửa hàng',
      Role.shipper => 'Shipper',
      Role.admin => 'Quản trị viên'
    };
IconData accountRoleIcon(Role role) => switch (role) {
      Role.customer => Icons.person_outline_rounded,
      Role.store => Icons.storefront_outlined,
      Role.shipper => Icons.delivery_dining_rounded,
      Role.admin => Icons.admin_panel_settings_outlined
    };
Widget adminBadge(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
Widget adminValueRow(String label, String value, {bool emphasized = false}) =>
    Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: adminMuted))),
        Text(
          value,
          style: TextStyle(
            color: emphasized ? adminForest : null,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
          ),
        )
      ],
    );
Widget adminStepHeading(int number, String title, String subtitle) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE6EFE6),
            child: Text(
              '$number',
              style: const TextStyle(
                color: adminForest,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(color: adminMuted, height: 1.4))
              ],
            ),
          )
        ],
      ),
    );
Widget adminFormField(TextEditingController controller, String label,
        {bool enabled = true, bool secret = false, bool email = false}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        obscureText: secret,
        keyboardType: email ? TextInputType.emailAddress : null,
        decoration: InputDecoration(labelText: label),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Không được bỏ trống';
          if (email && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
            return 'Email không hợp lệ';
          }
          if (secret && (v.length < 8 || v.length > 72)) {
            return 'Mật khẩu từ 8–72 ký tự';
          }
          return null;
        },
      ),
    );
