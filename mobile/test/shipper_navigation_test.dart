import 'dart:convert';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/screens/shipper/navigation_route.dart';
import 'package:cstore_mobile/services/account_api.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> leg(double km, List<List<double>> points) => {
      'distanceKm': km,
      'durationSeconds': km * 180,
      'coordinates': points,
      'steps': [
        {
          'name': 'Nguyễn Huệ',
          'type': 'turn',
          'modifier': 'right',
          'distanceMeters': 120,
          'durationSeconds': 30,
          'latitude': 10.7731,
          'longitude': 106.7030
        }
      ],
      'provider': 'OSRM',
      'selection': 'SHORTEST_AVAILABLE'
    };

Map<String, dynamic> navigationJson({bool pickedUp = false}) {
  final pickup = leg(.8, [
    [106.701, 10.772],
    [106.7030, 10.7731]
  ]);
  final delivery = leg(1.2, [
    [106.7030, 10.7731],
    [106.7040, 10.7741]
  ]);
  return {
    'stage': pickedUp ? 'DELIVERY' : 'PICKUP',
    'simulated': pickedUp,
    'shipperLatitude': pickedUp ? 10.7731 : 10.772,
    'shipperLongitude': pickedUp ? 106.7030 : 106.701,
    'storeLatitude': 10.7731,
    'storeLongitude': 106.7030,
    'customerLatitude': 10.7741,
    'customerLongitude': 106.7040,
    'pickupRoute': pickedUp ? null : pickup,
    'deliveryRoute': delivery,
    'activeRoute': pickedUp ? delivery : pickup
  };
}

