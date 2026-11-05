import 'dart:convert';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/screens/customer/cart_page.dart';
import 'package:cstore_mobile/screens/orders.dart';
import 'package:cstore_mobile/services/account_api.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/widgets/order_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Future<void> checkoutRoundTrip(WidgetTester t,
    {bool editRecipient = false}) async {
  if (editRecipient) {
    t.view.physicalSize = const Size(390, 680);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetViewInsets);
  }
  Map<String, dynamic>? submitted;
  final order = <String, dynamic>{
    'id': 50,
    'storeId': 9,
    'items': [
      {
        'productId': 20,
        'name': 'Sữa tươi',
        'unitPrice': 25000,
        'quantity': 1,
        'image': ''
      }
    ],
    'recipient': 'Khách hàng',
    'phone': '0901234567',
    'address': '45 Nguyễn Huệ, TP. Hồ Chí Minh',
    'latitude': 10.7736,
    'longitude': 106.7034,
    'fee': 15100,
    'status': 'PENDING',
    'createdAt': '2026-11-02T12:00:00Z',
    'customerId': 1,
    'history': [
      {'status': 'PENDING', 'at': '2026-11-02T12:00:00Z'}
    ]
  };
  final api = AccountApi(client: MockClient((r) async {
    if (r.url.path.endsWith('/customer/delivery-quote')) {
      return http.Response(
          jsonEncode({
            'storeId': 9,
            'distanceKm': 1.4,
            'durationSeconds': 180,
            'fee': 19200
          }),
          200);
    }
    if (r.method == 'POST' && r.url.path.endsWith('/customer/orders')) {
      submitted = jsonDecode(r.body) as Map<String, dynamic>;
      order['recipient'] = submitted!['recipient'];
      return http.Response.bytes(utf8.encode(jsonEncode(order)), 200);
    }
    if (r.url.path.endsWith('/customer/orders')) {
      return http.Response.bytes(utf8.encode(jsonEncode([order])), 200);
    }
    if (r.url.path.endsWith('/products')) {
      return http.Response.bytes(
          utf8.encode(jsonEncode([
            {
              'id': 20,
              'storeId': 9,
              'name': 'Sữa tươi',
              'price': 25000,
              'stock': 4,
              'image': '',
              'category': 'Đồ uống',
              'active': true
            }
          ])),
          200);
    }
    return http.Response('{}', 404);
  }));
  final state = AppState(accountApi: api)
    ..account = const Account(
        1, 'customer@test.local', 'Khách hàng', Role.customer, null)
    ..positionKnown = true
    ..location = '45 Nguyễn Huệ, TP. Hồ Chí Minh'
    ..lat = 10.7736
    ..lng = 106.7034
    ..branchList = [
      const Branch(
          9, 'Chi nhánh Nguyễn Huệ', 'Địa chỉ cửa hàng', 10.7731, 106.703)
    ]
    ..selected = const Branch(
        9, 'Chi nhánh Nguyễn Huệ', 'Địa chỉ cửa hàng', 10.7731, 106.703);
  state.products.add(Product(20, 9, 'Sữa tươi', 25000, 5, '', 'Đồ uống'));
  state.cart[20] = 1;
  await t.pumpWidget(MaterialApp(home: CheckoutPage(state: state)));
  await t.pumpAndSettle();
  expect(find.text('Đã ghim vị trí giao hàng'), findsOneWidget);
  expect(find.text('45 Nguyễn Huệ, TP. Hồ Chí Minh'), findsOneWidget);
  if (!editRecipient) {
    expect(find.byType(OrderItemRow), findsOneWidget);
  }
  if (editRecipient) {
    final recipient = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Tên người nhận');
    await t.ensureVisible(recipient);
    await t.enterText(recipient, 'Người nhận được khách chỉnh sửa');
    t.view.viewInsets = const FakeViewPadding(bottom: 320);
    await t.pumpAndSettle();
  }
  final phone = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == 'Số điện thoại');
  await t.ensureVisible(phone);
  await t.enterText(phone, '0901234567');
  if (editRecipient) {
    t.view.viewInsets = FakeViewPadding.zero;
    await t.pumpAndSettle();
    await t.drag(find.byType(SingleChildScrollView), const Offset(0, -650));
    await t.pumpAndSettle();
    state.refresh();
    await t.pumpAndSettle();
  }
  await t.tap(find.text('Xác nhận đặt hàng COD'));
  await t.pumpAndSettle();
  expect(submitted?['recipient'],
      editRecipient ? 'Người nhận được khách chỉnh sửa' : 'Khách hàng');
  expect(submitted?['pinConfirmed'], isTrue);
  expect(submitted?['latitude'], 10.7736);
  expect(submitted?['longitude'], 106.7034);
  expect(submitted?['address'], '45 Nguyễn Huệ, TP. Hồ Chí Minh');
  expect(find.byType(OrderDetail), findsOneWidget);
  expect(find.text('Vui lòng ghim điểm giao hàng trên bản đồ.'), findsNothing);
  await t.pumpWidget(const SizedBox());
  state.dispose();
}

void main() {
  testWidgets(
      'checkout reuses confirmed location and sends it without repinning',
      (t) => checkoutRoundTrip(t));

  testWidgets(
      'edited recipient survives keyboard resizing, phone entry and scrolling',
      (t) => checkoutRoundTrip(t, editRecipient: true));

  testWidgets('checkout without a confirmed pin cannot submit', (t) async {
    final state = AppState()
      ..account = const Account(
          1, 'customer@test.local', 'Khách hàng', Role.customer, null)
      ..selected = const Branch(9, 'Cửa hàng', 'Địa chỉ', 10.77, 106.7);
    state.products.add(Product(20, 9, 'Sữa tươi', 25000, 5, '', 'Đồ uống'));
    state.cart[20] = 1;
    await t.pumpWidget(MaterialApp(home: CheckoutPage(state: state)));
    await t.pumpAndSettle();
    await t.enterText(
        find.byWidgetPredicate((w) =>
            w is TextField && w.decoration?.labelText == 'Số điện thoại'),
        '0901234567');
    await t.tap(find.text('Xác nhận đặt hàng COD'));
    await t.pump();
    expect(
        find.text('Vui lòng ghim điểm giao hàng trên bản đồ.'), findsOneWidget);
    expect(state.cart, isNotEmpty);
    await t.pumpWidget(const SizedBox());
    state.dispose();
  });
}
