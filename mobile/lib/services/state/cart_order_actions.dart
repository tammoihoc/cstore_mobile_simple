part of 'app_state.dart';

/// Giỏ hàng và thao tác trên đơn; backend vẫn kiểm tra giá, tồn và quyền.
/// `app` là cùng một AppState đang được giao diện lắng nghe.
class _CartOrderActions {
  _CartOrderActions(this.app);

  final AppState app;

  void change(
    Product product,
    int delta,
  ) {
    if (app.selected?.id != product.branchId || !product.active) return;
    final next = (app.cart[product.id] ?? 0) + delta;
    if (next > product.stock) return;
    if (next <= 0) {
      app.cart.remove(product.id);
    } else {
      app.cart[product.id] = next;
    }
    app.refresh();
  }

  Future<ShopOrder> checkout(
    String name,
    String phone,
    String address,
    double latitude,
    double longitude,
  ) async {
    if (app.selected == null || app.cart.isEmpty) {
      throw StateError('Giỏ hàng trống');
    }
    // Chỉ gửi mã sản phẩm và số lượng. Backend tự chốt giá và giữ tồn kho.
    final data = await app.api.request(
      '/customer/orders',
      body: {
        'storeId': app.selected!.id,
        'recipient': name,
        'phone': phone,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'pinConfirmed': true,
        'items': [
          for (final e in app.cart.entries)
            {'productId': e.key, 'quantity': e.value}
        ]
      },
    );
    final o = orderFromJson(
      data as Map<String, dynamic>,
    );
    app.cart.clear();
    await app.reload();
    return o;
  }

  Future<void> transition(
    ShopOrder order,
    OrderStatus next,
    Role role, {
    String reason = '',
    bool simulateArrival = false,
  }) async {
    final prefix = role == Role.store
        ? 'merchant'
        : role == Role.customer
            ? 'customer'
            : 'shipper';
    await app.api.request(
      '/$prefix/orders/${order.id}/${next == OrderStatus.cancelled ? 'cancel' : 'status'}',
      method: 'PUT',
      body: next == OrderStatus.cancelled
          ? null
          : {
              'status': statusToApi(next),
              'reason': reason,
              if (simulateArrival) 'simulateArrival': true
            },
    );
    await app.reload();
  }

  Future<void> pay(
    ShopOrder order,
    Role role,
  ) async {
    await app.api.request(
      '/${role == Role.store ? 'merchant' : 'shipper'}/orders/${order.id}/payment',
      method: 'PUT',
    );
    await app.reload();
  }
}