void main() {
  test('road navigation preserves GeoJSON coordinate order, phase and turns',
      () {
    final pickup = DeliveryNavigation.fromJson(navigationJson());
    expect(pickup.toStore, isTrue);
    expect(pickup.title, 'Đến cửa hàng nhận hàng');
    expect(pickup.active.points.first.latitude, 10.772);
    expect(pickup.active.points.first.longitude, 106.701);
    expect(pickup.active.distanceLabel, '800 m');
    expect(pickup.active.steps.single.instruction, 'Rẽ phải vào Nguyễn Huệ');
    final delivery =
        DeliveryNavigation.fromJson(navigationJson(pickedUp: true));
    expect(delivery.toStore, isFalse);
    expect(delivery.title, 'Giao hàng đến khách');
    expect(delivery.simulated, isTrue);
    expect(delivery.pickup, isNull);
    expect(delivery.active.distanceKm, 1.2);
    expect(delivery.driver.latitude, delivery.store.latitude);
    expect(delivery.driver.longitude, delivery.store.longitude);
  });

  testWidgets(
      'shipper map zooms, avoids poll refetch and switches after simulated pickup',
      (tester) async {
    var pickedUp = false;
    var routeRequests = 0;
    Map<String, dynamic>? transitionBody;
    Map<String, dynamic> orderJson() => {
          'id': 7,
          'storeId': 2,
          'recipient': 'Khách',
          'phone': '0901234567',
          'address': 'Điểm giao',
          'latitude': 10.7741,
          'longitude': 106.7040,
          'fee': 18600,
          'distanceKm': 1.2,
          'durationSeconds': 216,
          'distanceSource': 'ROAD',
          'status': pickedUp ? 'PICKED_UP' : 'ASSIGNED',
          'shipperId': 1,
          'customerId': 3,
          'createdAt': '2026-11-02T12:00:00Z',
          'items': [
            {
              'productId': 5,
              'name': 'Món đã chọn',
              'unitPrice': 20000,
              'quantity': 1,
              'image': ''
            }
          ],
          'history': [
            {'status': 'ASSIGNED', 'at': '2026-11-02T12:00:00Z'}
          ]
        };
    http.Response jsonResponse(dynamic value) =>
        http.Response.bytes(utf8.encode(jsonEncode(value)), 200);
    final api = AccountApi(client: MockClient((request) async {
      if (request.url.path.endsWith('/route')) {
        routeRequests++;
        return jsonResponse(navigationJson(pickedUp: pickedUp));
      }
      if (request.url.path.endsWith('/status')) {
        transitionBody = jsonDecode(request.body) as Map<String, dynamic>;
        pickedUp = true;
        return jsonResponse(orderJson());
      }
      if (request.url.path.endsWith('/shipper/orders')) {
        return jsonResponse([orderJson()]);
      }
      if (request.url.path.endsWith('/shipper/state')) {
        return jsonResponse({
          'online': true,
          'latitude': pickedUp ? 10.7731 : 10.772,
          'longitude': pickedUp ? 106.7030 : 106.701,
          'simulated': pickedUp
        });
      }
      if (request.url.path.endsWith('/shipper/offers')) {
        return jsonResponse([]);
      }
      return jsonResponse([]);
    }));
    final state = AppState(accountApi: api)
      ..account =
          const Account(1, 'shipper@test.local', 'Tài xế', Role.shipper, null)
      ..online = true
      ..shipperLat = 10.772
      ..shipperLng = 106.701
      ..branchList = [
        const Branch(2, 'Cửa hàng', 'Điểm lấy', 10.7731, 106.7030)
      ];
    final order = orderFromJson(orderJson());
    state.orders.add(order);
    await tester.pumpWidget(
        MaterialApp(home: ShipperNavigationPage(state: state, order: order)));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('navigation-route-ready')), findsOneWidget);
    expect(find.text('Đến cửa hàng nhận hàng'), findsOneWidget);
    expect(routeRequests, 1);
    state.refresh();
    await tester.pumpAndSettle();
    expect(routeRequests, 1);
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final zoom = map.mapController!.camera.zoom;
    await tester.tap(find.byTooltip('Phóng to'));
    await tester.pumpAndSettle();
    expect(map.mapController!.camera.zoom, greaterThan(zoom));
    final simulate = find.text('Mô phỏng đã tới cửa hàng và nhận hàng');
    await tester.ensureVisible(simulate);
    await tester.tap(simulate);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận mô phỏng'));
    await tester.pumpAndSettle();
    expect(transitionBody?['status'], 'PICKED_UP');
    expect(transitionBody?['simulateArrival'], isTrue);
    expect(state.shipperSimulated, isTrue);
    expect(state.shipperLat, 10.7731);
    expect(state.shipperLng, 106.7030);
    expect(find.text('Giao hàng đến khách'), findsOneWidget);
    expect(routeRequests, 2);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets(
      'unavailable routing shows retry instead of a straight-line estimate',
      (tester) async {
    final state = AppState(
        accountApi: AccountApi(
            client: MockClient((_) async => http.Response.bytes(
                utf8.encode(jsonEncode(
                    {'message': 'Dịch vụ đường đi tạm thời không sẵn sàng'})),
                503))))
      ..account =
          const Account(1, 'shipper@test.local', 'Tài xế', Role.shipper, null)
      ..shipperLat = 10.772
      ..shipperLng = 106.701
      ..branchList = [
        const Branch(2, 'Cửa hàng', 'Điểm lấy', 10.7731, 106.7030)
      ];
    final order = ShopOrder(
        7, 2, [], 'Khách', '0901234567', 'Điểm giao', 10.7741, 106.7040, 18000)
      ..status = OrderStatus.assigned
      ..shipperId = '1';
    state.orders.add(order);
    await tester.pumpWidget(
        MaterialApp(home: ShipperNavigationPage(state: state, order: order)));
    await tester.pumpAndSettle();
    expect(
        find.text('Dịch vụ đường đi tạm thời không sẵn sàng'), findsOneWidget);
    expect(find.text('Thử tải lại đường đi'), findsOneWidget);
    expect(find.byKey(const ValueKey('navigation-route-ready')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
