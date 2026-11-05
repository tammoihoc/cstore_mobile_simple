import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cstore_mobile/services/account_api.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/app/app.dart';
import 'package:cstore_mobile/screens/admin/admin_home.dart';
import 'package:cstore_mobile/screens/customer/customer_home.dart';
import 'package:cstore_mobile/screens/store/store_home.dart';
import 'package:cstore_mobile/screens/shipper/shipper_home.dart';
import 'package:cstore_mobile/screens/location_picker.dart';

void main() {
  for (final entry in {
    'CUSTOMER': CustomerHome,
    'STORE': StoreHome,
    'SHIPPER': ShipperHome,
    'ADMIN': AdminHome
  }.entries) {
    testWidgets('server role ${entry.key} controls routing and logout',
        (t) async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          final body = jsonDecode(request.body);
          expect(body['email'], 'user@test.local');
          expect(body.containsKey('role'), isFalse);
          return http.Response(
              jsonEncode({
                'token': 'test-token',
                'user': {
                  'id': 1,
                  'email': 'user@test.local',
                  'name': 'Test',
                  'role': entry.key,
                  'storeId': entry.key == 'STORE' ? 1 : null
                }
              }),
              200);
        }
        if (request.url.path.endsWith('/branches')) {
          return http.Response(
              jsonEncode([
                {
                  'id': 1,
                  'name': 'Branch',
                  'address': 'Address',
                  'latitude': 10.7731,
                  'longitude': 106.703,
                  'brand': 'C-Store'
                }
              ]),
              200);
        }
        return http.Response('[]', 200);
      });
      final s = AppState(accountApi: AccountApi(client: client));
      await t.pumpWidget(CStoreApp(state: s));
      await t.enterText(find.byType(TextFormField).at(0), 'user@test.local');
      await t.enterText(find.byType(TextFormField).at(1), 'password123');
      await t.ensureVisible(find.text('Đăng nhập'));
      await t.tap(find.text('Đăng nhập'));
      await t.pumpAndSettle();
      expect(find.byType(entry.value), findsOneWidget);
      await t.tap(find.byIcon(Icons.logout));
      await t.pumpAndSettle();
      expect(s.account, isNull);
      expect(s.api.token, isNull);
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
  testWidgets('map requires an explicit pin before confirm', (t) async {
    await t.pumpWidget(const MaterialApp(
        home: LocationPicker(title: 'Ghim vị trí', lat: 10.77, lng: 106.7)));
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    // No pin yet → button disabled, instruction visible.
    expect(t.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    expect(
        find.text('Chạm vào bản đồ để ghim vị trí chính xác'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
  test('failed login never creates a local session', () async {
    final s = AppState(
        accountApi: AccountApi(
            client: MockClient((_) async => http.Response('', 401))));
    await expectLater(s.login('bad@test.local', 'bad'), throwsStateError);
    expect(s.account, isNull);
    expect(s.api.token, isNull);
    s.dispose();
  });
}
