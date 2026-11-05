// Trang xác nhận đặt hàng: ghim địa chỉ, lấy báo giá và gửi đơn lên máy chủ.

import 'package:flutter/material.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/widgets/common.dart';
import 'package:cstore_mobile/widgets/order_widgets.dart';
import 'package:cstore_mobile/screens/orders.dart';
import 'package:cstore_mobile/screens/location_picker.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.state});
  final AppState state;
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), phone = TextEditingController();
  bool pinConfirmed = false, busy = false;
  bool quoteLoading = false;
  DeliveryQuote? quote;
  String? quoteError;
  int quoteRevision = 0;
  late final TextEditingController address, lat, lng;
  @override
  void initState() {
    super.initState();
    final s = widget.state;
    name.text = s.account?.name ?? '';
    phone.text = s.account?.phone ?? '';
    pinConfirmed = s.positionKnown;
    address = TextEditingController(text: pinConfirmed ? s.location : '');
    lat = TextEditingController(text: '${s.lat}');
    lng = TextEditingController(text: '${s.lng}');
    if (pinConfirmed) loadQuote();
  }

  @override
  void dispose() {
    quoteRevision++;
    for (final c in [name, phone, address, lat, lng]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> chooseLocation() async {
    final s = widget.state;
    final p = await Navigator.push<PinnedLocation>(
        context,
        MaterialPageRoute(
          builder: (_) => LocationPicker(
            title: 'Chọn điểm giao hàng',
            lat: double.tryParse(lat.text) ?? s.lat,
            lng: double.tryParse(lng.text) ?? s.lng,
            address: address.text,
            initialPinConfirmed: pinConfirmed,
            branches: s.branchList,
          ),
        ));
    if (p != null && mounted) {
      await attempt(context, () async {
        await s.setLocation(p.address, p.lat, p.lng);
        if (!mounted) return;
        setState(() {
          address.text = p.address;
          lat.text = '${p.lat}';
          lng.text = '${p.lng}';
          pinConfirmed = true;
        });
        await loadQuote();
      });
    }
  }

  Future<void> loadQuote() async {
    final store = widget.state.selected;
    if (!pinConfirmed || store == null) return;
    final request = ++quoteRevision;
    setState(() {
      quoteLoading = true;
      quote = null;
      quoteError = null;
    });
    try {
      final loaded = await widget.state
          .quoteDelivery(store, double.parse(lat.text), double.parse(lng.text));
      if (!mounted || request != quoteRevision) return;
      setState(() => quote = loaded);
    } catch (e) {
      if (!mounted || request != quoteRevision) return;
      setState(() => quoteError = e is StateError
          ? e.message
          : 'Chưa tính được đường đi. Kiểm tra kết nối và thử lại.');
    } finally {
      if (mounted && request == quoteRevision) {
        setState(() => quoteLoading = false);
      }
    }
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    if (!pinConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng ghim điểm giao hàng trên bản đồ.'),
      ));
      return;
    }
    if (quoteLoading || quote == null) return;
    setState(() => busy = true);
    await attempt(context, () async {
      final o = await widget.state.checkout(name.text.trim(), phone.text.trim(),
          address.text.trim(), double.parse(lat.text), double.parse(lng.text));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
            builder: (_) => OrderDetail(
                  state: widget.state,
                  order: o,
                  role: Role.customer,
                )),
      );
    });
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) => content(context),
      );

  Widget content(BuildContext context) {
    final s = widget.state;
    if (s.selected == null || s.cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Xác nhận đặt hàng')),
        body: empty('Giỏ hàng trống'),
      );
    }
    final fee = pinConfirmed ? quote?.fee : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận đặt hàng')),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: FilledButton(
            onPressed: busy || quoteLoading || (pinConfirmed && quote == null)
                ? null
                : submit,
            child: Text(
              busy ? 'Đang đặt hàng…' : 'Xác nhận đặt hàng COD',
            ),
          ),
        ),
      ),
      body: Form(
        key: form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading('Giao hàng đến bạn', 'Kiểm tra thông tin trước khi đặt'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: forest,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pinConfirmed
                                ? 'Điểm giao đã lưu'
                                : 'Chọn điểm giao hàng',
                            style: const TextStyle(
                              color: forest,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            address.text.isEmpty
                                ? 'Ghim trên bản đồ để tính phí giao chính xác.'
                                : address.text,
                          ),
                          TextButton.icon(
                            onPressed: busy ? null : chooseLocation,
                            icon: const Icon(
                              Icons.pin_drop_outlined,
                              size: 18,
                            ),
                            label: Text(
                              pinConfirmed
                                  ? 'Đã ghim vị trí giao hàng'
                                  : 'Chọn điểm giao trên bản đồ',
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 18),
              for (final e in [
                (name, 'Tên người nhận'),
                (phone, 'Số điện thoại')
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    key: ValueKey(
                      e.$1 == name ? 'checkout-recipient' : 'checkout-phone',
                    ),
                    controller: e.$1,
                    enabled: !busy,
                    decoration: InputDecoration(labelText: e.$2),
                    keyboardType: e.$1 == phone ? TextInputType.phone : null,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Không được bỏ trống';
                      }
                      if (e.$1 == phone &&
                          !RegExp(r'^0[0-9]{9}$').hasMatch(v.trim())) {
                        return 'Nhập 10 chữ số, bắt đầu bằng 0';
                      }
                      return null;
                    },
                  ),
                ),
              heading('Đơn hàng của bạn', s.selected!.name),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    for (final e in s.cart.entries)
                      OrderItemRow(
                        line: OrderLine(
                          s.product(e.key).id,
                          s.product(e.key).name,
                          s.product(e.key).price,
                          e.value,
                          image: s.product(e.key).asset,
                        ),
                      ),
                    const Divider(),
                    AmountRow('Tiền hàng', s.subtotal),
                    if (quoteLoading)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Đang tính tuyến đường giao hàng…',
                              ),
                            )
                          ],
                        ),
                      ),
                    if (quote != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.route_rounded,
                              color: forest,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${quote!.distanceKm.toStringAsFixed(2)} km đường đi • khoảng ${(quote!.durationSeconds / 60).ceil().clamp(1, 9999)} phút',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: forest,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    if (quoteError != null) ...[
                      Text(
                        quoteError!,
                        style: const TextStyle(color: orange),
                      ),
                      TextButton(
                        onPressed: quoteLoading ? null : loadQuote,
                        child: const Text('Thử lại tuyến đường'),
                      ),
                    ],
                    if (fee != null) AmountRow('Phí giao hàng', fee),
                    if (!pinConfirmed)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Ghim điểm giao để xem phí vận chuyển.',
                          style: TextStyle(color: orange),
                        ),
                      ),
                    const Divider(),
                    if (fee != null)
                      AmountRow(
                        'Tổng thanh toán',
                        s.subtotal + fee,
                        total: true,
                      ),
                    if (fee == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Tổng thanh toán sẽ hiển thị khi có tuyến đường.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12)
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.payments_outlined, color: forest),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Thanh toán COD khi nhận hàng',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12)
            ],
          ),
        ),
      ),
    );
  }
}
