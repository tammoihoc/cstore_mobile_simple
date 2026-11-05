import 'dart:convert';
import 'package:cstore_mobile/app/app.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/screens/admin/admin_home.dart';
import 'package:cstore_mobile/services/account_api.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const fixtures = [
  Branch(1, 'An Nhiên', 'Address 1', 10.77, 106.7, brand: 'An Nhiên'),
  Branch(2, 'An Nhiên · Quận 3', 'Address 2', 10.78, 106.71, brand: 'An Nhiên'),
  Branch(3, 'Mộc Mart', 'Address 3', 10.79, 106.72, brand: 'Mộc Mart'),
];
Map<String, dynamic> brandRow(String name, int count, int gross, int id) => {
      'key': name.toLowerCase(),
      'name': name,
      'image': '',
      'branchCount': count,
      'archivedBranchCount': 0,
      'completedOrders': count,
      'grossSales': gross,
      'platformRevenue': gross * .15,
      'active': true,
      'branches': [
        for (var i = 0; i < count; i++)
          {
            'storeId': id + i,
            'name': '$name · Chi nhánh ${i + 1}',
            'completedOrders': 1,
            'grossSales': gross ~/ count,
            'platformRevenue': gross / count * .15,
            'active': true
          }
      ]
    };
http.Response jsonResponse(Object data) =>
    http.Response.bytes(utf8.encode(jsonEncode(data)), 200);
AppState adminState() =>
    AppState(accountApi: AccountApi(client: MockClient((r) async {
      if (r.url.path.endsWith('/admin/accounts')) return jsonResponse([]);
      if (r.url.path.endsWith('/branches')) {
        return jsonResponse([
          for (final b in fixtures)
            {
              'id': b.id,
              'name': b.name,
              'address': b.address,
              'latitude': b.lat,
              'longitude': b.lng,
              'brand': b.brand,
              'image': b.image
            }
        ]);
      }
      if (r.url.path.endsWith('/admin/revenue')) {
        final a = brandRow('An Nhiên', 2, 150000, 1),
            b = brandRow('Mộc Mart', 1, 90000, 3);
        return jsonResponse({
          'brandCount': 2,
          'branchCount': 3,
          'grossSales': 240000,
          'platformRevenue': 36000,
          'completedOrders': 3,
          'brands': [a, b],
          'topBrand': a
        });
      }
      return http.Response('{}', 404);
    })))
      ..account =
          const Account(99, 'admin@test.local', 'Admin', Role.admin, null);

void main() {
  testWidgets(
      'admin distinguishes total brand revenue and active branch counts',
      (t) async {
    final state = adminState();
    t.view.physicalSize = const Size(390, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(CStoreApp(state: state));
    await t.pumpAndSettle();
    expect(find.text('Tổng doanh thu tất cả thương hiệu cửa hàng tiện lợi'),
        findsOneWidget);
    expect(find.text('240.000đ'), findsOneWidget);
    expect(find.text('Thương hiệu đăng ký'), findsOneWidget);
    expect(find.text('Chi nhánh hoạt động'), findsOneWidget);
    expect(find.text('Doanh số món hàng đủ điều kiện'), findsNothing);
    await t.tap(find.text('Thương hiệu'));
    await t.pumpAndSettle();
    expect(find.text('An Nhiên'), findsOneWidget);
    expect(find.text('2 chi nhánh • 2 đơn hoàn tất'), findsOneWidget);
    await t.tap(find.text('An Nhiên'));
    await t.pumpAndSettle();
    expect(find.text('Doanh thu thương hiệu'), findsOneWidget);
    expect(find.text('150.000đ'), findsOneWidget);
    expect(find.text('Danh sách chi nhánh (2)'), findsOneWidget);
    expect(find.text('An Nhiên · Chi nhánh 1'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
      'existing brand selection autofills name and requires a new branch name',
      (t) async {
    final state = AppState()..branchList = fixtures;
    await t.pumpWidget(MaterialApp(home: CreatePartner(state: state)));
    await t.pumpAndSettle();
    expect(find.text('Tạo thương hiệu'), findsOneWidget);
    await t.tap(find.byType(DropdownButtonFormField<String>));
    await t.pumpAndSettle();
    await t.tap(find.text('Thêm chi nhánh · An Nhiên').last);
    await t.pumpAndSettle();
    final brand = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Tên thương hiệu');
    expect(t.widget<TextField>(brand).controller!.text, 'An Nhiên');
    expect(t.widget<TextField>(brand).readOnly, isTrue);
    expect(
        find.byWidgetPredicate((w) =>
            w is TextField && w.decoration?.labelText == 'Tên chi nhánh'),
        findsOneWidget);
    expect(find.text('Tạo chi nhánh và tài khoản'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets(
      'new brand mode offers only remaining active brands after a refresh',
      (t) async {
    final state = AppState()..branchList = [fixtures.last];
    await t.pumpWidget(MaterialApp(home: CreatePartner(state: state)));
    await t.pumpAndSettle();
    await t.tap(find.byType(DropdownButtonFormField<String>));
    await t.pumpAndSettle();
    expect(find.text('Thêm chi nhánh · An Nhiên'), findsNothing);
    expect(find.text('Thêm chi nhánh · Mộc Mart'), findsOneWidget);
    expect(find.text('Đang có 1 chi nhánh'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    state.dispose();
  });
}
