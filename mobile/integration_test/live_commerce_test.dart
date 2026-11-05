import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cstore_mobile/app/app.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/screens/store/store_home.dart';
import 'package:cstore_mobile/screens/customer/customer_home.dart';
import 'package:cstore_mobile/screens/customer/shop_page.dart';
import 'package:cstore_mobile/screens/shipper/shipper_home.dart';
import 'package:cstore_mobile/screens/shipper/navigation_route.dart';
import 'package:cstore_mobile/screens/orders.dart';
import 'package:cstore_mobile/models/models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'road quote, saved GPS pin and simulated shipper navigation through COD delivery',
      (t) async {
    // Programmatic text input uses one backend; a live Android IME can resend
    // its earlier editing value after tester.enterText injects a replacement.
    t.testTextInput.register();
    addTearDown(t.testTextInput.unregister);
    final state = AppState();
    final name = 'QA Android ${DateTime.now().microsecondsSinceEpoch}';
    const storeEmail = String.fromEnvironment('QA_STORE_EMAIL'),
        storePassword = String.fromEnvironment('QA_STORE_PASSWORD'),
        customerEmail = String.fromEnvironment('QA_CUSTOMER_EMAIL'),
        customerPassword = String.fromEnvironment('QA_CUSTOMER_PASSWORD'),
        shipperEmail = String.fromEnvironment('QA_SHIPPER_EMAIL'),
        shipperPassword = String.fromEnvironment('QA_SHIPPER_PASSWORD');
    const branchId = int.fromEnvironment('QA_BRANCH_ID');
    Finder input(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label);
    Future<void> waitFor(Finder f, {int ticks = 150}) async {
      for (var i = 0; i < ticks; i++) {
        await t.pump(const Duration(milliseconds: 300));
        if (f.evaluate().isNotEmpty) return;
      }
      fail('Timeout waiting for expected screen/result');
    }

    Future<void> waitUntil(bool Function() ready, String description,
        {int ticks = 150}) async {
      for (var i = 0; i < ticks; i++) {
        await t.pump(const Duration(milliseconds: 300));
        if (ready()) return;
      }
      fail('Timeout waiting for $description');
    }

    Finder action(String label) => find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));

    Future<void> reveal(Finder finder) async {
      if (finder.evaluate().isEmpty) {
        final scrollable = find.byType(Scrollable).last;
        final scroll = t.state<ScrollableState>(scrollable);
        scroll.position.jumpTo(scroll.position.minScrollExtent);
        await t.pump();
        if (finder.evaluate().isEmpty) {
          await t.scrollUntilVisible(finder, 200, scrollable: scrollable);
        }
      }
      await t.ensureVisible(finder);
      await t.pump(const Duration(milliseconds: 200));
    }

    Future<void> clickAction(String label) async {
      final button = action(label);
      await reveal(button);
      await waitUntil(
          () => button.evaluate().any((element) =>
              (element.widget as ButtonStyleButton).onPressed != null),
          'enabled action $label');
      await t.ensureVisible(button);
      await t.tap(button);
      await t.pump();
    }

    Future<void> screenshot(String marker) async {
      await t.pumpAndSettle();
      debugPrint(marker);
      await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    }

    Future<void> returnToLogin() async {
      Navigator.of(t.element(find.byType(OrderDetail)))
          .popUntil((route) => route.isFirst);
      await t.pumpAndSettle();
      state.logout();
      await t.pumpAndSettle();
      await waitFor(input('Email'));
    }

    Future<void> enter(String label, String value) async {
      final f = input(label);
      await reveal(f);
      await t.showKeyboard(f);
      await t.pumpAndSettle();
      await t.enterText(f, value);
      await t.pumpAndSettle();
    }

    Future<void> hide() async {
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      await t.pump(const Duration(milliseconds: 350));
    }

    Future<void> login(String email, String password) async {
      await enter('Email', email);
      await enter('Mật khẩu', password);
      await hide();
      await reveal(find.text('Đăng nhập'));
      await t.tap(find.text('Đăng nhập'));
      await waitUntil(() => state.timer != null && !state.loading,
          'authenticated session loaded');
    }

    await t.pumpWidget(CStoreApp(state: state));
    await t.pumpAndSettle();
    await login(storeEmail, storePassword);
    await waitFor(find.byType(StoreHome));
    await t.tap(find.text('Sản phẩm'));
    await t.pumpAndSettle();
    await t.tap(find.text('Thêm sản phẩm'));
    await t.pumpAndSettle();
    debugPrint('QA_NATIVE_GALLERY_READY');
    await t.tap(find.text('Thư viện ảnh'));
    await t.pump();
    await waitFor(find.textContaining('Đã chọn:'), ticks: 220);
    await enter('Tên sản phẩm', name);
    await enter('Giá (đ)', '27000');
    await enter('Tồn kho khả dụng', '5');
    await enter('Danh mục', 'QA Android');
    await hide();
    await reveal(find.text('Lưu sản phẩm'));
    await t.tap(find.text('Lưu sản phẩm'));
    await waitFor(find.byType(StoreHome));
    await waitFor(find.text(name));
    final uploaded = state.products.singleWhere((p) => p.name == name);
    expect(uploaded.asset, startsWith('/api/images/'));
    final response = await state.api.client
        .get(Uri.parse(state.api.imageUrl(uploaded.asset)));
    expect(response.statusCode, 200);
    expect(response.bodyBytes.length, greaterThan(100));
    state.logout();
    await t.pumpAndSettle();
    await login(customerEmail, customerPassword);
    await waitFor(find.byType(CustomerHome));
    await t.tap(find.text(state.location));
    await t.pumpAndSettle();
    debugPrint('QA_GPS_READY');
    await t.tap(find.byTooltip('Lấy vị trí GPS'));
    await waitFor(find.textContaining('Vị trí Android •'));
    await enter('Địa chỉ giao hàng', '45 Nguyen Hue - Android GPS');
    final addressController =
        t.widget<TextField>(input('Địa chỉ giao hàng')).controller!;
    expect(addressController.text, '45 Nguyen Hue - Android GPS',
        reason: 'Manual address applied through the input channel');
    await hide();
    expect(addressController.text, '45 Nguyen Hue - Android GPS',
        reason: 'Manual address retained after hiding text input');
    await reveal(find.text('Xác nhận vị trí đã ghim'));
    expect(addressController.text, '45 Nguyen Hue - Android GPS',
        reason: 'Manual address retained before confirming the pin');
    await t.tap(find.text('Xác nhận vị trí đã ghim'));
    await waitFor(find.byType(CustomerHome));
    await t.pumpAndSettle();
    await waitUntil(() => state.location == '45 Nguyen Hue - Android GPS',
        'confirmed manual address saved to the customer account');
    expect(state.location, '45 Nguyen Hue - Android GPS');
    expect(state.positionKnown, isTrue);
    expect(state.lat, closeTo(10.7736, .0001));
    expect(state.lng, closeTo(106.7034, .0001));
    await waitUntil(() => state.nearby.any((b) => b.id == branchId),
        'nearby branch with a road route');
    final branch = state.nearby.singleWhere((b) => b.id == branchId);
    final quote = await state.api.request('/customer/delivery-quote', body: {
      'storeId': branchId,
      'latitude': state.lat,
      'longitude': state.lng,
    }) as Map<String, dynamic>;
    expect(quote['distanceKm'], greaterThan(0));
    expect(quote['route']['coordinates'], isNotEmpty);
    await reveal(find.text(branch.name));
    await t.tap(find.text(branch.name));
    await waitFor(find.byType(ShopPage));
    await waitFor(find.text(name));
    final product = state.products.singleWhere((p) => p.name == name);
    state.change(product, 1);
    await t.pump();
    await t.tap(find.byTooltip('Giỏ hàng'));
    await t.pumpAndSettle();
    await t.tap(find.text('Tiếp tục đặt hàng'));
    await t.pumpAndSettle();
    await waitUntil(
        () => action('Xác nhận đặt hàng COD').evaluate().any((element) =>
            (element.widget as ButtonStyleButton).onPressed != null),
        'road quote loaded before editing checkout fields');
    await t.pumpAndSettle();
    await enter('Tên người nhận', 'Khach QA Android');
    expect(t.widget<TextField>(input('Tên người nhận')).controller!.text,
        'Khach QA Android');
    final recipientController =
        t.widget<TextField>(input('Tên người nhận')).controller!;
    await enter('Số điện thoại', '0901234567');
    expect(recipientController.text, 'Khach QA Android',
        reason: 'Recipient retained after entering phone');
    await hide();
    expect(recipientController.text, 'Khach QA Android',
        reason: 'Recipient retained after hiding keyboard');
    await reveal(find.text('Đã ghim vị trí giao hàng'));
    expect(state.location, '45 Nguyen Hue - Android GPS');
    await reveal(find.text(name));
    await screenshot('QA_SCREENSHOT_CHECKOUT');
    expect(recipientController.text, 'Khach QA Android',
        reason: 'Recipient retained after scrolling to items');
    await clickAction('Xác nhận đặt hàng COD');
    await waitFor(find.byType(OrderDetail));
    final order = state.customerOrders.singleWhere(
        (o) => o.lines.any((line) => line.productId == uploaded.id));
    expect(order.recipient, 'Khach QA Android');
    expect(order.lines.any((l) => l.productId == uploaded.id), isTrue);
    expect(order.lines.singleWhere((l) => l.productId == uploaded.id).image,
        uploaded.asset);
    expect(order.total, greaterThanOrEqualTo(42000));
    final customerSnapshot =
        (await state.api.request('/customer/orders') as List)
            .singleWhere((o) => o['id'] == order.id) as Map<String, dynamic>;
    expect(customerSnapshot['distanceSource'], 'ROAD');
    expect(customerSnapshot['distanceKm'],
        closeTo(quote['distanceKm'] as num, .001));
    expect(customerSnapshot['fee'], quote['fee']);
    expect(customerSnapshot['durationSeconds'], quote['durationSeconds']);
    await reveal(find.text(name));
    await screenshot('QA_SCREENSHOT_ORDER');

    await returnToLogin();
    await login(storeEmail, storePassword);
    await waitFor(find.byType(StoreHome));
    await waitUntil(
        () => !state.loading && state.storeOrders.any((o) => o.id == order.id),
        'customer order in store account');
    await t.tap(find.text('Đơn hàng'));
    await t.pump();
    await reveal(find.text('#CS${order.id}'));
    await t.tap(find.text('#CS${order.id}'));
    await waitFor(find.byType(OrderDetail));
    await clickAction('Chấp nhận đơn');
    await waitUntil(
        () => state.storeOrders
            .any((o) => o.id == order.id && o.status == OrderStatus.accepted),
        'store acceptance persisted');
    expect(
        state.storeOrders
            .singleWhere((o) => o.id == order.id)
            .lines
            .singleWhere((line) => line.productId == uploaded.id)
            .image,
        uploaded.asset);
    await reveal(find.text(name));
    await screenshot('QA_SCREENSHOT_STORE');

    await returnToLogin();
    await login(shipperEmail, shipperPassword);
    await waitFor(find.byType(ShipperHome));
    await clickAction('Cập nhật GPS Android');
    await waitUntil(
        () =>
            (state.shipperLat - 10.7736).abs() < .0001 &&
            (state.shipperLng - 106.7034).abs() < .0001 &&
            !state.loading,
        'shipper starts navigation at Android GPS position');
    await waitUntil(
        () => !state.loading && state.offers.any((o) => o.id == order.id),
        'accepted order offered to online shipper');
    expect(state.online, isTrue);
    await reveal(find.text('#CS${order.id}'));
    await t.tap(find.text('#CS${order.id}'));
    await waitFor(find.byType(OrderDetail));
    await clickAction('Nhận giao đơn này');
    await waitUntil(
        () => state.deliveries.any((o) =>
            o.id == order.id &&
            o.status == OrderStatus.assigned &&
            o.shipperId == state.shipperId),
        'shipper claim persisted');
    await clickAction('Mở bản đồ giao hàng');
    await waitFor(find.byType(ShipperNavigationPage));
    await waitFor(find.byKey(const ValueKey('navigation-route-ready')));
    await waitFor(find.text('Đến cửa hàng nhận hàng'));
    await t.pumpAndSettle();
    final mapController =
        t.widget<FlutterMap>(find.byType(FlutterMap)).mapController!;
    final originalZoom = mapController.camera.zoom;
    await t.tap(find.byTooltip('Phóng to'));
    await t.pumpAndSettle();
    expect(mapController.camera.zoom, greaterThan(originalZoom));
    await t.tap(find.byTooltip('Thu nhỏ'));
    await t.pumpAndSettle();
    expect(mapController.camera.zoom, closeTo(originalZoom, .01));
    await t.tap(find.byTooltip('Xem toàn bộ tuyến'));
    await t.pumpAndSettle();
    final pickupRoute = await state.api
        .request('/shipper/orders/${order.id}/route') as Map<String, dynamic>;
    expect(pickupRoute['stage'], 'PICKUP');
    expect(pickupRoute['activeRoute'], pickupRoute['pickupRoute']);
    expect(pickupRoute['activeRoute']['coordinates'], isNotEmpty);
    await screenshot('QA_SCREENSHOT_SHIPPER_PICKUP_MAP');
    await clickAction('Mô phỏng đã tới cửa hàng và nhận hàng');
    await waitFor(find.text('Mô phỏng nhận hàng tại cửa hàng?'));
    await clickAction('Xác nhận mô phỏng');
    await waitUntil(
        () => state.deliveries
            .any((o) => o.id == order.id && o.status == OrderStatus.pickedUp),
        'simulated pickup persisted');
    await waitFor(find.text('Giao hàng đến khách'));
    await waitFor(find.byKey(const ValueKey('navigation-route-ready')));
    final driverAtStore =
        await state.api.request('/shipper/state') as Map<String, dynamic>;
    expect(driverAtStore['simulated'], isTrue);
    expect(driverAtStore['latitude'], closeTo(branch.lat, .000001));
    expect(driverAtStore['longitude'], closeTo(branch.lng, .000001));
    final deliveryRoute = await state.api
        .request('/shipper/orders/${order.id}/route') as Map<String, dynamic>;
    expect(deliveryRoute['stage'], 'DELIVERY');
    expect(deliveryRoute['simulated'], isTrue);
    expect(deliveryRoute['activeRoute'], deliveryRoute['deliveryRoute']);
    expect(deliveryRoute['activeRoute']['coordinates'], isNotEmpty);
    await screenshot('QA_SCREENSHOT_SHIPPER_DELIVERY_MAP');
    await t.pageBack();
    await t.pumpAndSettle();
    await waitFor(find.byType(OrderDetail));
    await clickAction('Bắt đầu giao');
    await waitUntil(
        () => state.deliveries
            .any((o) => o.id == order.id && o.status == OrderStatus.delivering),
        'delivery started');
    await clickAction('Xác nhận đã nhận tiền');
    await waitFor(find.text('Đã thực nhận đủ tiền?'));
    await clickAction('Đã nhận đủ');
    await waitUntil(
        () => state.deliveries.any((o) => o.id == order.id && o.paid),
        'COD payment persisted');
    await clickAction('Xác nhận đã giao');
    await waitUntil(
        () => state.deliveries.any((o) =>
            o.id == order.id && o.status == OrderStatus.delivered && o.paid),
        'delivery completed and paid');
    final delivered = state.deliveries.singleWhere((o) => o.id == order.id);
    expect(
        delivered.history.map((h) => h.status),
        containsAllInOrder([
          OrderStatus.pending,
          OrderStatus.accepted,
          OrderStatus.assigned,
          OrderStatus.pickedUp,
          OrderStatus.delivering,
          OrderStatus.delivered
        ]));
    expect(
        delivered.lines
            .singleWhere((line) => line.productId == uploaded.id)
            .image,
        uploaded.asset);
    final saved = (await state.api.request('/shipper/orders') as List)
        .singleWhere((o) => o['id'] == order.id) as Map<String, dynamic>;
    expect(saved['status'], 'DELIVERED');
    expect(saved['paidAt'], isNotNull);
    expect(saved['distanceSource'], 'ROAD');
    await reveal(find.text(name));
    await screenshot('QA_SCREENSHOT_SHIPPER_DONE');
    final portrait = state.account!.avatar;
    await returnToLogin();
    await login(customerEmail, customerPassword);
    await t.tap(find.text('Đơn hàng'));
    await t.pumpAndSettle();
    await reveal(find.text('#CS${order.id}'));
    await t.tap(find.text('#CS${order.id}'));
    await waitFor(find.byType(OrderDetail));
    await reveal(find.text('Người giao hàng của bạn'));
    final customerDelivered =
        state.customerOrders.singleWhere((o) => o.id == order.id);
    expect(customerDelivered.shipperAvatar, portrait);
    expect(customerDelivered.shipperPhone, isNotEmpty);
    await screenshot('QA_SCREENSHOT_CUSTOMER_COURIER_PHOTO');
    debugPrint(
        'QA_LIVE_COMMERCE_PASS product=${uploaded.id} order=${order.id} status=DELIVERED paid=true road=OSRM simulatedPickup=true');
  });
}
