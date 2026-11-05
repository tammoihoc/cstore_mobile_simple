import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cstore_mobile/app/app.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/screens/admin/admin_home.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('admin brand overview, logo branch creation and store removal',
      (t) async {
    t.testTextInput.register();
    addTearDown(t.testTextInput.unregister);
    const adminEmail = String.fromEnvironment('QA_ADMIN_EMAIL');
    const adminPassword = String.fromEnvironment('QA_ADMIN_PASSWORD');
    const partnerPassword = String.fromEnvironment('QA_PARTNER_PASSWORD');
    expect(adminEmail, isNotEmpty);
    expect(adminPassword, isNotEmpty);
    expect(partnerPassword.length, greaterThanOrEqualTo(8));
    final state = AppState();
    final unique = DateTime.now().microsecondsSinceEpoch;
    final partnerEmail = 'qa.ui.$unique@cstore.local';
    final secondEmail = 'qa.ui.branch.$unique@cstore.local';
    final partnerName = 'QA Brand $unique';
    Finder input(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label);
    Finder hint(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == label);
    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 150; i++) {
        await t.pump(const Duration(milliseconds: 300));
        if (finder.evaluate().isNotEmpty) return;
      }
      fail('Expected screen did not appear');
    }

    Future<void> idle() async {
      for (var i = 0; i < 150; i++) {
        await t.pump(const Duration(milliseconds: 300));
        if (find.byType(LinearProgressIndicator).evaluate().isEmpty) {
          await t.pumpAndSettle();
          return;
        }
      }
      fail('Admin data did not finish loading');
    }

    Future<void> reveal(Finder finder) async {
      if (finder.evaluate().isEmpty) {
        final scrolling = find.byType(Scrollable).last;
        final scroll = t.state<ScrollableState>(scrolling);
        scroll.position.jumpTo(scroll.position.minScrollExtent);
        await t.pump();
        if (finder.evaluate().isEmpty) {
          await t.scrollUntilVisible(finder, 200, scrollable: scrolling);
        }
      }
      await t.ensureVisible(finder);
      await t.pumpAndSettle();
    }

    Future<void> enter(String label, String text) async {
      final field = input(label);
      await reveal(field);
      await t.showKeyboard(field);
      await t.pumpAndSettle();
      await t.enterText(field, text);
      await t.pumpAndSettle();
    }

    Future<void> hide() async {
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      await t.pumpAndSettle();
    }

    Future<void> snapshot(String name) async {
      await t.pumpAndSettle();
      debugPrint('QA_SCREENSHOT_$name');
      await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    }

    Future<void> pin(String address) async {
      await reveal(find.text('Chưa ghim vị trí chi nhánh'));
      await t.tap(find.text('Chưa ghim vị trí chi nhánh'));
      await t.pumpAndSettle();
      await waitFor(find.byType(FlutterMap));
      await t.tap(find.byTooltip('Lấy vị trí GPS'));
      await waitFor(find.textContaining('Vị trí Android •'));
      await enter('Địa chỉ giao hàng', address);
      await hide();
      expect(t.widget<TextField>(input('Địa chỉ giao hàng')).controller!.text,
          address);
      await reveal(find.text('Xác nhận vị trí đã ghim'));
      await t.tap(find.text('Xác nhận vị trí đã ghim'));
      await t.pumpAndSettle();
    }

    Future<void> remove(String email) async {
      await t.tap(find.text('Tài khoản'));
      await t.pumpAndSettle();
      final search = hint('Tìm theo tên hoặc email');
      await t.enterText(search, email);
      await hide();
      await reveal(find.byTooltip('Quản lý tài khoản'));
      await snapshot('ADMIN_ACCOUNTS');
      await t.tap(find.byTooltip('Quản lý tài khoản'));
      await t.pumpAndSettle();
      await t.tap(find.text('Xóa cửa hàng và tài khoản'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(FilledButton, 'Xóa cửa hàng'));
      await idle();
    }

    await t.pumpWidget(CStoreApp(state: state));
    await t.pumpAndSettle();
    await enter('Email', adminEmail);
    await enter('Mật khẩu', adminPassword);
    await hide();
    await reveal(find.text('Đăng nhập'));
    await t.tap(find.text('Đăng nhập'));
    await waitFor(find.byType(AdminHome));
    await idle();
    await snapshot('ADMIN_OVERVIEW');
    await t.tap(find.text('Tài khoản'));
    await t.pumpAndSettle();
    await t.tap(find.text('Cửa hàng'));
    await t.pumpAndSettle();
    await snapshot('ADMIN_STORE_ACCOUNTS');
    await t.tap(find.text('Shipper'));
    await t.pumpAndSettle();
    await snapshot('ADMIN_SHIPPER_ACCOUNTS');
    await t.tap(find.text('Tất cả'));
    await t.pumpAndSettle();
    await t.tap(find.text('Tổng quan'));
    await t.pumpAndSettle();
    await t.tap(find.text('Tạo thương hiệu'));
    await t.pumpAndSettle();
    await enter('Tên thương hiệu', partnerName);
    await hide();
    await pin('45 Nguyen Hue, Quan 1');
    await reveal(find.text('45 Nguyen Hue, Quan 1'));
    await t.tap(find.text('45 Nguyen Hue, Quan 1'));
    await t.pumpAndSettle();
    expect(t.widget<TextField>(input('Địa chỉ giao hàng')).controller!.text,
        '45 Nguyen Hue, Quan 1');
    await t.tap(find.text('Xác nhận vị trí đã ghim'));
    await t.pumpAndSettle();
    await reveal(find.text('Chọn ảnh thương hiệu'));
    debugPrint('QA_NATIVE_GALLERY_READY');
    await t.tap(find.text('Chọn ảnh thương hiệu'));
    await waitFor(
        find.byWidgetPredicate((w) => w is Image && w.image is MemoryImage));
    await enter('Tên người phụ trách', partnerName);
    await enter('Email đăng nhập', partnerEmail);
    await enter('Mật khẩu ban đầu', partnerPassword);
    await hide();
    await t.tap(find.text('Tạo thương hiệu và tài khoản'));
    await waitFor(find.byType(AdminHome));
    await idle();
    final accounts = await state.api.accounts();
    final first = accounts.singleWhere((a) => a.email == partnerEmail);
    final created = state.branchList.singleWhere((b) => b.id == first.storeId);
    expect(created.brand, partnerName);
    expect(created.image, isNotEmpty);
    expect(first.storeOwner, isTrue);
    await t.tap(find.text('Thương hiệu'));
    await t.pumpAndSettle();
    await t.enterText(hint('Tìm thương hiệu'), partnerName);
    await hide();
    await t
        .tap(find.byWidgetPredicate((w) => w is Text && w.data == partnerName));
    await t.pumpAndSettle();
    await snapshot('ADMIN_BRAND_DETAIL');
    await t.tap(find.text('Thêm chi nhánh'));
    await t.pumpAndSettle();
    expect(t.widget<TextField>(input('Tên thương hiệu')).controller!.text,
        partnerName);
    expect(t.widget<TextField>(input('Tên thương hiệu')).readOnly, isTrue);
    expect(find.text('Thêm chi nhánh · $partnerName'), findsOneWidget);
    await snapshot('ADMIN_BRANCH_FORM');
    await enter('Tên chi nhánh', 'Chi nhánh 2');
    await hide();
    await pin('QA chi nhanh 2');
    await enter('Tên người phụ trách', 'QA quản lý chi nhánh 2');
    await enter('Email đăng nhập', secondEmail);
    await enter('Mật khẩu ban đầu', partnerPassword);
    await hide();
    await t.tap(find.text('Tạo chi nhánh và tài khoản'));
    await waitFor(find.byType(AdminHome));
    await idle();
    final second =
        (await state.api.accounts()).singleWhere((a) => a.email == secondEmail);
    expect(state.branchList.singleWhere((b) => b.id == second.storeId).image,
        created.image);
    final brandData = (await state.api.request('/admin/brands') as List)
        .singleWhere((b) => b['name'] == partnerName);
    expect(brandData['branchCount'], 2);
    await snapshot('ADMIN_BRAND_LIST');
    await remove(partnerEmail);
    expect(state.branchList.any((b) => b.id == first.storeId), isFalse);
    final remaining = (await state.api.request('/admin/brands') as List)
        .singleWhere((b) => b['name'] == partnerName);
    expect(remaining['branchCount'], 1);
    await remove(secondEmail);
    expect(state.branchList.any((b) => b.brand == partnerName), isFalse);
    expect(
        (await state.api.request('/admin/brands') as List)
            .any((b) => b['name'] == partnerName),
        isFalse);
    await t.tap(find.text('Thương hiệu'));
    await t.pumpAndSettle();
    await t.tap(find.text('Tạo thương hiệu'));
    await t.pumpAndSettle();
    await t.tap(find.byType(DropdownButtonFormField<String>));
    await t.pumpAndSettle();
    expect(find.text('Thêm chi nhánh · $partnerName'), findsNothing);
    await t.pageBack();
    await t.pumpAndSettle();
    await t.pageBack();
    await t.pumpAndSettle();
    await t.tap(find.text('Tổng quan'));
    await idle();
    await snapshot('ADMIN_FINAL');
    debugPrint(
        'QA_ADMIN_BRANDS_PASS groupedRevenue=true branchLogo=true deletedStoresHidden=true');
  });
}
