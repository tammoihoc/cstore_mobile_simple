part of 'app_state.dart';

/// Đọc dữ liệu server, polling và quản lý sản phẩm theo chi nhánh.
/// `app` là cùng một AppState đang được giao diện lắng nghe.
class _CatalogActions {
  _CatalogActions(this.app);

  final AppState app;

  Future<void> reloadBranches() async {
    app.branchList = await app.api.branches();
    app.refresh();
  }

  Future<void> reload() async {
    if (app.account == null || app.loading) return;
    app.loading = true;
    app.error = null;
    app.refresh();
    try {
      if (app.account!.role == Role.store) {
        await app.loadProducts();
        await app.loadOrders('/merchant/orders');
      }
      if (app.account!.role == Role.customer) {
        if (app.selected != null) await app.loadProducts();
        await app.loadOrders('/customer/orders');
      }
      if (app.account!.role == Role.shipper) {
        await app.loadOrders('/shipper/orders');
        final state =
            await app.api.request('/shipper/state') as Map<String, dynamic>;
        app.online = state['online'] as bool;
        app.shipperLat = (state['latitude'] as num?)?.toDouble() ?? 0;
        app.shipperLng = (state['longitude'] as num?)?.toDouble() ?? 0;
        app.shipperSimulated = state['simulated'] == true;
        app._offers
          ..clear()
          ..addAll(
            [
              for (final j in await app.api.request('/shipper/offers') as List)
                orderFromJson(
                  j as Map<String, dynamic>,
                )
            ],
          );
      }
    } catch (e) {
      app.error = e is StateError
          ? e.message
          : 'Không kết nối được máy chủ. Kéo xuống hoặc nhấn thử lại.';
    } finally {
      app.loading = false;
      app.refresh();
    }
  }

  Future<void> loadOrders(String path) async {
    final loaded = [
      for (final j in await app.api.request(path) as List)
        orderFromJson(
          j as Map<String, dynamic>,
        )
    ];
    app.orders
      ..clear()
      ..addAll(loaded);
  }

  Future<void> loadProducts() async {
    // Mỗi lần tải có số thứ tự. Chỉ kết quả mới nhất được ghi vào products.
    final revision = ++app._productsRevision;
    final path = app.account?.role == Role.store
        ? '/merchant/products'
        : '/products?storeId=${app.selected!.id}';
    final loaded = [
      for (final j in await app.api.request(path) as List)
        productFromJson(
          j as Map<String, dynamic>,
        )
    ];
    if (revision != app._productsRevision) return;
    app.products
      ..clear()
      ..addAll(loaded);
    // Tồn kho server có thể đã đổi; bỏ hoặc giảm số lượng giỏ không còn hợp lệ.
    for (final id in app.cart.keys.toList()) {
      final p = app.products.where((p) => p.id == id).firstOrNull;
      if (p == null || !p.active || p.stock == 0) {
        app.cart.remove(id);
      } else if (app.cart[id]! > p.stock) {
        app.cart[id] = p.stock;
      }
    }
  }

  Future<void> select(Branch? branch) async {
    app.cart.clear();
    app.selected = branch;
    app.products.clear();
    app.refresh();
    if (branch != null) {
      try {
        await app.loadProducts();
        app.error = null;
      } catch (e) {
        app.error = 'Không tải được sản phẩm. Vui lòng thử lại.';
      }
      app.refresh();
    }
  }

  Future<Product> saveProduct(
    Product? product,
    String name,
    int price,
    int stock,
    String category,
  ) async {
    final data = await app.api.request(
      '/merchant/products${product == null ? '' : '/${product.id}'}',
      method: product == null ? 'POST' : 'PUT',
      body: {
        'name': name,
        'price': price,
        'stock': stock,
        'category': category
      },
    );
    final saved = productFromJson(
      data as Map<String, dynamic>,
    );
    await app.reload();
    return saved;
  }

  Future<void> removeProduct(Product product) async {
    await app.api.request(
      '/merchant/products/${product.id}',
      method: 'DELETE',
    );
    await app.reload();
  }

  Future<void> uploadImage(
    Product product,
    List<int> bytes,
    String name,
  ) async {
    await app.api.uploadImage(
      product.id,
      bytes,
      name,
    );
    // An existing periodic reload must not swallow the refresh after upload.
    // Tải ảnh mới trực tiếp, kể cả khi polling cũ vẫn còn chạy.
    await app.loadProducts();
    app.refresh();
  }
}
