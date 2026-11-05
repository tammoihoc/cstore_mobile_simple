import 'dart:convert';
import 'dart:async';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/screens/admin/admin_home.dart';
import 'package:cstore_mobile/screens/orders.dart';
import 'package:cstore_mobile/screens/profile/profile_page.dart';
import 'package:cstore_mobile/services/account_api.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/widgets/account_avatar.dart';
import 'package:cstore_mobile/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> user(
        {String role = 'CUSTOMER',
        String avatar = '',
        String gender = 'UNSPECIFIED'}) =>
    {
      'id': 1,
      'email': 'qa@test.local',
      'name': 'Người dùng QA',
      'role': role,
      'avatar': avatar,
      'gender': gender,
      'phone': '0901234567',
      'passwordEnabled': true
    };
http.Response response(Object data) =>
    http.Response.bytes(utf8.encode(jsonEncode(data)), 200);

void main() {
  testWidgets(
      'customer defaults are chosen explicitly and shipper has no synthetic portrait',
      (t) async {
    await t.pumpWidget(const MaterialApp(
        home: Row(children: [
      AccountAvatar(role: Role.customer, gender: 'MALE'),
      AccountAvatar(role: Role.customer, gender: 'FEMALE'),
      AccountAvatar(role: Role.shipper),
      AccountAvatar(role: Role.store, path: '/api/images/logo.png')
    ])));
    await t.pumpAndSettle();
    final paths = t
        .widgetList<ProductImage>(find.byType(ProductImage))
        .map((w) => w.path)
        .toList();
    expect(paths, [
      'assets/images/avatar-default-male.png',
      'assets/images/avatar-default-female.png',
      '/api/images/logo.png'
    ]);
    expect(find.byIcon(Icons.delivery_dining_rounded), findsOneWidget);
    final logo = t.widgetList<ProductImage>(find.byType(ProductImage)).last;
    expect(logo.fit, BoxFit.cover);
  });

  test(
      'profile saves server identity and password change replaces session token',
      () async {
    var saved = user();
    final calls = <String>[];
    final api = AccountApi(client: MockClient((r) async {
      calls.add('${r.method} ${r.url.path}');
      if (r.url.path.endsWith('/password')) {
        expect(r.headers['Authorization'], 'Bearer previous-session');
        return response({'token': 'replacement-session', 'user': saved});
      }
      if (r.method == 'PUT') {
        final input = jsonDecode(r.body) as Map<String, dynamic>;
        saved = {...saved, ...input};
      }
      return response(saved);
    }))
      ..token = 'previous-session';
    final state = AppState(accountApi: api)..account = Account.fromJson(saved);
    await state.updateProfile('Tên mới', '0987654321', 'FEMALE');
    expect(state.account?.gender, 'FEMALE');
    await state.refreshProfile();
    expect(state.account?.name, 'Tên mới');
    await state.changePassword('test-current-password', 'test-new-password');
    expect(api.token, 'replacement-session');
    expect(calls, [
      'PUT /api/account/profile',
      'GET /api/account/profile',
      'PUT /api/account/password'
    ]);
    state.dispose();
  });

  test('late password response cannot restore an account after logout',
      () async {
    final completed = Completer<http.Response>();
    final api = AccountApi(client: MockClient((_) => completed.future))
      ..token = 'previous-session';
    final state = AppState(accountApi: api)..account = Account.fromJson(user());
    final changing =
        state.changePassword('test-current-password', 'test-new-password');
    await Future<void>.delayed(Duration.zero);
    state.logout();
    completed
        .complete(response({'token': 'replacement-session', 'user': user()}));
    await changing;
    expect(state.account, isNull);
    expect(api.token, isNull);
    state.dispose();
  });

  test('missing shipper photo blocks online and claim before any API call',
      () async {
    var calls = 0;
    final state = AppState(accountApi: AccountApi(client: MockClient((_) async {
      calls++;
      return response({});
    })))
      ..account = Account.fromJson(user(role: 'SHIPPER'));
    await expectLater(
        state.setShipperPosition(true, 10.77, 106.7), throwsStateError);
    await expectLater(
        state.claim(
            ShopOrder(1, 1, [], 'QA', '0901234567', 'QA', 10.77, 106.7, 15000)),
        throwsStateError);
    expect(calls, 0);
    state.dispose();
  });

  testWidgets('password confirmation must match before submitting', (t) async {
    var calls = 0;
    final state = AppState(accountApi: AccountApi(client: MockClient((_) async {
      calls++;
      return response({});
    })))
      ..account = Account.fromJson(user());
    await t.pumpWidget(MaterialApp(home: ChangePasswordPage(state: state)));
    for (var i = 0; i < 3; i++) {
      await t.enterText(
          find.byKey(ValueKey('password-$i')),
          [
            'test-current-password',
            'test-new-password',
            'test-different-password'
          ][i]);
    }
    await t.ensureVisible(find.text('Lưu mật khẩu'));
    await t.tap(find.text('Lưu mật khẩu'));
    await t.pumpAndSettle();
    expect(find.text('Mật khẩu nhập lại chưa khớp'), findsOneWidget);
    expect(calls, 0);
    await t.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets('profile default selection is saved and form fits a narrow phone',
      (t) async {
    Map<String, dynamic>? payload;
    final state = AppState(accountApi: AccountApi(client: MockClient((r) async {
      payload = jsonDecode(r.body) as Map<String, dynamic>;
      return response({...user(), ...payload!});
    })))
      ..account = Account.fromJson(user());
    t.view.physicalSize = const Size(390, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(home: EditProfilePage(state: state)));
    expect(find.text('Lựa chọn hiển thị'), findsNothing);
    expect(find.text('Avatar mặc định'), findsNothing);
    final genders = find.byType(DropdownButtonFormField<String>);
    await t.ensureVisible(genders);
    await t.tap(genders);
    await t.pumpAndSettle();
    await t.tap(find.text('Nữ').last);
    await t.pumpAndSettle();
    final dropdown = t.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>));
    expect(dropdown.initialValue, 'FEMALE');
    await t.tap(find.text('Lưu hồ sơ'));
    await t.pumpAndSettle();
    expect(payload?['gender'], 'FEMALE');
    expect(state.account?.gender, 'FEMALE');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets('customer order identifies courier by own photo and phone',
      (t) async {
    final state = AppState()..account = Account.fromJson(user());
    final order = ShopOrder(
        3, 2, [], 'Khách', '0901234567', 'Địa chỉ', 10.77, 106.7, 15000)
      ..shipperId = '7'
      ..shipperName = 'Tài xế QA'
      ..shipperPhone = '0987654321'
      ..shipperAvatar = '/api/images/portrait.png'
      ..status = OrderStatus.delivering;
    state.orders.add(order);
    await t.pumpWidget(MaterialApp(
        home: OrderDetail(state: state, order: order, role: Role.customer)));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Người giao hàng của bạn'), 200);
    expect(find.text('Tài xế QA'), findsOneWidget);
    final avatar = t.widget<AccountAvatar>(find.byType(AccountAvatar));
    expect(avatar.path, '/api/images/portrait.png');
    expect(avatar.role, Role.shipper);
    await t.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets(
      'admin account list uses branch logo and flags missing shipper portrait',
      (t) async {
    final state = AppState(accountApi: AccountApi(client: MockClient((r) async {
      if (r.url.path.endsWith('/admin/accounts')) {
        return response([
          {
            ...user(role: 'STORE'),
            'id': 2,
            'storeId': 8,
            'avatar': '/api/images/logo.png'
          },
          {...user(role: 'SHIPPER'), 'id': 3}
        ]);
      }
      if (r.url.path.endsWith('/branches')) {
        return response([
          {
            'id': 8,
            'name': 'Thương hiệu • Quận 1',
            'address': 'QA',
            'latitude': 10.77,
            'longitude': 106.7,
            'image': '/api/images/logo.png'
          }
        ]);
      }
      return response({});
    })))
      ..account =
          const Account(99, 'admin@test.local', 'Admin', Role.admin, null);
    await t.pumpWidget(MaterialApp(home: AdminHome(state: state)));
    await t.pumpAndSettle();
    await t.tap(find.text('Tài khoản'));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Thương hiệu • Quận 1'), 200,
        scrollable: find.byType(Scrollable).first);
    final avatars = t.widgetList<AccountAvatar>(find.byType(AccountAvatar));
    expect(
        avatars.any((a) =>
            a.account?.role == Role.store && a.path == '/api/images/logo.png'),
        isTrue);
    await t.scrollUntilVisible(find.text('Cần ảnh đại diện'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Cần ảnh đại diện'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    state.dispose();
  });
}
