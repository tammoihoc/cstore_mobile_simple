import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum SocialProvider {
  google('Google'),
  facebook('Facebook');

  const SocialProvider(this.label);
  final String label;
}

/// Obtains provider credentials only. Our backend decides the account and role.
abstract class SocialSignIn {
  bool isConfigured(SocialProvider provider);
  Future<String?> authenticate(SocialProvider provider);
  Future<void> signOut();
}

class NativeSocialSignIn implements SocialSignIn {
  static const _googleClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '682231635924-hahtn3bhl2bnc21bbrau2c164fh7gh0t.apps.googleusercontent.com',
  );
  static const _facebookAppId = String.fromEnvironment(
    'FACEBOOK_APP_ID',
    defaultValue: '1753843223411204',
  );
  static const _facebookClientToken = String.fromEnvironment(
    'FACEBOOK_CLIENT_TOKEN',
    defaultValue: '4f8754f686ed5593e176ff3219dc98e6',
  );
  static Future<void>? _googleInitialization;
  bool _facebookUsed = false;

  @override
  bool isConfigured(SocialProvider provider) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    return switch (provider) {
      SocialProvider.google =>
        _googleClientId.endsWith('.apps.googleusercontent.com'),
      SocialProvider.facebook =>
        RegExp(r'^[1-9][0-9]+$').hasMatch(_facebookAppId) &&
            _facebookClientToken.isNotEmpty,
    };
  }

  @override
  Future<String?> authenticate(SocialProvider provider) async {
    if (!isConfigured(provider)) {
      throw StateError(
        'Đăng nhập ${provider.label} chưa được bật. Bạn có thể dùng email.',
      );
    }
    try {
      if (provider == SocialProvider.google) {
        await (_googleInitialization ??=
            GoogleSignIn.instance.initialize(serverClientId: _googleClientId));
        final account = await GoogleSignIn.instance.authenticate();
        final token = account.authentication.idToken;
        if (token == null || token.isEmpty) {
          throw StateError('Google chưa xác nhận được đăng nhập. Hãy thử lại.');
        }
        return token;
      }
      final result = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
      );
      if (result.status == LoginStatus.cancelled) return null;
      final token = result.accessToken;
      if (result.status != LoginStatus.success ||
          token == null ||
          token.tokenString.isEmpty) {
        throw StateError('Không đăng nhập được Facebook. Vui lòng thử lại.');
      }
      // The Android backend exchange accepts Graph API access tokens only.
      if (token.type != AccessTokenType.classic) {
        throw StateError('Phiên Facebook chưa được hỗ trợ trên thiết bị này.');
      }
      _facebookUsed = true;
      return token.tokenString;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          e.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw StateError(
          'Đăng nhập Google hiện chưa sẵn sàng. Bạn có thể dùng email.',
        );
      }
      throw StateError('Không đăng nhập được Google. Vui lòng thử lại.');
    } on PlatformException {
      throw StateError(
        'Không mở được đăng nhập ${provider.label}. Vui lòng thử lại.',
      );
    } on MissingPluginException {
      throw StateError(
        'Đăng nhập ${provider.label} chưa sẵn sàng trên thiết bị này.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    if (_googleInitialization != null) {
      try {
        await _googleInitialization;
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Local app logout must succeed even when a provider is unavailable.
      }
    }
    if (_facebookUsed) {
      _facebookUsed = false;
      try {
        await FacebookAuth.instance.logOut();
      } catch (_) {
        // The application JWT is already cleared by AppState.
      }
    }
  }
}
