import 'dart:async';
import 'dart:convert';

import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/screens/auth/welcome.dart';
import 'package:cstore_mobile/services/account_api.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/services/social_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeSocialSignIn implements SocialSignIn {
  FakeSocialSignIn({this.configured = true, this.result = 'provider-proof'});
  final bool configured;
  final String? result;
  Completer<String?>? pending;
  int authentications = 0;
  int signOuts = 0;

  @override
  bool isConfigured(SocialProvider provider) => configured;
  @override
  Future<String?> authenticate(SocialProvider provider) async {
    authentications++;
    return pending == null ? result : await pending!.future;
  }

  @override
  Future<void> signOut() async => signOuts++;
}

http.Response providers({bool enabled = true}) =>
    http.Response(jsonEncode({'google': enabled, 'facebook': enabled}), 200);

http.Response session() => http.Response(
    jsonEncode({
      'token': 'app-session',
      'user': {
        'id': 42,
        'email': 'customer@example.com',
        'name': 'Customer from server',
        'role': 'CUSTOMER',
        'storeId': null,
      }
    }),
    200);

void main() {
  for (final provider in SocialProvider.values) {
    test('${provider.name} exchanges proof and loads the server account',
        () async {
      final native = FakeSocialSignIn();
      var exchanges = 0;
      final state = AppState(
          socialSignIn: native,
          accountApi: AccountApi(client: MockClient((request) async {
            if (request.url.path.endsWith('/auth/providers')) {
              return providers();
            }
            if (request.url.path.endsWith('/auth/social')) {
              exchanges++;
              expect(request.method, 'POST');
              expect(jsonDecode(request.body), {
                'provider': provider.name,
                'token': 'provider-proof',
              });
              return session();
            }
            expect(request.headers['Authorization'], 'Bearer app-session');
            return http.Response('[]', 200);
          })));
      addTearDown(state.dispose);
      expect(await state.loginSocial(provider), isTrue);
      expect(exchanges, 1);
      expect(state.account!.id, 42);
      expect(state.account!.role, Role.customer);
      expect(state.api.token, 'app-session');
      state.logout();
      expect(state.account, isNull);
      expect(state.api.token, isNull);
      expect(native.signOuts, 1);
    });
  }

  test('cancelled provider login never sends a credential or creates a session',
      () async {
    final native = FakeSocialSignIn(result: null);
    final paths = <String>[];
    final state = AppState(
        socialSignIn: native,
        accountApi: AccountApi(client: MockClient((request) async {
          paths.add(request.url.path);
          return providers();
        })));
    addTearDown(state.dispose);
    expect(await state.loginSocial(SocialProvider.google), isFalse);
    expect(paths, ['/api/auth/providers']);
    expect(state.account, isNull);
    expect(state.api.token, isNull);
  });

  test('missing mobile configuration never calls a provider or backend',
      () async {
    final native = FakeSocialSignIn(configured: false);
    final state = AppState(
        socialSignIn: native,
        accountApi: AccountApi(client: MockClient((_) async {
          fail('No backend request expected when mobile config is missing');
        })));
    addTearDown(state.dispose);
    await expectLater(
        state.loginSocial(SocialProvider.facebook), throwsStateError);
    expect(native.authentications, 0);
    expect(state.account, isNull);
  });

  test('disabled backend provider never opens native sign in', () async {
    final native = FakeSocialSignIn();
    final state = AppState(
        socialSignIn: native,
        accountApi: AccountApi(
            client: MockClient((_) async => providers(enabled: false))));
    addTearDown(state.dispose);
    await expectLater(
        state.loginSocial(SocialProvider.google), throwsStateError);
    expect(native.authentications, 0);
    expect(state.api.token, isNull);
  });

  test('rejected provider proof never creates a session', () async {
    final state = AppState(
        socialSignIn: FakeSocialSignIn(),
        accountApi: AccountApi(client: MockClient((request) async {
          return request.url.path.endsWith('/auth/providers')
              ? providers()
              : http.Response('{}', 401);
        })));
    addTearDown(state.dispose);
    await expectLater(
        state.loginSocial(SocialProvider.google),
        throwsA(isA<StateError>().having((e) => e.message, 'message',
            'Không xác minh được đăng nhập. Vui lòng thử lại.')));
    expect(state.account, isNull);
    expect(state.api.token, isNull);
  });

  test('failure loading a new social session clears its application token',
      () async {
    final state = AppState(
        socialSignIn: FakeSocialSignIn(),
        accountApi: AccountApi(client: MockClient((request) async {
          if (request.url.path.endsWith('/auth/providers')) return providers();
          if (request.url.path.endsWith('/auth/social')) return session();
          return http.Response('{}', 503);
        })));
    addTearDown(state.dispose);
    await expectLater(
        state.loginSocial(SocialProvider.facebook), throwsStateError);
    expect(state.account, isNull);
    expect(state.api.token, isNull);
  });

  testWidgets('social buttons prevent repeat requests and recover on cancel',
      (tester) async {
    final native = FakeSocialSignIn()..pending = Completer<String?>();
    var requests = 0;
    final state = AppState(
        socialSignIn: native,
        accountApi: AccountApi(client: MockClient((_) async {
          requests++;
          return providers();
        })));
    await tester.pumpWidget(MaterialApp(home: LoginPage(state: state)));
    final google = find.byKey(const ValueKey('login-google'));
    final facebook = find.byKey(const ValueKey('login-facebook'));
    await tester.ensureVisible(google);
    await tester.tap(google);
    await tester.pump();
    expect(tester.widget<OutlinedButton>(google).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(facebook).onPressed, isNull);
    expect(await state.loginSocial(SocialProvider.facebook), isFalse);
    expect(requests, 1);
    expect(native.authentications, 1);
    native.pending!.complete(null);
    await tester.pumpAndSettle();
    expect(tester.widget<OutlinedButton>(google).onPressed, isNotNull);
    expect(find.text('Đã hủy đăng nhập Google.'), findsOneWidget);
    expect(state.account, isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
