import 'package:cstore_mobile/app/app.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppState customerState() => AppState()
  ..account =
      const Account(1, 'scroll@test.local', 'Khách', Role.customer, null)
  ..positionKnown = true
  ..lat = 10.77
  ..lng = 106.7
  ..branchList = [
    for (var i = 0; i < 12; i++)
      Branch(i, 'Cửa hàng $i', 'Địa chỉ $i', 10.77, 106.7)
  ]
  ..nearbyQuotes.addEntries([
    for (var i = 0; i < 12; i++) MapEntry(i, DeliveryQuote(i, .5, 120, 16500))
  ]);

Future<void> showCustomerPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(CStoreApp(state: customerState()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pulling past the top does not stretch page content',
      (tester) async {
    await showCustomerPage(tester);
    final title = find.text('Hôm nay, mua gì nhỉ?');
    final before = tester.getRect(title);
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);

    final gesture = await tester.startGesture(before.center);
    await gesture.moveBy(const Offset(0, 180));
    await tester.pump(const Duration(milliseconds: 100));

    expect(scroll.position.pixels, scroll.position.minScrollExtent);
    expect(tester.getRect(title), before);
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    await gesture.up();
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('all stores remain reachable and bottom drag keeps their size',
      (tester) async {
    await showCustomerPage(tester);
    final scrollable = find.byType(Scrollable).first;
    final lastStore = find.text('Cửa hàng 11');
    await tester.scrollUntilVisible(lastStore, 400, scrollable: scrollable);
    await tester.pumpAndSettle();
    expect(lastStore.hitTestable(), findsOneWidget);

    final scroll = tester.state<ScrollableState>(scrollable);
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await tester.pump();
    final before = tester.getRect(lastStore);
    final gesture = await tester.startGesture(before.center);
    await gesture.moveBy(const Offset(0, -180));
    await tester.pump(const Duration(milliseconds: 100));

    expect(scroll.position.pixels, scroll.position.maxScrollExtent);
    expect(tester.getRect(lastStore), before);
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    await gesture.up();
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('mouse wheel still scrolls the customer page', (tester) async {
    await showCustomerPage(tester);
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    await tester.sendEventToBinding(PointerScrollEvent(
        kind: PointerDeviceKind.mouse,
        position: tester.getCenter(find.byType(ListView)),
        scrollDelta: const Offset(0, 300)));
    await tester.pumpAndSettle();

    expect(scroll.position.pixels, greaterThan(0));
    expect(scroll.position.pixels,
        lessThanOrEqualTo(scroll.position.maxScrollExtent));
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
