import 'package:flutter/material.dart';

import '../models/models.dart';
import '../screens/admin/admin_home.dart';
import '../screens/auth/welcome.dart';
import '../screens/customer/customer_home.dart';
import '../screens/shipper/shipper_home.dart';
import '../screens/store/store_home.dart';
import '../services/app_state.dart';

/// Đổi màn hình theo phiên và vai trò backend trả về sau đăng nhập.
/// Đây là điều hướng giao diện; backend vẫn kiểm tra quyền ở mỗi API.
class RoleHome extends StatelessWidget {
  const RoleHome({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final account = state.account;
        if (account == null) return LoginPage(state: state);

        return switch (account.role) {
          Role.customer => CustomerHome(state: state),
          Role.store => StoreHome(state: state),
          Role.shipper => ShipperHome(state: state),
          Role.admin => AdminHome(state: state),
        };
      },
    );
  }
}
