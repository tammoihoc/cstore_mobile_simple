import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/models/store_metrics.dart';
import 'package:cstore_mobile/services/account_api.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/screens/admin/admin_home.dart';
import 'package:cstore_mobile/screens/orders.dart';
import 'package:cstore_mobile/screens/profile/profile_page.dart';
import 'package:cstore_mobile/screens/store/store_home.dart';
import 'package:cstore_mobile/widgets/account_avatar.dart';
import 'package:cstore_mobile/widgets/date_filter.dart';

http.Response json(Object data) =>
    http.Response.bytes(utf8.encode(jsonEncode(data)), 200);
ShopOrder order(int id, DateTime created,
    {DateTime? delivered,
    DateTime? paid,
    int price = 100000,
    int quantity = 1}) {
  final o = ShopOrder(id, 2, [OrderLine(9, 'Sữa', price, quantity)],
      'Người nhận', '0901234567', 'Điểm giao', 10.77, 106.7, 20000,
      createdAt: created)
    ..paidAt = paid
    ..customerId = '1';
  if (delivered != null) {
    o.status = OrderStatus.delivered;
    o.history.add(HistoryEntry(OrderStatus.delivered, time: delivered));
  }
  return o;
}

void main() {
  test(
      'date filter includes both whole local boundary days and handles unknown dates',
      () {
    final range =
        DateTimeRange(start: DateTime(2026, 11, 3), end: DateTime(2026, 11, 4));
    expect(inDateRange(DateTime(2026, 11, 3).toUtc(), range), isTrue);
    expect(inDateRange(DateTime(2026, 11, 4, 23, 59, 59, 999).toUtc(), range),
        isTrue);
    expect(inDateRange(DateTime(2026, 11, 5), range), isFalse);
    expect(inDateRange(null, range), isFalse);
    expect(inDateRange(null, null), isTrue);
  });
  test(
      'store revenue uses completion date, price snapshots and excludes delivery fee and unfinished orders',
      () {
    final day = DateTime(2026, 11, 3),
        range = DateTimeRange(
            start: DateTime(2026, 11, 3), end: DateTime(2026, 11, 3));
    final old = order(1, DateTime(2026, 11, 1), delivered: day, paid: day);
    final later = order(2, day,
        delivered: DateTime(2026, 11, 4), paid: DateTime(2026, 11, 4));
    final second =
        order(3, day, delivered: day, paid: day, price: 25000, quantity: 2);
    final pending = order(4, day);
    final unpaid = order(5, day, delivered: day);
    final cancelled = order(6, day, paid: day)..status = OrderStatus.cancelled;
    final data =
        StoreMetrics([old, later, second, pending, unpaid, cancelled], range);
    expect(data.revenue, 150000);
    expect(data.commission, 22500);
    expect(data.estimatedNet, 127500);
    expect(data.deliveryFees, 40000);
    expect(data.unpaidDelivered, 1);
    expect(data.completed.length, 2);
    expect(data.placed.length, 5);
    expect(data.placedCompleted,
        2); // Includes the later-completed order placed that day.
    expect(data.bestSellers.single.quantity, 3);
    expect(data.bestSellers.single.revenue, 150000);
    expect(data.dailyRevenue[day], 150000);
  });
  for (final role in [Role.shipper, Role.customer, Role.store]) {
    testWidgets(
        '$role can call the other delivery party without a self-call button',
        (t) async {
      final state = AppState()
        ..account = Account(
            role == Role.shipper ? 7 : 1, 'qa@test.local', 'QA', role, 2);
      final o = order(1, DateTime.now())
        ..shipperId = '7'
        ..shipperName = 'Tài xế'
        ..shipperPhone = '0987654321'
        ..status = OrderStatus.assigned;
      state.orders.add(o);
      await t.pumpWidget(
          MaterialApp(home: OrderDetail(state: state, order: o, role: role)));
      await t.pumpAndSettle();
      expect(find.byTooltip('Gọi người nhận'),
          role == Role.customer ? findsNothing : findsOneWidget);
      expect(find.byTooltip('Gọi shipper'),
          role == Role.shipper ? findsNothing : findsOneWidget);
      await t.pumpWidget(const SizedBox());
      state.dispose();
    });
  }
  testWidgets(
      'history combines status and date filters, and canceling custom dates preserves selection',
      (t) async {
    final state = AppState()
      ..account = const Account(1, 'qa@test.local', 'QA', Role.customer, null);
    state.orders.addAll([
      order(81, DateTime.now()),
      order(82, DateTime.now().subtract(const Duration(days: 2)))
    ]);
    await t.pumpWidget(MaterialApp(
        home: Scaffold(body: OrderList(state: state, role: Role.customer))));
    await t.pumpAndSettle();
    final dropdown = find.descendant(
        of: find.byType(DateFilterBar),
        matching: find.byType(DropdownButton<String>));
    await t.tap(dropdown);
    await t.pumpAndSettle();
    await t.tap(find.text('Hôm nay').last);
    await t.pumpAndSettle();
    expect(find.text('#CS81'), findsOneWidget);
    expect(find.text('#CS82'), findsNothing);
    await t.tap(dropdown);
    await t.pumpAndSettle();
    await t.tap(find.text('Chọn khoảng ngày').last);
    await t.pumpAndSettle();
    Navigator.of(t.element(find.byType(DateRangePickerDialog))).pop();
    await t.pumpAndSettle();
    expect(t.widget<DropdownButton<String>>(dropdown).value, 'Hôm nay');
    await t.tap(find.text('Hoàn tất'));
    await t.pumpAndSettle();
    expect(find.text('#CS81'), findsNothing);
    await t.tap(find.text('Tất cả'));
    await t.pumpAndSettle();
    await t.tap(find.text('Bỏ lọc ngày'));
    await t.pumpAndSettle();
    expect(find.text('#CS82'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    state.dispose();
  });
  testWidgets(
      'gender keeps a personal photo until explicitly deleted and compact profile has no extra phone tile',
      (t) async {
    var saved = <String, dynamic>{
      'id': 1,
      'name': 'QA',
      'email': 'qa@test.local',
      'role': 'CUSTOMER',
      'gender': 'MALE',
      'avatar': '/api/images/own.png',
      'phone': '0901234567'
    };
    final state = AppState(accountApi: AccountApi(client: MockClient((r) async {
      if (r.method == 'DELETE') saved = {...saved, 'avatar': ''};
      if (r.method == 'PUT') {
        saved = {...saved, ...jsonDecode(r.body) as Map<String, dynamic>};
      }
      return json(saved);
    })))
      ..account = Account.fromJson(saved);
    await t.pumpWidget(MaterialApp(home: EditProfilePage(state: state)));
    await t.pumpAndSettle();
    expect(find.text('Avatar mặc định'), findsNothing);
    expect(find.text('Lựa chọn hiển thị'), findsNothing);
    final genders = find.byType(DropdownButtonFormField<String>);
    await t.ensureVisible(genders);
    await t.tap(genders);
    await t.pumpAndSettle();
    await t.tap(find.text('Nữ').last);
    await t.pumpAndSettle();
    expect(state.account!.avatar, '/api/images/own.png');
    expect(t.widget<AccountAvatar>(find.byType(AccountAvatar)).account!.avatar,
        '/api/images/own.png');
    await t.ensureVisible(find.text('Xóa ảnh đại diện'));
    await t.tap(find.text('Xóa ảnh đại diện'));
    await t.pumpAndSettle();
    expect(state.account!.avatar, '');
    expect(
        t.widget<AccountAvatar>(find.byType(AccountAvatar)).gender, 'FEMALE');
    await t.tap(find.text('Lưu hồ sơ'));
    await t.pumpAndSettle();
    expect(saved['gender'], 'FEMALE');
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(MaterialApp(home: ProfilePage(state: state)));
    await t.pumpAndSettle();
    expect(find.text('Số điện thoại'), findsNothing);
    await t.pumpWidget(const SizedBox());
    state.dispose();
  });
  testWidgets(
      'admin filters account type with creation date while unknown dates stay honest',
      (t) async {
    final now = DateTime.now();
    Map<String, dynamic> user(int id, String role, DateTime? created) => {
          'id': id,
          'name': 'QA $id',
          'email': 'qa$id@test.local',
          'role': role,
          'createdAt': created?.toUtc().toIso8601String()
        };
    final state = AppState(accountApi: AccountApi(client: MockClient((r) async {
      if (r.url.path.endsWith('/admin/accounts')) {
        return json([
          user(2, 'SHIPPER', now),
          user(3, 'SHIPPER', now.subtract(const Duration(days: 20))),
          user(4, 'CUSTOMER', now),
          user(5, 'SHIPPER', null)
        ]);
      }
      if (r.url.path.endsWith('/branches')) return json([]);
      return json({});
    })))
      ..account =
          const Account(99, 'admin@test.local', 'Admin', Role.admin, null);
    await t.pumpWidget(MaterialApp(home: AdminHome(state: state)));
    await t.pumpAndSettle();
    await t.tap(find.text('Tài khoản'));
    await t.pumpAndSettle();
    final kinds = find.byType(DropdownButtonFormField<String>);
    await t.ensureVisible(kinds);
    await t.tap(kinds);
    await t.pumpAndSettle();
    await t.tap(find.text('Shipper').last);
    await t.pumpAndSettle();
    final dates = find.descendant(
        of: find.byType(DateFilterBar),
        matching: find.byType(DropdownButton<String>));
    await t.ensureVisible(dates);
    await t.tap(dates);
    await t.pumpAndSettle();
    await t.tap(find.text('Hôm nay').last);
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('qa2@test.local'), 180,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('qa2@test.local'), findsOneWidget);
    expect(find.text('qa3@test.local'), findsNothing);
    expect(find.text('qa4@test.local'), findsNothing);
    expect(find.text('qa5@test.local'), findsNothing);
    expect(find.text('Tạo ngày ${displayDay(now)}'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    state.dispose();
  });
  testWidgets(
      'merchant tabs expose actual accounting, stock filters and branch logo on a narrow phone',
      (t) async {
    final state = AppState()
      ..account = const Account(1, 'store@test.local', 'Quản lý', Role.store, 2)
      ..branchList = [
        const Branch(2, 'Mộc • Quận 1', 'Điểm bán', 10.77, 106.7, brand: 'Mộc')
      ];
    state.products.addAll([
      Product(3, 2, 'Sữa', 25000, 0, '', 'Đồ uống'),
      Product(4, 2, 'Bánh', 15000, 4, '', 'Đồ ăn')
    ]);
    state.orders.add(order(1, DateTime.now(),
        delivered: DateTime.now(), paid: DateTime.now()));
    t.view.physicalSize = const Size(390, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(home: StoreHome(state: state)));
    await t.pumpAndSettle();
    expect(find.text('100.000đ'), findsOneWidget);
    expect(find.text('15.000đ'), findsOneWidget);
    expect(find.text('85.000đ'), findsOneWidget);
    await t.tap(find.text('Sản phẩm'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(ChoiceChip, 'Hết hàng'));
    await t.pumpAndSettle();
    expect(find.text('Sữa'), findsOneWidget);
    expect(find.text('Bánh'), findsNothing);
    await t.tap(find.text('Chi nhánh'));
    await t.pumpAndSettle();
    expect(find.text('Chi nhánh & tài khoản'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    state.dispose();
  });
}
