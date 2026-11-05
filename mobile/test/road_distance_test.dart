import 'dart:async';
import 'dart:convert';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/screens/customer/cart_page.dart';
import 'package:cstore_mobile/screens/location_picker.dart';
import 'package:cstore_mobile/services/account_api.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

AppState customer(http.Client client) =>
    AppState(accountApi: AccountApi(client: client))
      ..account =
          const Account(1, 'road@test.local', 'Khách', Role.customer, null)
      ..positionKnown = true
      ..location = 'Điểm giao đã lưu'
      ..lat = 10.7736
      ..lng = 106.7034
      ..branchList = const [
        Branch(1, 'Gần theo tọa độ', 'Address', 10.77361, 106.70341),
        Branch(2, 'Gần theo đường đi', 'Address', 10.774, 106.704),
      ];

void main() {
  test('stores are sorted by road distance returned by the server', () async {
    final state = customer(MockClient((_) async => http.Response(
        jsonEncode([
          {'storeId': 1, 'distanceKm': 9, 'durationSeconds': 900, 'fee': 42000},
          {'storeId': 2, 'distanceKm': 1, 'durationSeconds': 180, 'fee': 18000},
        ]),
        200)));
    addTearDown(state.dispose);
    await state.loadNearby();
    expect(state.nearby.map((b) => b.id), [2, 1]);
    expect(state.nearbyQuotes[2]!.distanceKm, 1);
  });

  test('old routing responses cannot overwrite a newly selected location',
      () async {
    final responses = [Completer<http.Response>(), Completer<http.Response>()];
    var requests = 0;
    final state = customer(MockClient((_) => responses[requests++].future));
    addTearDown(state.dispose);
    final first = state.loadNearby();
    await Future<void>.delayed(Duration.zero);
    state.lat = 10.78;
    final second = state.loadNearby();
    await Future<void>.delayed(Duration.zero);
    responses[1].complete(http.Response(
        jsonEncode([
          {'storeId': 2, 'distanceKm': 2, 'durationSeconds': 300, 'fee': 21000}
        ]),
        200));
    await second;
    responses[0].complete(http.Response(
        jsonEncode([
          {'storeId': 1, 'distanceKm': 1, 'durationSeconds': 180, 'fee': 18000}
        ]),
        200));
    await first;
    expect(state.nearby.map((b) => b.id), [2]);
    expect(state.nearbyLoading, isFalse);
  });

  test('route service failure does not display straight line distances',
      () async {
    final state = customer(MockClient((_) async => http.Response('{}', 503)));
    addTearDown(state.dispose);
    await state.loadNearby();
    expect(state.nearby, isEmpty);
    expect(state.nearbyError, isNotNull);
    expect(state.nearbyQuotes, isEmpty);
  });

  testWidgets('checkout cannot invent a fee when road routing fails',
      (tester) async {
    final state = customer(MockClient((_) async =>
        http.Response(jsonEncode({'message': 'Routing unavailable'}), 503)))
      ..selected = const Branch(1, 'Cửa hàng', 'Address', 10.77361, 106.70341);
    state.products.add(Product(5, 1, 'Món hàng', 25000, 3, '', 'Món'));
    state.cart[5] = 1;
    await tester.pumpWidget(MaterialApp(home: CheckoutPage(state: state)));
    await tester.pumpAndSettle();
    expect(find.text('Routing unavailable'), findsOneWidget);
    final confirm = find.widgetWithText(FilledButton, 'Xác nhận đặt hàng COD');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    expect(find.text('Thử lại tuyến đường'), findsOneWidget);
    expect(find.text('Tổng thanh toán'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets('pin map zoom controls change the camera without creating a pin',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: LocationPicker(
            title: 'Ghim điểm giao', lat: 10.7736, lng: 106.7034)));
    await tester.pumpAndSettle();
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final controller = map.mapController!;
    final initial = controller.camera.zoom;
    await tester.tap(find.byTooltip('Phóng to'));
    await tester.pump();
    expect(controller.camera.zoom, initial + 1);
    await tester.tap(find.byTooltip('Thu nhỏ'));
    await tester.pump();
    expect(controller.camera.zoom, initial);
    expect(find.byIcon(Icons.location_pin), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
