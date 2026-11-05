import 'package:cstore_mobile/app/app.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/widgets/cstore_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android login scroll and registration validation',
      (tester) async {
    final state = AppState();
    await tester.pumpWidget(CStoreApp(state: state));

    // Bounded pumps keep this smoke test independent of network/SDK activity.
    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    final list = find.byKey(const ValueKey('login-scroll'));
    final scrollable = find.descendant(
        of: list,
        matching: find.byWidgetPredicate((widget) =>
            widget is Scrollable &&
            widget.axisDirection == AxisDirection.down));
    Future<void> reveal(Finder finder) async {
      await tester.scrollUntilVisible(finder, 240, scrollable: scrollable);
      await tester.ensureVisible(finder);
      await settle();
      expect(finder.hitTestable(), findsOneWidget);
    }

    await settle();
    expect(list, findsOneWidget);
    expect(find.text('Mừng bạn trở lại'), findsOneWidget);
    final scroll = tester.state<ScrollableState>(scrollable);
    final brand = find.byType(CStoreLogo);
    final before = tester.getRect(brand);

    debugPrint('QA_UI: Kéo quá đầu trang, kiểm tra nội dung không bị giãn.');
    final gesture = await tester.startGesture(before.center);
    await gesture.moveBy(const Offset(0, 180));
    await tester.pump(const Duration(milliseconds: 200));
    final during = tester.getRect(brand);
    expect(
        scroll.position.pixels, closeTo(scroll.position.minScrollExtent, .1));
    expect(during.top, closeTo(before.top, .5));
    expect(during.height, closeTo(before.height, .5));
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    await gesture.up();
    await settle();

    debugPrint('QA_UI: Cuộn đến hai nút Google và Facebook.');
    final google = find.byKey(const ValueKey('login-google'));
    final facebook = find.byKey(const ValueKey('login-facebook'));
    await reveal(google);
    await reveal(facebook);
    if (scroll.position.maxScrollExtent > 0) {
      await tester.drag(list, const Offset(0, -160));
      await settle();
      expect(scroll.position.pixels, greaterThan(0));
    }
    expect(tester.widget<OutlinedButton>(google).onPressed, isNotNull);
    expect(tester.widget<OutlinedButton>(facebook).onPressed, isNotNull);

    debugPrint(
        'QA_UI: Chuyển đăng ký và kiểm tra form trống, không gọi OAuth.');
    final toggle = find.byKey(const ValueKey('login-register-toggle'));
    await reveal(toggle);
    await tester.tap(toggle);
    await settle();
    expect(find.text('Đã có tài khoản? Đăng nhập'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    final register = find.widgetWithText(FilledButton, 'Tạo tài khoản');
    await reveal(register);
    await tester.tap(register);
    await settle();
    expect(find.text('Nhập họ tên'), findsOneWidget);
    expect(find.text('Nhập email hợp lệ'), findsOneWidget);
    expect(find.text('Nhập mật khẩu'), findsOneWidget);
    expect(state.account, isNull);
    expect(state.api.token, isNull);

    await reveal(toggle);
    await tester.tap(toggle);
    await settle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    await reveal(google);
    await reveal(facebook);
    expect(tester.takeException(), isNull);
    debugPrint(
        'QA_UI: Đạt kiểm tra giao diện; chưa xác thực tài khoản OAuth thật.');
  });
}
