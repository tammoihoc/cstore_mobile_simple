// Ô thống kê và thẻ doanh thu; trả thao tác về màn hình bằng callback.

import 'package:flutter/material.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/widgets/common.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_colors.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_ui.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_brand_logo.dart';

List<Widget> buildAdminOverview({
  required Map<String, dynamic>? revenue,
  required List<Map<String, dynamic>> brands,
  required VoidCallback onShowAllBrands,
  required ValueChanged<Map<String, dynamic>> onOpenBrand,
}) {
  Widget brandCard(Map<String, dynamic> brand,
          {int? rank, bool highlight = false}) =>
      buildAdminBrandCard(brand,
          onOpenBrand: onOpenBrand, rank: rank, highlight: highlight);
  final data = revenue;
  final ranked = brands.where((b) => adminAmount(b['grossSales']) > 0).toList();
  final leader = data?['topBrand'] is Map<String, dynamic>
      ? data!['topBrand'] as Map<String, dynamic>
      : null;
  return [
    const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 16, color: adminMuted),
          SizedBox(width: 8),
          Text('Toàn thời gian', style: TextStyle(color: adminMuted)),
          Spacer(),
          Text(
            'TỔNG QUAN',
            style: TextStyle(
              color: adminForest,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          )
        ],
      ),
    ),
    Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [adminForest, Color(0xFF2D6751)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng doanh thu tất cả thương hiệu cửa hàng tiện lợi',
            style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              data == null ? '—' : money(adminAmount(data['grossSales'])),
              style: const TextStyle(
                color: adminLime,
                fontSize: 36,
                letterSpacing: -.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.task_alt_rounded, color: adminLime, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đơn đã giao và thanh toán • Không tính phí giao hàng',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    ),
    const SizedBox(height: 14),
    Row(
      children: [
        Expanded(
          child: adminMetric('Thương hiệu đăng ký',
              '${data?['brandCount'] ?? '—'}', Icons.loyalty_outlined),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: adminMetric('Chi nhánh hoạt động',
              '${data?['branchCount'] ?? '—'}', Icons.storefront_outlined),
        )
      ],
    ),
    const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Text(
        'Số thương hiệu và chi nhánh đang hoạt động trên nền tảng.',
        style: TextStyle(color: adminMuted, fontSize: 11),
      ),
    ),
    const SizedBox(height: 14),
    Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: adminLime,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.savings_outlined, color: adminForest, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nền tảng dự kiến nhận 15%',
                  style: TextStyle(color: adminForest, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  data == null
                      ? '—'
                      : money(adminAmount(data['platformRevenue'])),
                  style: const TextStyle(
                    color: adminForest,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                )
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${data?['completedOrders'] ?? '—'}',
                style: const TextStyle(
                  color: adminForest,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'đơn hoàn tất',
                style: TextStyle(fontSize: 10, color: adminForest),
              )
            ],
          )
        ],
      ),
    ),
    heading('Thương hiệu có doanh thu cao nhất'),
    if (leader == null)
      empty('Chưa có đơn đã giao và thanh toán để xếp hạng thương hiệu.')
    else
      brandCard(leader, rank: 1, highlight: true),
    Row(
      children: [
        const Expanded(
          child: Text(
            'Doanh thu theo thương hiệu',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(onPressed: onShowAllBrands, child: const Text('Xem tất cả'))
      ],
    ),
    if (ranked.isEmpty)
      const Text(
        'Doanh thu được tổng hợp từ từng chi nhánh của thương hiệu.',
        style: TextStyle(color: adminMuted, fontSize: 12),
      ),
    for (var i = 0; i < ranked.length && i < 5; i++)
      brandCard(ranked[i], rank: i + 1),
    if (brands
        .any((b) => b['active'] == false && adminAmount(b['grossSales']) > 0))
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Tổng doanh thu giữ cả lịch sử của điểm bán đã ngừng hoạt động.',
          style: TextStyle(color: adminMuted, fontSize: 11),
        ),
      )
  ];
}

Widget adminMetric(String label, String value, IconData icon) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: adminSage,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: adminForest),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: adminForest,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: adminForest, fontSize: 12))
        ],
      ),
    );

Widget buildAdminBrandCard(Map<String, dynamic> brand,
    {required ValueChanged<Map<String, dynamic>> onOpenBrand,
    int? rank,
    bool highlight = false}) {
  final name = brand['name'] as String? ?? 'Thương hiệu';
  final active = brand['active'] != false;
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: highlight ? const Color(0xFFEDF3DE) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => onOpenBrand(brand),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (rank != null) ...[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: rank == 1 ? adminLime : adminSage,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: adminForest,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10)
              ],
              AdminBrandLogo(
                name: name,
                path: brand['image'] as String? ?? '',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: adminForest,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      money(adminAmount(brand['grossSales'])),
                      style: const TextStyle(
                        color: adminForest,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      active
                          ? '${brand['branchCount']} chi nhánh • ${brand['completedOrders']} đơn hoàn tất'
                          : 'Đã ngừng • ${brand['archivedBranchCount']} chi nhánh lưu trữ',
                      style: const TextStyle(
                        color: adminMuted,
                        fontSize: 11,
                      ),
                    )
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: adminMuted)
            ],
          ),
        ),
      ),
    ),
  );
}
