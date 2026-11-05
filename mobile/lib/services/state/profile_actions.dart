part of 'app_state.dart';

/// Thông tin cá nhân; bỏ kết quả cũ nếu người dùng đã đăng xuất.
/// `app` là cùng một AppState đang được giao diện lắng nghe.
class _ProfileActions {
  _ProfileActions(this.app);

  final AppState app;

  Future<void> refreshProfile() async {
    final id = app.account?.id;
    if (id == null) return;
    final loaded = await app.api.profile();
    if (app.account?.id == id) {
      app.account = loaded;
      app.refresh();
    }
  }

  Future<void> updateProfile(
    String name,
    String phone,
    String gender,
  ) async {
    // Ghi lại phiên lúc bắt đầu: phản hồi cũ không được khôi phục tài khoản đã logout.
    final epoch = app._accountEpoch;
    final loaded = await app.api.updateProfile(
      name,
      phone,
      gender,
    );
    if (epoch != app._accountEpoch) return;
    app.account = loaded;
    app.refresh();
  }

  Future<void> uploadAvatar(
    List<int> bytes,
    String name,
  ) async {
    // Ghi lại phiên lúc bắt đầu: phản hồi cũ không được khôi phục tài khoản đã logout.
    final epoch = app._accountEpoch;
    final loaded = await app.api.uploadAvatar(
      bytes,
      name,
    );
    if (epoch != app._accountEpoch) return;
    app.account = loaded;
    app.refresh();
  }

  Future<void> removeAvatar() async {
    // Ghi lại phiên lúc bắt đầu: phản hồi cũ không được khôi phục tài khoản đã logout.
    final epoch = app._accountEpoch;
    final loaded = await app.api.removeAvatar();
    if (epoch != app._accountEpoch) return;
    app.account = loaded;
    app.refresh();
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    // Ghi lại phiên lúc bắt đầu: phản hồi cũ không được khôi phục tài khoản đã logout.
    final epoch = app._accountEpoch;
    final loaded = await app.api.changePassword(
      currentPassword,
      newPassword,
    );
    if (epoch != app._accountEpoch) return;
    app.account = loaded;
    app.refresh();
  }
}
