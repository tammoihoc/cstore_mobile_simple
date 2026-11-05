part of 'app_state.dart';

/// Đăng nhập, đăng ký, nạp phiên và xóa dữ liệu khi đăng xuất.
/// `app` là cùng một AppState đang được giao diện lắng nghe.
class _SessionActions {
  _SessionActions(this.app);

  final AppState app;

  Future<void> login(
    String email,
    String password,
  ) async {
    try {
      app.account = await app.api.login(
        email.trim(),
        password,
      );
      await app._loadSession();
    } catch (e) {
      app.logout();
      rethrow;
    }
  }

  Future<bool> loginSocial(SocialProvider provider) async {
    if (app._socialLoginPending) return false;
    if (!app.socialSignIn.isConfigured(provider)) {
      throw StateError(
        'Đăng nhập ${provider.label} chưa được bật. Bạn có thể dùng email.',
      );
    }
    app._socialLoginPending = true;
    try {
      final providers = await app.api.socialProviders();
      if (providers[provider.name] != true) {
        throw StateError(
          'Đăng nhập ${provider.label} hiện chưa sẵn sàng. Bạn có thể dùng email.',
        );
      }
      final token = await app.socialSignIn.authenticate(provider);
      if (token == null) return false;
      app.account = await app.api.socialLogin(
        provider.name,
        token,
      );
      await app._loadSession();
      return true;
    } catch (_) {
      app.logout();
      rethrow;
    } finally {
      app._socialLoginPending = false;
    }
  }

  Future<void> _loadSession() async {
    await app.reloadBranches();
    if (app.account!.role == Role.customer) {
      final saved = await app.api.request('/customer/location');
      if (saved is Map<String, dynamic> && saved['pinConfirmed'] == true) {
        final a = (saved['latitude'] as num?)?.toDouble();
        final b = (saved['longitude'] as num?)?.toDouble();
        final address = saved['address'] as String? ?? '';
        if (a != null &&
            b != null &&
            app.validCoordinates(
              a,
              b,
            ) &&
            address.trim().isNotEmpty) {
          app._applyLocation(
            address,
            a,
            b,
          );
          unawaited(app.loadNearby());
        }
      }
    }
    if (app.account!.role == Role.store &&
        !app.branchList.any((b) => b.id == app.storeBranchId)) {
      throw StateError('Chi nhánh chưa được xác nhận vị trí.');
    }
    await app.reload();
    app.timer?.cancel();
    // Polling: hỏi lại server mỗi 10 giây, không chạy chồng khi đang tải.
    app.timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        if (!app.loading && app.account != null) app.reload();
      },
    );
  }

  Future<void> register(
    String name,
    String email,
    String password,
    Role role,
  ) async {
    await app.api.request(
      '/auth/register',
      body: {
        'fullName': name,
        'email': email.trim(),
        'password': password,
        'role': role.name.toUpperCase()
      },
    );
    await app.login(
      email,
      password,
    );
  }

  void logout() {
    // Tăng mã phiên/lần tải để các thao tác có kiểm tra bỏ kết quả cũ.
    app._accountEpoch++;
    app._productsRevision++;
    app.timer?.cancel();
    app.timer = null;
    app.api.token = null;
    app.account = null;
    app.online = false;
    app.selected = null;
    app.products.clear();
    app.orders.clear();
    app._offers.clear();
    app.cart.clear();
    app.lat = 0;
    app.lng = 0;
    app.location = 'Chọn vị trí giao hàng';
    app.positionKnown = false;
    app.shipperLat = 0;
    app.shipperLng = 0;
    app.shipperSimulated = false;
    app._nearbyRevision++;
    app.nearbyQuotes.clear();
    app.nearbyLoading = false;
    app.nearbyError = null;
    app.error = null;
    unawaited(app.socialSignIn.signOut().catchError((Object _) {}));
    app.refresh();
  }
}
