import '../../widgets/product_image.dart';
import '../../widgets/sync_status.dart';
import '../../widgets/order_widgets.dart';
import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import 'cart_page.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key, required this.state});
  final AppState state;
  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  String query = '', category = 'Tất cả';
  bool leaving = false;
  Future<void> leave() async {
    final s = widget.state;
    final ok = s.cart.isEmpty ||
        await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                      title: const Text('Rời chi nhánh?'),
                      content: const Text(
                        'Toàn bộ sản phẩm trong giỏ hàng sẽ được xóa.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Ở lại'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Xóa giỏ và rời'),
                        )
                      ],
                    )) ==
            true;
    if (ok && mounted) {
      s.select(null);
      setState(() => leaving = true);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (mounted) Navigator.pop(context);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: leaving,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) leave();
        },
        child: ListenableBuilder(
          listenable: widget.state,
          builder: (context, _) {
            final s = widget.state, b = s.selected;
            if (b == null) return const Scaffold();
            final products = s.products
                .where((p) =>
                    p.branchId == b.id &&
                    p.active &&
                    p.name.toLowerCase().contains(query.toLowerCase()) &&
                    (category == 'Tất cả' || p.category == category))
                .toList();
            final categories = {
              'Tất cả',
              ...s.products
                  .where((p) => p.branchId == b.id && p.active)
                  .map((p) => p.category)
            };
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  onPressed: leave,
                  icon: const Icon(Icons.arrow_back),
                ),
                title: Text(b.name),
                actions: [
                  IconButton(
                    tooltip: 'Giỏ hàng',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => CartPage(state: s)),
                    ),
                    icon: Badge(
                      label: Text(
                        '${s.cart.values.fold(0, (a, b) => a + b)}',
                      ),
                      child: const Icon(Icons.shopping_bag_outlined),
                    ),
                  )
                ],
              ),
              bottomNavigationBar: s.cart.isEmpty
                  ? null
                  : SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                        child: FilledButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => CartPage(state: s)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Xem giỏ · ${s.cart.values.fold<int>(0, (a, b) => a + b)} món',
                              ),
                              Text(money(s.subtotal))
                            ],
                          ),
                        ),
                      ),
                    ),
              body: SyncStatus(
                state: s,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: forest,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: ProductImage(
                                      path: b.image,
                                      width: 76,
                                      height: 86,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          b.brand ?? 'Tiệm gần nhà',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 20,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          b.address,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Mở cửa · Giao trong 10 km',
                                          style: TextStyle(
                                            color: Color(0xFFCCE2BB),
                                            fontSize: 11,
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              decoration: const InputDecoration(
                                hintText: 'Tìm sản phẩm',
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: (v) => setState(() => query = v),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: categories
                                  .map((c) => ChoiceChip(
                                        label: Text(c),
                                        selected: category == c,
                                        onSelected: (_) =>
                                            setState(() => category = c),
                                      ))
                                  .toList(),
                            )
                          ],
                        ),
                      ),
                    ),
                    if (products.isEmpty)
                      SliverToBoxAdapter(
                        child: empty('Không tìm thấy sản phẩm'),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid.builder(
                        itemCount: products.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 260,
                          mainAxisExtent: 310,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (c, i) {
                          final p = products[i];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (c) => SafeArea(
                                        child: ListenableBuilder(
                                          listenable: s,
                                          builder: (c, _) => Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                ProductImage(
                                                  path: p.asset,
                                                  height: 180,
                                                ),
                                                heading(p.name,
                                                    '${p.category} • Còn ${p.stock}'),
                                                Text(
                                                  money(p.price),
                                                ),
                                                FilledButton(
                                                  onPressed:
                                                      (s.cart[p.id] ?? 0) <
                                                              p.stock
                                                          ? () => s.change(p, 1)
                                                          : null,
                                                  child: Text(
                                                    'Thêm vào giỏ (${s.cart[p.id] ?? 0})',
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      )),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ProductImage(
                                    path: p.asset,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Còn ${p.stock}',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                money(p.price),
                                                style: const TextStyle(
                                                  color: orange,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            IconButton.filledTonal(
                                              onPressed:
                                                  (s.cart[p.id] ?? 0) < p.stock
                                                      ? () => s.change(p, 1)
                                                      : null,
                                              icon: const Icon(
                                                Icons.add,
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
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      );
}
