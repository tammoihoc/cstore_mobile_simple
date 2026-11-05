// Chi tiết đơn và các thao tác theo vai trò/trạng thái hiện tại.

import 'package:flutter/material.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/widgets/common.dart';
import 'package:cstore_mobile/widgets/account_avatar.dart';
import 'package:cstore_mobile/widgets/order_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cstore_mobile/screens/shipper/navigation_route.dart';

class OrderDetail extends StatefulWidget {
  const OrderDetail(
      {super.key,
      required this.state,
      required this.order,
      required this.role});
  final AppState state;
  final ShopOrder order;
  final Role role;
  @override
  State<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  bool busy = false;
  AppState get state => widget.state;
  Role get role => widget.role;

  // Chặn bấm lặp, chạy thao tác bất đồng bộ rồi bật lại các nút.
  Future<void> run(Future<void> Function() action) async {
    if (busy || !mounted) return;
    setState(() => busy = true);
    await attempt(context, action);
    if (mounted) setState(() => busy = false);
  }

  String date(DateTime value) {
    final d = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)} · ${two(d.day)}/${two(d.month)}/${d.year}';
  }

  Widget panel(Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final o = state.orders
                  .where((o) => o.id == widget.order.id)
                  .firstOrNull ??
              state.offers.where((o) => o.id == widget.order.id).firstOrNull ??
              widget.order;
          final branch =
              state.branchList.where((b) => b.id == o.branchId).firstOrNull;
          return Scaffold(
            appBar: AppBar(title: Text('Đơn #CS${o.id}')),
            body: RefreshIndicator(
              onRefresh: state.reload,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: forest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          o.status == OrderStatus.delivered
                              ? Icons.task_alt_rounded
                              : Icons.local_shipping_outlined,
                          color: const Color(0xFFCCE2BB),
                          size: 34,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          statusNames[o.status.index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          branch?.name ?? 'Chi nhánh #${o.branchId}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Đặt lúc ${date(o.created)}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        )
                      ],
                    ),
                  ),
                  heading('Thông tin giao hàng'),
                  panel(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: orange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  o.recipient,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(o.address),
                                const SizedBox(height: 6),
                                Text(
                                  o.phone,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                  ),
                                )
                              ],
                            ),
                          ),
                          if (role != Role.customer &&
                              o.phone.trim().isNotEmpty)
                            IconButton(
                              tooltip: 'Gọi người nhận',
                              onPressed: () =>
                                  launchUrl(Uri(scheme: 'tel', path: o.phone)),
                              icon: const Icon(
                                Icons.call_outlined,
                                color: forest,
                              ),
                            )
                        ],
                      ),
                      if (role != Role.customer && branch != null) ...[
                        const Divider(height: 26),
                        Text(
                          'LẤY HÀNG TẠI',
                          style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.3,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          branch.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(branch.address)
                      ],
                      if (o.shipperId != null) ...[
                        const Divider(height: 26),
                        Row(
                          children: [
                            AccountAvatar(
                              path: o.shipperAvatar ?? '',
                              role: Role.shipper,
                              size: 62,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    role == Role.customer
                                        ? 'Người giao hàng của bạn'
                                        : 'Tài xế phụ trách',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    o.shipperName ?? 'Shipper đã nhận đơn',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (o.shipperPhone != null)
                                    Text(
                                      o.shipperPhone!,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    )
                                ],
                              ),
                            ),
                            if (role != Role.shipper &&
                                o.shipperId != state.shipperId &&
                                o.shipperPhone?.trim().isNotEmpty == true)
                              IconButton(
                                tooltip: 'Gọi shipper',
                                onPressed: () => launchUrl(
                                    Uri(scheme: 'tel', path: o.shipperPhone)),
                                icon: const Icon(
                                  Icons.call_outlined,
                                  color: forest,
                                ),
                              )
                          ],
                        )
                      ],
                      if (o.distanceSource == 'ROAD' &&
                          o.distanceKm != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${o.distanceKm!.toStringAsFixed(2)} km đường đi${o.durationSeconds == null ? '' : ' · ${(o.durationSeconds! / 60).ceil()} phút ước tính'}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        )
                      ] else ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Chưa có khoảng cách đường đi cho đơn cũ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        )
                      ]
                    ],
                  )),
                  if (role == Role.shipper &&
                      (o.status == OrderStatus.accepted || o.activeDelivery))
                    panel(Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.route_rounded, color: forest),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Lộ trình giao hàng',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          [OrderStatus.accepted, OrderStatus.assigned]
                                  .contains(o.status)
                              ? 'Xem đường từ tài xế đến cửa hàng và chặng giao đến khách.'
                              : 'Xem đường từ vị trí tài xế đến điểm giao của khách.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => ShipperNavigationPage(
                                      state: state,
                                      order: o,
                                    )),
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Mở bản đồ giao hàng'),
                        )
                      ],
                    )),
                  heading('Món hàng & thanh toán',
                      '${o.lines.fold<int>(0, (s, l) => s + l.quantity)} sản phẩm'),
                  panel(Column(
                    children: [
                      for (final l in o.lines)
                        OrderItemRow(
                          line: l,
                          imageFallback: state.products
                                  .where((p) => p.id == l.productId)
                                  .firstOrNull
                                  ?.asset ??
                              '',
                        ),
                      const Divider(),
                      AmountRow('Tiền hàng', o.subtotal),
                      AmountRow('Phí giao hàng', o.fee),
                      const Divider(),
                      AmountRow('Tổng thanh toán', o.total, total: true),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: o.paid
                              ? const Color(0xFFEAF2EC)
                              : const Color(0xFFFFF3E7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              o.paid
                                  ? Icons.verified_outlined
                                  : Icons.payments_outlined,
                              color: o.paid ? forest : orange,
                              size: 21,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                o.paid
                                    ? 'Đã thanh toán · ${o.paidAt == null ? '' : date(o.paidAt!)}'
                                    : 'COD · Chưa thanh toán',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  )),
                  if (o.reason?.isNotEmpty == true)
                    panel(Text(
                      'Lý do: ${o.reason}',
                      style: const TextStyle(color: Color(0xFF9F4940)),
                    )),
                  ...actions(o),
                  heading('Theo dõi đơn'),
                  panel(Column(
                    children: [
                      for (var i = 0; i < o.history.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Icon(
                                i == o.history.length - 1
                                    ? Icons.radio_button_checked
                                    : Icons.check_circle,
                                color: forest,
                                size: 20,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  statusNames[o.history[i].status.index],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                date(o.history[i].at),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              )
                            ],
                          ),
                        )
                    ],
                  )),
                  if (busy) const Center(child: CircularProgressIndicator())
                ],
              ),
            ),
          );
        },
      );

  // Chỉ hiện nút phù hợp với vai trò/trạng thái; backend vẫn xác thực mỗi thao tác.
  List<Widget> actions(ShopOrder o) => [
        if (role == Role.customer && o.status == OrderStatus.pending)
          OutlinedButton(
            onPressed: busy
                ? null
                : () async {
                    final yes = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                              title: const Text('Hủy đơn hàng?'),
                              content: const Text(
                                'Cửa hàng chưa xác nhận đơn. Bạn có thể hủy ngay lúc này.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const Text('Giữ đơn'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('Hủy đơn'),
                                )
                              ],
                            ));
                    if (yes == true && mounted) {
                      await run(() =>
                          state.transition(o, OrderStatus.cancelled, role));
                    }
                  },
            child: const Text('Hủy đơn hàng'),
          ),
        if (role == Role.store && o.status == OrderStatus.pending) ...[
          FilledButton(
            onPressed: busy
                ? null
                : () =>
                    run(() => state.transition(o, OrderStatus.accepted, role)),
            child: const Text('Chấp nhận đơn'),
          ),
          OutlinedButton(
            onPressed: busy
                ? null
                : () async {
                    final reason = await ask(context, 'Lý do từ chối');
                    if (reason != null && mounted) {
                      await run(() => state.transition(
                          o, OrderStatus.rejected, role,
                          reason: reason));
                    }
                  },
            child: const Text('Từ chối đơn'),
          )
        ],
        if (role == Role.shipper && o.status == OrderStatus.accepted)
          FilledButton(
            onPressed: busy ? null : () => run(() => state.claim(o)),
            child: const Text('Nhận giao đơn này'),
          ),
        if (role == Role.shipper &&
            o.shipperId == state.shipperId &&
            o.activeDelivery)
          FilledButton(
            onPressed: busy
                ? null
                : () => run(() => state.transition(
                    o, OrderStatus.values[o.status.index + 1], role)),
            child: Text(
              o.status == OrderStatus.assigned
                  ? 'Đã lấy hàng'
                  : o.status == OrderStatus.pickedUp
                      ? 'Bắt đầu giao'
                      : 'Xác nhận đã giao',
            ),
          ),
        if (!o.paid &&
            ((role == Role.store &&
                    ![
                      OrderStatus.pending,
                      OrderStatus.rejected,
                      OrderStatus.cancelled
                    ].contains(o.status)) ||
                (role == Role.shipper &&
                    o.shipperId == state.shipperId &&
                    [OrderStatus.pickedUp, OrderStatus.delivering]
                        .contains(o.status))))
          OutlinedButton(
            onPressed: busy
                ? null
                : () async {
                    final yes = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                              title: const Text('Đã thực nhận đủ tiền?'),
                              content: Text(
                                'Chỉ xác nhận khi đã nhận ${money(o.total)}. Thao tác được ghi nhận một lần.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const Text('Chưa nhận'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('Đã nhận đủ'),
                                )
                              ],
                            ));
                    if (yes == true && mounted) {
                      await run(() => state.pay(o, role));
                    }
                  },
            child: const Text('Xác nhận đã nhận tiền'),
          ),
        const SizedBox(height: 8)
      ];
}
