import 'dart:async';
import 'dart:convert';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/screens/location_picker.dart';
import 'package:cstore_mobile/services/account_api.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/services/geocoding_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class ControlledGeocoding extends GeocodingService {
  final pending = <Completer<String?>>[];
  @override
  Future<String?> reverse(double lat, double lng) {
    final request = Completer<String?>();
    pending.add(request);
    return request.future;
  }
}

void main() {
  test('delivery pin survives login and remains isolated between accounts',
      () async {
    Map<String, dynamic>? saved;
    final state =
        AppState(accountApi: AccountApi(client: MockClient((request) async {
      if (request.url.path.endsWith('/auth/login')) {
        return http.Response(
            jsonEncode({
              'token': 'test-session',
              'user': {
                'id': 7,
                'email': 'buyer@test.local',
                'name': 'Buyer',
                'role': 'CUSTOMER'
              }
            }),
            200);
      }
      if (request.url.path.endsWith('/customer/location')) {
        if (request.method == 'PUT') {
          saved = jsonDecode(request.body) as Map<String, dynamic>;
        }
        return http.Response.bytes(utf8.encode(jsonEncode(saved)), 200);
      }
      return http.Response('[]', 200);
    })));
    addTearDown(state.dispose);
    await state.login('buyer@test.local', 'test-password');
    expect(state.positionKnown, isFalse);
    await state.setLocation('12 Đường đã sửa', 10.7736, 106.7034);
    expect(saved!['pinConfirmed'], isTrue);
    state.logout();
    expect(state.positionKnown, isFalse);
    expect(state.location, 'Chọn vị trí giao hàng');
    await state.login('buyer@test.local', 'test-password');
    expect(state.positionKnown, isTrue);
    expect(state.location, '12 Đường đã sửa');
    expect(state.lat, 10.7736);
    saved = null;
    state.logout();
    await state.login('buyer@test.local', 'test-password');
    expect(state.positionKnown, isFalse);
  });

  testWidgets('reopening saved pin retains address and shop markers',
      (tester) async {
    PinnedLocation? result;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      result = await Navigator.push<PinnedLocation>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LocationPicker(
                                      title: 'Điểm giao',
                                      lat: 10.7736,
                                      lng: 106.7034,
                                      address: '12 Đường đã sửa',
                                      initialPinConfirmed: true,
                                      branches: [
                                        Branch(1, 'Shop đã đăng ký', 'Address',
                                            10.774, 106.704)
                                      ])));
                    },
                    child: const Text('Mở'))))));
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    expect(find.text('Shop đã đăng ký'), findsOneWidget);
    expect(find.byIcon(Icons.location_pin), findsOneWidget);
    final input = find.byType(TextField);
    expect(tester.widget<TextField>(input).controller!.text, '12 Đường đã sửa');
    await tester.enterText(input, '15 Đường khách sửa');
    await tester.tap(find.text('Xác nhận vị trí đã ghim'));
    await tester.pumpAndSettle();
    expect(result!.address, '15 Đường khách sửa');
    expect(result!.lat, 10.7736);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('stale geocoding cannot overwrite new pin or manual address',
      (tester) async {
    final geocoding = ControlledGeocoding();
    await tester.pumpWidget(MaterialApp(
        home: LocationPicker(
            title: 'Điểm giao',
            lat: 10.7736,
            lng: 106.7034,
            geocodingService: geocoding)));
    await tester.pump();
    final center = tester.getCenter(find.byType(FlutterMap));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 400));
    expect(geocoding.pending.length, 1);
    await tester.tapAt(center + const Offset(60, -60));
    await tester.pump(const Duration(milliseconds: 400));
    expect(geocoding.pending.length, 2);
    geocoding.pending.last.complete('Địa chỉ mới');
    await tester.pump();
    geocoding.pending.first.complete('Địa chỉ cũ');
    await tester.pump();
    final input = find.byType(TextField);
    expect(tester.widget<TextField>(input).controller!.text, 'Địa chỉ mới');
    await tester.enterText(input, 'Số nhà khách sửa');
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);
    expect(
        tester.widget<TextField>(input).controller!.text, 'Số nhà khách sửa');
    await tester.pumpWidget(const SizedBox());
    geocoding.dispose();
  });
}
