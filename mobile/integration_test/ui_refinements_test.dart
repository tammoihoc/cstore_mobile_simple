import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cstore_mobile/app/app.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/models/store_metrics.dart';
import 'package:cstore_mobile/screens/customer/customer_home.dart';
import 'package:cstore_mobile/screens/shipper/shipper_home.dart';
import 'package:cstore_mobile/screens/store/store_home.dart';
import 'package:cstore_mobile/screens/admin/admin_home.dart';
import 'package:cstore_mobile/screens/profile/profile_page.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/widgets/date_filter.dart';
import 'package:cstore_mobile/widgets/product_image.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'compact profiles, own-photo priority, role contacts, date filters and merchant redesign',
      (t) async {
    t.testTextInput.register();
    addTearDown(t.testTextInput.unregister);
    final state = AppState();
    const customerEmail = String.fromEnvironment('QA_CUSTOMER_EMAIL'),
        customerPassword = String.fromEnvironment('QA_CUSTOMER_PASSWORD');
    const shipperEmail = String.fromEnvironment('QA_SHIPPER_EMAIL'),
        shipperPassword = String.fromEnvironment('QA_SHIPPER_PASSWORD');
    const storeEmail = String.fromEnvironment('QA_STORE_EMAIL'),
        storePassword = String.fromEnvironment('QA_STORE_PASSWORD');
    const adminEmail = String.fromEnvironment('QA_ADMIN_EMAIL'),
        adminPassword = String.fromEnvironment('QA_ADMIN_PASSWORD');
    const createdPassword = String.fromEnvironment('QA_PROFILE_PASSWORD');
    Finder input(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label);
    Future<void> until(bool Function() ready, String description) async {
      for (var i = 0; i < 200; i++) {
        await t.pump(const Duration(milliseconds: 300));
        if (ready()) return;
      }
      fail('Timeout: $description');
    }

    Future<void> reveal(Finder f) async {
      if (f.evaluate().isEmpty) {
        final scroll = find.byType(Scrollable).first;
        t.state<ScrollableState>(scroll).position.jumpTo(0);
        await t.pump();
        if (f.evaluate().isEmpty) {
          await t.scrollUntilVisible(f, 180, scrollable: scroll);
        }
      }
      await t.ensureVisible(f);
      await t.pumpAndSettle();
    }

    Future<void> tap(String text) async {
      final f = find.text(text);
      await reveal(f);
      await t.tap(f);
      await t.pumpAndSettle();
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
      await t.pumpAndSettle();
    }

    Future<void> shot(String label) async {
      await t.pumpAndSettle();
      debugPrint('QA_SCREENSHOT_$label');
      await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    }

    Future<void> top() async {
      t
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await t.pumpAndSettle();
    }

    Future<void> login(String email, String password) async {
      await enter('Email', email);
      await enter('Mật khẩu', password);
      await hide();
      await tap('Đăng nhập');
      await until(
          () => state.timer != null && !state.loading, 'session loaded');
    }

    Future<void> logout() async {
      final context = t.element(find.byType(Scaffold).first);
      Navigator.of(context).popUntil((route) => route.isFirst);
      await t.pumpAndSettle();
      state.logout();
      await t.pumpAndSettle();
    }

    Future<void> gender(String label) async {
      final f = find.byType(DropdownButtonFormField<String>);
      await reveal(f);
      await t.tap(f);
      await t.pumpAndSettle();
      await t.tap(find.text(label).last);
      await t.pumpAndSettle();
    }

    Future<void> dates(String choice) async {
      final f = find.descendant(
          of: find.byType(DateFilterBar),
          matching: find.byType(DropdownButton<String>));
      await reveal(f);
      await t.tap(f);
      await t.pumpAndSettle();
      await t.tap(find.text(choice).last);
      await t.pumpAndSettle();
    }

    await t.pumpWidget(CStoreApp(state: state));
    await t.pumpAndSettle();
    await login(customerEmail, customerPassword);
    expect(find.byType(CustomerHome), findsOneWidget);
    await t.tap(find.byTooltip('Hồ sơ của tôi'));
    await t.pumpAndSettle();
    expect(find.text('Số điện thoại'), findsNothing);
    await tap('Chỉnh sửa hồ sơ');
    expect(find.text('Lựa chọn hiển thị'), findsNothing);
    expect(find.text('Avatar mặc định'), findsNothing);
    if (state.account!.avatar.isNotEmpty) await tap('Xóa ảnh đại diện');
    await gender('Nam');
    expect(
        t
            .widgetList<ProductImage>(find.byType(ProductImage))
            .any((w) => w.path == 'assets/images/avatar-default-male.png'),
        isTrue);
    debugPrint('QA_NATIVE_GALLERY_READY');
    await tap('Chọn ảnh đại diện');
    await until(
        () => state.account!.avatar.isNotEmpty, 'native customer photo upload');
    final personal = state.account!.avatar;
    await gender('Nữ');
    expect(state.account!.avatar, personal);
    expect(
        t
            .widgetList<ProductImage>(find.byType(ProductImage))
            .any((w) => w.path == personal),
        isTrue);
    await shot('CUSTOMER_PERSONAL_PHOTO_PRIORITY');
    await tap('Xóa ảnh đại diện');
    await until(() => state.account!.avatar.isEmpty, 'explicit photo removal');
    expect(
        t
            .widgetList<ProductImage>(find.byType(ProductImage))
            .any((w) => w.path == 'assets/images/avatar-default-female.png'),
        isTrue);
    await shot('CUSTOMER_GENDER_AVATAR');
    await tap('Lưu hồ sơ');
    await until(
        () => find.byType(EditProfilePage).evaluate().isEmpty, 'profile saved');
    expect((await state.api.profile()).gender, 'FEMALE');
    await top();
    await shot('CUSTOMER_COMPACT_PROFILE');
    await t.tap(find.text('Đơn hàng'));
    await t.pumpAndSettle();
    await dates('7 ngày gần đây');
    await shot('CUSTOMER_HISTORY_DATE_FILTER');
    final customerOrder =
        state.customerOrders.where((o) => o.shipperId != null).first;
    await reveal(find.text('#CS${customerOrder.id}'));
    await t.tap(find.text('#CS${customerOrder.id}'));
    await t.pumpAndSettle();
    await reveal(find.text('Người giao hàng của bạn'));
    expect(find.byTooltip('Gọi người nhận'), findsNothing);
    expect(find.byTooltip('Gọi shipper'), findsOneWidget);
    await shot('CUSTOMER_CONTACT_SHIPPER');
    await logout();
    await login(shipperEmail, shipperPassword);
    expect(find.byType(ShipperHome), findsOneWidget);
    if (state.deliveries.isEmpty) {
      await logout();
      await login(const String.fromEnvironment('QA_OTHER_SHIPPER_EMAIL'),
          const String.fromEnvironment('QA_OTHER_SHIPPER_PASSWORD'));
    }
    await t.tap(find.text('Hồ sơ'));
    await t.pumpAndSettle();
    expect(find.text('Số điện thoại'), findsNothing);
    await shot('SHIPPER_COMPACT_PROFILE');
    await t.tap(find.text('Lịch sử'));
    await t.pumpAndSettle();
    await dates('7 ngày gần đây');
    await shot('SHIPPER_HISTORY_DATE_FILTER');
    final delivery = state.deliveries.first;
    await reveal(find.text('#CS${delivery.id}'));
    await t.tap(find.text('#CS${delivery.id}'));
    await t.pumpAndSettle();
    await reveal(find.text('Tài xế phụ trách'));
    expect(find.byTooltip('Gọi shipper'), findsNothing);
    expect(find.byTooltip('Gọi người nhận'), findsOneWidget);
    await shot('SHIPPER_CONTACT_RECIPIENT');
    await logout();
    await login(storeEmail, storePassword);
    expect(find.byType(StoreHome), findsOneWidget);
    await dates('Tất cả ngày');
    final stats = StoreMetrics(state.storeOrders, null);
    expect(find.text(money(stats.revenue)), findsWidgets);
    expect(find.text(money(stats.estimatedNet)), findsWidgets);
    await top();
    await shot('STORE_NEW_OVERVIEW');
    await reveal(find.text('Món bán tốt'));
    await shot('STORE_REVENUE_PRODUCTS');
    await t.tap(find.text('Sản phẩm'));
    await t.pumpAndSettle();
    await shot('STORE_NEW_INVENTORY');
    await t.tap(find.text('Đơn hàng'));
    await t.pumpAndSettle();
    await dates('Hôm nay');
    await shot('STORE_NEW_ORDERS');
    await t.tap(find.text('Chi nhánh'));
    await t.pumpAndSettle();
    await shot('STORE_NEW_BRANCH');
    await logout();
    await login(adminEmail, adminPassword);
    expect(find.byType(AdminHome), findsOneWidget);
    final unique = DateTime.now().microsecondsSinceEpoch;
    final email = 'qa.refine.date.$unique@cstore.local';
    final created = await state.api.request('/admin/accounts', body: {
      'email': email,
      'fullName': 'QA bộ lọc ngày',
      'password': createdPassword,
      'role': 'SHIPPER'
    }) as Map<String, dynamic>;
    try {
      expect(created['createdAt'], isNotNull);
      await t.tap(find.byTooltip('Làm mới dữ liệu'));
      await until(() => find.byType(LinearProgressIndicator).evaluate().isEmpty,
          'admin reloaded');
      await t.tap(find.text('Tài khoản'));
      await t.pumpAndSettle();
      final kinds = find.byType(DropdownButtonFormField<String>);
      await reveal(kinds);
      await t.tap(kinds);
      await t.pumpAndSettle();
      await t.tap(find.text('Shipper').last);
      await t.pumpAndSettle();
      await dates('Hôm nay');
      final search = find.byWidgetPredicate((w) =>
          w is TextField &&
          w.decoration?.hintText == 'Tìm theo tên hoặc email');
      await reveal(search);
      await t.enterText(search, email);
      await hide();
      await reveal(find.byWidgetPredicate((w) => w is Text && w.data == email));
      expect(find.text('Chưa có ngày tạo'), findsNothing);
      await shot('ADMIN_ACCOUNT_CREATION_FILTERS');
    } finally {
      await state.api
          .request('/admin/accounts/${created['id']}', method: 'DELETE');
    }
    debugPrint(
        'QA_UI_REFINEMENTS_PASS genderPhotoPriority=true explicitRemoval=true noSelfCalls=true historyDates=true accountCreationFilters=true merchantRedesign=true');
  });
}
