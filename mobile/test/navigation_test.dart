import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cstore_mobile/screens/location_picker.dart';

void main() {
  testWidgets('map requires pin plus address before confirm', (t) async {
    await t.pumpWidget(const MaterialApp(
        home: LocationPicker(title: 'Ghim vị trí', lat: 10.77, lng: 106.7)));
    expect(t.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    expect(find.byTooltip('Lấy vị trí GPS'), findsOneWidget);
    expect(
        find.text('Chạm vào bản đồ để ghim vị trí chính xác'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
}
