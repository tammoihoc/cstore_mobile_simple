// Tổng quan: dùng StoreMetrics để tính doanh thu, tồn kho và báo cáo.

import 'package:flutter/material.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/widgets/common.dart';
import 'package:cstore_mobile/widgets/product_image.dart';
import 'package:cstore_mobile/widgets/account_avatar.dart';
import 'package:cstore_mobile/widgets/date_filter.dart';
import 'package:cstore_mobile/screens/store/widgets/store_styles.dart';
import 'package:cstore_mobile/screens/store/widgets/store_components.dart';
import 'package:cstore_mobile/models/store_metrics.dart';

/// Nhận dữ liệu và callback; trạng thái bộ lọc vẫn do StoreHome giữ.
Widget buildStoreDashboard({
  required AppState state,
  required DateTimeRange? reportDates,
  required ValueChanged<DateTimeRange?> onReportDatesChanged,
  required VoidCallback onOrdersTap,
  required VoidCallback onInventoryTap,
}) {
  final s = state;
  final branch = s.branch(s.storeBranchId);
  final stock = s.products
      .where((product) => product.branchId == s.storeBranchId && product.active)
      .toList();

  final data = StoreMetrics(s.storeOrders, reportDates);
  final daily = data.dailyRevenue.entries.toList()
    ..sort((a, b) => b.key.compareTo(a.key));
  final maxDaily = daily.fold<int>(0, (v, e) => e.value > v ? e.value : v);
  final low = stock.where((p) => p.stock > 0 && p.stock <= 5).length,
      emptyStock = stock.where((p) => p.stock == 0).length;
  return RefreshIndicator(
    onRefresh: s.reload,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            AccountAvatar(path: branch.image, role: Role.store, size: 66),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch.brand ?? branch.name,
                    style: const TextStyle(color: storeMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tổng quan kinh doanh',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: storeForest,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 22),
        DateFilterBar(
          value: reportDates,
          label: 'Thời gian báo cáo',
          onChanged: onReportDatesChanged,
        ),
        const SizedBox(height: 18),
        storePanel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        color: storeLime),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'DOANH THU TIỀN HÀNG',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 18),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    money(data.revenue),
                    style: const TextStyle(
                      color: storeLime,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${data.completed.length} đơn đã giao và đã thanh toán trong kỳ',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Divider(height: 32, color: Colors.white24),
                storeFinanceRow('Phí nền tảng 15%', money(data.commission)),
                const SizedBox(height: 12),
                storeFinanceRow(
                    'Dự kiến cửa hàng nhận', money(data.estimatedNet),
                    strong: true),
                const SizedBox(height: 14),
                const Text(
                  'Theo ngày hoàn tất. Không cộng phí giao hàng vào doanh thu cửa hàng.',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                )
              ],
            ),
            color: storeForest),
        storePanel(
            Row(
              children: [
                const Icon(Icons.delivery_dining_rounded, color: storeForest),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phí giao hàng thu hộ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tách riêng khỏi tiền hàng và phí nền tảng',
                        style: TextStyle(fontSize: 11, color: storeMuted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        money(data.deliveryFees),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: storeForest,
                          fontSize: 20,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
            color: storeSage),
        heading('Đơn hàng trong kỳ',
            'Theo ngày đặt đơn • Mỗi đơn thuộc một trạng thái hiện tại'),
        LayoutBuilder(
          builder: (_, box) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in [
                (
                  'Tổng đơn đặt',
                  data.placed.length,
                  Icons.receipt_long_outlined
                ),
                ('Chờ xác nhận', data.waiting, Icons.hourglass_empty_rounded),
                ('Chờ tài xế nhận', data.accepted, Icons.storefront_outlined),
                ('Đang giao', data.delivering, Icons.local_shipping_outlined),
                (
                  'Đã giao & thanh toán',
                  data.placedCompleted,
                  Icons.task_alt_rounded
                ),
                ('Hủy / từ chối', data.stopped, Icons.cancel_outlined),
                if (data.unpaidDelivered > 0)
                  (
                    'Đã giao, chưa thanh toán',
                    data.unpaidDelivered,
                    Icons.payments_outlined
                  )
              ])
                SizedBox(
                  width: (box.maxWidth - 12) / 2,
                  child: storeMetric(item.$1, '${item.$2}', item.$3,
                      onTap: onOrdersTap),
                )
            ],
          ),
        ),
        heading('Doanh thu theo ngày',
            'Tiền hàng từ các đơn đã hoàn tất và thanh toán'),
        storePanel(daily.isEmpty
            ? const Text(
                'Chưa có doanh thu trong khoảng ngày này.',
                style: TextStyle(color: storeMuted),
              )
            : Column(
                children: [
                  for (final e in daily.take(7))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayDay(e.key),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: storeMuted,
                                  ),
                                ),
                              ),
                              Text(
                                money(e.value),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: storeForest,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: maxDaily == 0 ? 0 : e.value / maxDaily,
                              backgroundColor: storeSage,
                              color: storeForest,
                              minHeight: 6,
                            ),
                          )
                        ],
                      ),
                    ),
                  if (daily.length > 7)
                    const Text(
                      'Hiển thị 7 ngày có doanh thu gần nhất trong kỳ.',
                      style: TextStyle(color: storeMuted, fontSize: 11),
                    )
                ],
              )),
        heading(
            'Món bán tốt', 'Xếp theo tiền hàng thực tế đã giao và thanh toán'),
        storePanel(data.bestSellers.isEmpty
            ? const Text(
                'Chưa có món được giao thành công trong kỳ.',
                style: TextStyle(color: storeMuted),
              )
            : Column(
                children: [
                  for (final product in data.bestSellers.take(5))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: ProductImage(
                              path: product.line.image,
                              width: 58,
                              height: 58,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.line.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${product.quantity} sản phẩm đã bán',
                                  style: const TextStyle(
                                    color: storeMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  money(product.revenue),
                                  style: const TextStyle(
                                    color: storeForest,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    )
                ],
              )),
        heading('Tồn kho hiện tại', 'Số lượng khả dụng tại chi nhánh'),
        storePanel(Column(
          children: [
            storeStockRow('Đang kinh doanh', '${stock.length} sản phẩm'),
            const Divider(height: 28),
            storeStockRow('Sắp hết hàng (1–5)', '$low sản phẩm'),
            const SizedBox(height: 12),
            storeStockRow('Hết hàng', '$emptyStock sản phẩm'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onInventoryTap,
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Quản lý tồn kho'),
              ),
            )
          ],
        )),
      ],
    ),
  );
}
