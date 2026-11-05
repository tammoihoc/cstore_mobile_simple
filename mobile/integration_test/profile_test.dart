import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cstore_mobile/app/app.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/screens/customer/customer_home.dart';
import 'package:cstore_mobile/screens/shipper/shipper_home.dart';
import 'package:cstore_mobile/screens/profile/profile_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'customer defaults, password session rotation and native shipper portrait',
      (t) async {
    t.testTextInput.register();
    addTearDown(t.testTextInput.unregister);
    final state = AppState();
    const customerEmail = String.fromEnvironment('QA_CUSTOMER_EMAIL'),
        customerPassword = String.fromEnvironment('QA_CUSTOMER_PASSWORD');
    const shipperEmail = String.fromEnvironment('QA_SHIPPER_EMAIL'),
        shipperPassword = String.fromEnvironment('QA_SHIPPER_PASSWORD');
    const temporaryPassword = String.fromEnvironment('QA_PROFILE_PASSWORD');
    Finder input(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label);
    Future<void> waitUntil(bool Function() ready, String description) async {
      for (var i = 0; i < 180; i++) {
        await t.pump(const Duration(milliseconds: 300));
        if (ready()) return;
      }
      fail('Timeout: $description');
    }

    Future<void> ready(Finder f) =>
        waitUntil(() => f.evaluate().isNotEmpty, 'expected screen or result');
    Future<void> reveal(Finder f) async {
      if (f.evaluate().isEmpty) {
        final scrolling = find.byType(Scrollable).first;
        t.state<ScrollableState>(scrolling).position.jumpTo(0);
        await t.pump();
        if (f.evaluate().isEmpty) {
          await t.scrollUntilVisible(f, 200, scrollable: scrolling);
        }
      }
      await t.ensureVisible(f);
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

    Future<void> tap(String label) async {
      final f = find.text(label);
      await reveal(f);
      await t.tap(f);
      await t.pumpAndSettle();
    }

    Future<void> shot(String label) async {
      await t.pumpAndSettle();
      debugPrint('QA_SCREENSHOT_$label');
      await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    }

    Future<void> login(String email, String password) async {
      await enter('Email', email);
      await enter('Mật khẩu', password);
      await hide();
      await tap('Đăng nhập');
      await waitUntil(
          () => state.timer != null && !state.loading, 'authenticated account');
    }

    Future<void> password(String previous, String next) async {
      await tap('Đổi mật khẩu');
      await ready(find.byType(ChangePasswordPage));
      await enter('Mật khẩu hiện tại', previous);
      await enter('Mật khẩu mới', next);
      await enter('Nhập lại mật khẩu mới', next);
      await hide();
      await shot('PASSWORD_SETTINGS');
      await tap('Lưu mật khẩu');
      await waitUntil(() => find.byType(ChangePasswordPage).evaluate().isEmpty,
          'password updated');
      await t.pumpAndSettle();
    }

    await t.pumpWidget(CStoreApp(state: state));
    await t.pumpAndSettle();
    await login(customerEmail, customerPassword);
    await ready(find.byType(CustomerHome));
    await t.tap(find.byTooltip('Hồ sơ của tôi'));
    await t.pumpAndSettle();
    await tap('Chỉnh sửa hồ sơ');
    await ready(find.byType(EditProfilePage));
    await enter('Họ và tên', 'Khách QA hồ sơ');
    await enter('Số điện thoại', '0901234567');
    await hide();
    expect(find.text('Avatar mặc định'), findsNothing);
    expect(find.text('Lựa chọn hiển thị'), findsNothing);
    final genders = find.byType(DropdownButtonFormField<String>);
    await reveal(genders);
    await t.tap(genders);
    await t.pumpAndSettle();
    await t.tap(find.text('Nữ').last);
    await t.pumpAndSettle();
    await shot('CUSTOMER_EDIT_PROFILE');
    await tap('Lưu hồ sơ');
    await waitUntil(
        () => find.byType(EditProfilePage).evaluate().isEmpty, 'saved profile');
    expect(state.account!.gender, 'FEMALE');
    expect(state.account!.phone, '0901234567');
    final saved = await state.api.profile();
    expect(saved.gender, 'FEMALE');
    expect(saved.name, 'Khách QA hồ sơ');
    await shot('CUSTOMER_PROFILE');
    final oldToken = state.api.token;
    // Restore the original QA password in finally so existing QA credentials remain usable.
    var passwordChanged = false;
    try {
      await password(customerPassword, temporaryPassword);
      passwordChanged = true;
      expect(state.api.token, isNot(oldToken));
      final revoked = await state.api.client.get(
          Uri.parse(state.api.imageUrl('/api/account/profile')),
          headers: {'Authorization': 'Bearer $oldToken'});
      expect(revoked.statusCode, 401);
      await state.api.profile();
      await password(temporaryPassword, customerPassword);
      passwordChanged = false;
    } finally {
      if (passwordChanged) {
        await state.changePassword(temporaryPassword, customerPassword);
      }
    }
    state.logout();
    await t.pumpAndSettle();
    await login(shipperEmail, shipperPassword);
    await ready(find.byType(ShipperHome));
    await t.tap(find.text('Hồ sơ'));
    await t.pumpAndSettle();
    await tap('Chỉnh sửa hồ sơ');
    final before = state.account!.avatar;
    debugPrint('QA_NATIVE_GALLERY_READY');
    await tap('Chọn ảnh đại diện');
    await waitUntil(
        () => state.account!.avatar != before, 'native portrait upload');
    expect(state.account!.avatar, startsWith('/api/images/'));
    expect(state.account!.photoRequired, isFalse);
    await enter('Số điện thoại', '0987654321');
    await hide();
    await shot('SHIPPER_EDIT_PROFILE');
    await tap('Lưu hồ sơ');
    await waitUntil(() => find.byType(EditProfilePage).evaluate().isEmpty,
        'saved shipper profile');
    final shipper = await state.api.profile();
    expect(shipper.phone, '0987654321');
    expect(shipper.avatar, state.account!.avatar);
    await shot('SHIPPER_PROFILE');
    debugPrint(
        'QA_PROFILE_PASS defaults=true nativePortrait=true passwordRotation=true originalPasswordRestored=true');
  });
}
