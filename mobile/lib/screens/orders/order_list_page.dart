// Danh sách đơn theo vai trò; lọc trạng thái/ngày và mở trang chi tiết.

import 'package:flutter/material.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/widgets/common.dart';
import 'package:cstore_mobile/widgets/date_filter.dart';
import 'package:cstore_mobile/widgets/order_widgets.dart';
import 'package:cstore_mobile/screens/orders/order_detail_page.dart';

class OrderList extends StatefulWidget {
  const OrderList({super.key, required this.state, required this.role});
  final AppState state;
  final Role role;
  @override
  State<OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<OrderList> {
  String filter = 'Tất cả';
  DateTimeRange? dateRange;
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final source = widget.role == Role.store
        ? s.storeOrders
        : widget.role == Role.shipper
            ? s.deliveries
            : s.customerOrders;
    final orders = source
        .where((o) => inDateRange(o.created, dateRange))
        .where((o) => switch (filter) {
              'Chờ xác nhận' => o.status == OrderStatus.pending,
              'Đang giao' =>
                o.activeDelivery || o.status == OrderStatus.accepted,
              'Hoàn tất' => o.status == OrderStatus.delivered,
              'Từ chối / hủy' => [OrderStatus.rejected, OrderStatus.cancelled]
                  .contains(o.status),
              _ => true
            })
        .toList()
      ..sort((a, b) => b.created.compareTo(a.created));
    return RefreshIndicator(
      onRefresh: s.reload,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          heading('Đơn hàng & hóa đơn',
              '${orders.length}/${source.length} đơn • Theo dõi từng chặng giao'),
          DateFilterBar(
            value: dateRange,
            onChanged: (v) => setState(() => dateRange = v),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final v in [
                  'Tất cả',
                  'Chờ xác nhận',
                  'Đang giao',
                  'Hoàn tất',
                  'Từ chối / hủy'
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(v),
                      selected: filter == v,
                      onSelected: (_) => setState(() => filter = v),
                    ),
                  )
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (orders.isEmpty) empty('Chưa có đơn hàng phù hợp'),
          for (final o in orders)
            OrderPreview(
              order: o,
              branchName: s.branchList
                      .where((b) => b.id == o.branchId)
                      .firstOrNull
                      ?.name ??
                  'Chi nhánh #${o.branchId}',
              delivery: widget.role == Role.shipper,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => OrderDetail(
                          state: s,
                          order: o,
                          role: widget.role,
                        )),
              ),
            )
        ],
      ),
    );
  }
}
