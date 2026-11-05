// Trang xem giỏ hàng; quy trình xác nhận đặt hàng nằm trong checkout_page.dart.

import 'package:flutter/material.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/widgets/common.dart';
import 'package:cstore_mobile/widgets/product_image.dart';
import 'package:cstore_mobile/widgets/order_widgets.dart';
import 'package:cstore_mobile/screens/customer/checkout_page.dart';

export 'checkout_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: const Text('Giỏ hàng')),
          bottomNavigationBar: state.cart.isEmpty
              ? null
              : SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => CheckoutPage(state: state)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tiếp tục đặt hàng'),
                          Text(money(state.subtotal))
                        ],
                      ),
                    ),
                  ),
                ),
          body: state.cart.isEmpty
              ? empty('Giỏ hàng trống')
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    heading('Món ngon đã chọn', state.selected!.name),
                    for (final e in state.cart.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: ProductImage(
                                  path: state.product(e.key).asset,
                                  width: 82,
                                  height: 88,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.product(e.key).name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      money(state.product(e.key).price),
                                      style: const TextStyle(
                                        color: forest,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          tooltip: 'Giảm số lượng',
                                          onPressed: () => state.change(
                                              state.product(e.key), -1),
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                        ),
                                        Text(
                                          '${e.value}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          tooltip: 'Tăng số lượng',
                                          onPressed: e.value <
                                                  state.product(e.key).stock
                                              ? () => state.change(
                                                  state.product(e.key), 1)
                                              : null,
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                          ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    AmountRow('Tạm tính', state.subtotal, total: true),
                    const Text(
                      'Phí giao hàng được tính theo điểm giao đã ghim.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    )
                  ],
                ),
        ),
      );
}
