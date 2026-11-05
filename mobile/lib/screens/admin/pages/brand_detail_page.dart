// Trang doanh thu và danh sách chi nhánh của một thương hiệu.

import 'package:flutter/material.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/widgets/common.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_colors.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_ui.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_brand_logo.dart';

class BrandDetailPage extends StatelessWidget {
  const BrandDetailPage({super.key, required this.brand, this.onAdd});
  final Map<String, dynamic> brand;
  final VoidCallback? onAdd;
  @override
  Widget build(BuildContext context) {
    final name = brand['name'] as String? ?? 'Thương hiệu';
    final gross = adminAmount(brand['grossSales']);
    final branches = adminRows(brand['branches']);
    return Scaffold(
      backgroundColor: adminPaper,
      appBar: AppBar(
        backgroundColor: adminPaper,
        title: const Text('Chi tiết thương hiệu'),
      ),
      floatingActionButton: onAdd == null
          ? null
          : FloatingActionButton.extended(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Thêm chi nhánh'),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          Row(
            children: [
              AdminBrandLogo(
                name: name,
                path: brand['image'] as String? ?? '',
                size: 82,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: adminForest,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    adminBadge('${brand['branchCount']} chi nhánh hoạt động',
                        adminForest),
                    if (adminAmount(brand['archivedBranchCount']) > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(
                          '${brand['archivedBranchCount']} chi nhánh đã ngừng',
                          style: const TextStyle(
                            color: adminMuted,
                            fontSize: 11,
                          ),
                        ),
                      )
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: adminForest,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Doanh thu thương hiệu',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    money(gross),
                    style: const TextStyle(
                      fontSize: 34,
                      color: adminLime,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  '${brand['completedOrders']} đơn đã giao và thanh toán',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const Divider(color: Colors.white24, height: 28),
                Text(
                  'Nền tảng dự kiến nhận 15%: ${money(adminAmount(brand['platformRevenue']))}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                )
              ],
            ),
          ),
          heading('Danh sách chi nhánh (${branches.length})',
              'Doanh thu từng điểm bán được cộng vào thương hiệu'),
          for (final branch in branches)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          color: adminForest,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            branch['name'] as String? ?? 'Chi nhánh',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (branch['active'] == false)
                          adminBadge('Đã ngừng', adminMuted)
                      ],
                    ),
                    const SizedBox(height: 12),
                    adminValueRow(
                        'Doanh thu', money(adminAmount(branch['grossSales'])),
                        emphasized: true),
                    const SizedBox(height: 7),
                    Text(
                      '${branch['completedOrders']} đơn hoàn tất',
                      style: const TextStyle(
                        color: adminMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        color: adminForest,
                        backgroundColor: adminSage,
                        value: gross == 0
                            ? 0
                            : (adminAmount(branch['grossSales']) / gross)
                                .clamp(0, 1),
                      ),
                    )
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}
