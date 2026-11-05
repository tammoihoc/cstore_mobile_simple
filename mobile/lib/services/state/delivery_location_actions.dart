part of 'app_state.dart';

/// Lưu điểm giao, kiểm tra tọa độ và đọc báo giá đường bộ.
/// `app` là cùng một AppState đang được giao diện lắng nghe.
class _DeliveryLocationActions {
  _DeliveryLocationActions(this.app);

  final AppState app;

  Future<void> setLocation(
    String address,
    double latitude,
    double longitude,
  ) async {
    if (!app.validCoordinates(
      latitude,
      longitude,
    )) {
      throw StateError('Tọa độ không hợp lệ');
    }
    if (address.trim().isEmpty) throw StateError('Nhập địa chỉ giao hàng');
    if (app.account?.role == Role.customer) {
      await app.api.request(
        '/customer/location',
        method: 'PUT',
        body: {
          'address': address.trim(),
          'latitude': latitude,
          'longitude': longitude,
          'pinConfirmed': true,
        },
      );
    }
    app._applyLocation(
      address.trim(),
      latitude,
      longitude,
    );
    app.refresh();
    await app.loadNearby();
  }

  Future<void> loadNearby() async {
    if (app.account?.role != Role.customer || !app.positionKnown) return;
    // Khi đổi ghim liên tiếp, chỉ giữ khoảng cách của ghim được chọn sau cùng.
    final revision = ++app._nearbyRevision;
    app.nearbyLoading = true;
    app.nearbyError = null;
    app.nearbyQuotes.clear();
    app.refresh();
    try {
      final data = await app.api.request(
        '/customer/nearby?latitude=${app.lat}&longitude=${app.lng}',
      ) as List;
      final loaded = [
        for (final item in data)
          DeliveryQuote.fromJson(
            item as Map<String, dynamic>,
          )
      ];
      if (revision != app._nearbyRevision) return;
      app.nearbyQuotes.addEntries(loaded.map((q) => MapEntry(
            q.storeId,
            q,
          )));
    } catch (e) {
      if (revision != app._nearbyRevision) return;
      app.nearbyError = e is StateError
          ? e.message
          : 'Chưa tải được khoảng cách đường đi. Vui lòng thử lại.';
    } finally {
      if (revision == app._nearbyRevision) {
        app.nearbyLoading = false;
        app.refresh();
      }
    }
  }

  Future<DeliveryQuote> quoteDelivery(
    Branch store,
    double latitude,
    double longitude,
  ) async {
    if (!app.validCoordinates(
      latitude,
      longitude,
    )) {
      throw StateError('Tọa độ không hợp lệ');
    }
    final data = await app.api.request(
      '/customer/delivery-quote',
      body: {
        'storeId': store.id,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return DeliveryQuote.fromJson(
      data as Map<String, dynamic>,
    );
  }

  void _applyLocation(
    String address,
    double latitude,
    double longitude,
  ) {
    app.location = address;
    app.lat = latitude;
    app.lng = longitude;
    app.positionKnown = true;
  }

  bool validCoordinates(
    double latitude,
    double longitude,
  ) =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}
