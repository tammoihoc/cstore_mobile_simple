// Bộ lọc tài khoản theo vai trò, tên, ngày tạo và thứ tự sắp xếp.

import 'package:flutter/material.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/widgets/common.dart';
import 'package:cstore_mobile/widgets/date_filter.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_colors.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_ui.dart';

List<Widget> buildAdminAccountFilters({
  required List<Account>? accounts,
  required List<Account> users,
  required Role? filter,
  required DateTimeRange? accountDates,
  required bool newestFirst,
  required ValueChanged<Role?> onRoleChanged,
  required ValueChanged<String> onSearchChanged,
  required ValueChanged<DateTimeRange?> onDatesChanged,
  required ValueChanged<bool> onSortChanged,
  required VoidCallback onReset,
}) {
  final active = (accounts ?? []).where((u) => !u.deleted).toList();
  return [
    heading(
        'Quản lý tài khoản', 'Nhận diện đúng người, kết nối đúng thương hiệu'),
    LayoutBuilder(
      builder: (context, box) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final role in [
            Role.customer,
            Role.store,
            Role.shipper,
            Role.admin
          ])
            SizedBox(
              width: (box.maxWidth - 10) / 2,
              child: Material(
                color: filter == role ? adminForest : Colors.white,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onRoleChanged(filter == role ? null : role),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          accountRoleIcon(role),
                          color: filter == role ? adminLime : adminForest,
                          size: 25,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${active.where((u) => u.role == role).length}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: filter == role
                                      ? Colors.white
                                      : adminForest,
                                ),
                              ),
                              Text(
                                accountRoleName(role),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: filter == role
                                      ? Colors.white70
                                      : adminMuted,
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            )
        ],
      ),
    ),
    const SizedBox(height: 20),
    TextField(
      decoration: const InputDecoration(
        hintText: 'Tìm theo tên hoặc email',
        prefixIcon: Icon(Icons.search_rounded),
      ),
      onChanged: onSearchChanged,
    ),
    const SizedBox(height: 12),
    DropdownButtonFormField<String>(
        key: ValueKey(filter),
        initialValue: filter?.name ?? 'ALL',
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Loại tài khoản',
          prefixIcon: Icon(Icons.manage_accounts_outlined),
        ),
        items: [
          const DropdownMenuItem(
            value: 'ALL',
            child: Text('Tất cả loại tài khoản'),
          ),
          for (final role in Role.values)
            DropdownMenuItem(
              value: role.name,
              child: Text(accountRoleName(role)),
            )
        ],
        onChanged: (v) =>
            onRoleChanged(v == 'ALL' ? null : Role.values.byName(v!))),
    const SizedBox(height: 14),
    DateFilterBar(
      value: accountDates,
      label: 'Ngày tạo tài khoản',
      onChanged: onDatesChanged,
    ),
    const SizedBox(height: 12),
    DropdownButtonFormField<bool>(
        initialValue: newestFirst,
        decoration: const InputDecoration(
          labelText: 'Sắp xếp tài khoản',
          prefixIcon: Icon(Icons.sort),
        ),
        items: const [
          DropdownMenuItem(value: true, child: Text('Mới nhất trước')),
          DropdownMenuItem(value: false, child: Text('Cũ nhất trước'))
        ],
        onChanged: (v) => onSortChanged(v!)),
    const SizedBox(height: 8),
    Row(
      children: [
        Expanded(
          child: Text(
            '${users.length} tài khoản${filter == null ? '' : ' • ${accountRoleName(filter)}'}',
            style: const TextStyle(
              color: adminMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(onPressed: onReset, child: const Text('Tất cả'))
      ],
    ),
    const SizedBox(height: 4)
  ];
}
