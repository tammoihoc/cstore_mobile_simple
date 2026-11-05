part of 'app_state.dart';

/// Nhận đơn và cập nhật trực tuyến/vị trí của người giao hàng.
/// `app` là cùng một AppState đang được giao diện lắng nghe.
class _ShipperActions {
  _ShipperActions(this.app);

  final AppState app;

  Future<void> claim(ShopOrder order) async {
    if (app.account?.photoRequired == true) {
      throw StateError('Thêm ảnh đại diện trong Hồ sơ trước khi nhận đơn mới.');
    }
    await app.api.request(
      '/shipper/orders/${order.id}/claim',
      method: 'POST',
    );
    await app.reload();
  }

  Future<void> setShipperPosition(
    bool ready,
    double latitude,
    double longitude, {
    bool preserveSimulation = false,
  }) async {
    if (ready && app.account?.photoRequired == true) {
      throw StateError(
        'Thêm ảnh đại diện trong Hồ sơ trước khi bật trực tuyến.',
      );
    }
    final data = await app.api.request(
      '/shipper/location',
      method: 'PUT',
      body: {
        'online': ready,
        'latitude': latitude,
        'longitude': longitude,
        if (preserveSimulation) 'preserveSimulation': true
      },
    );
    app.online = ready;
    app.shipperLat = latitude;
    app.shipperLng = longitude;
    app.shipperSimulated = data is Map && data['simulated'] == true;
    await app.reload();
  }
}
