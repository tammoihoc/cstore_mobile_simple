import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cstore_mobile/app/app.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/services/account_api.dart';
import 'package:cstore_mobile/services/app_state.dart';

void main() {
  test('no static products or orders and no sample location on startup', () {
    final s = AppState();
    expect(s.products, isEmpty);
    expect(s.orders, isEmpty);
    expect(s.branchList, isEmpty);
    expect(s.positionKnown, isFalse);
    s.dispose();
  });
  test('Haversine distance is zero for same point and symmetric', () {
    expect(distance(10, 106, 10, 106), closeTo(0, .0001));
    expect(distance(10.7731, 106.703, 10.7795, 106.688),
        closeTo(distance(10.7795, 106.688, 10.7731, 106.703), .000001));
    expect(distance(0, 0, 1, 0), closeTo(111.195, .01));
  });
  test('product catalog comes from REST, respects selected branch and stock',
      () async {
    final api = AccountApi(
        client: MockClient((request) async => http.Response(
            jsonEncode([
              {
                'id': 20,
                'storeId': 9,
                'name': 'Server product',
                'price': 25000,
                'stock': 2,
                'image': '/api/images/file.png',
                'category': 'Drink',
                'active': true
              }
            ]),
            200)));
    final s = AppState(accountApi: api);
    const branch = Branch(9, 'Server branch', 'Address', 10.77, 106.7);
    await s.select(branch);
    expect(s.products.single.name, 'Server product');
    final p = s.products.single;
    s.change(p, 1);
    s.change(p, 1);
    s.change(p, 1);
    expect(s.cart[p.id], 2);
    await s.select(null);
    expect(s.cart, isEmpty);
    s.dispose();
  });
  testWidgets('one login form without role selector', (t) async {
    await t.pumpWidget(const CStoreApp());
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Khách hàng'), findsNothing);
  });
}
