import 'package:flutter/material.dart';

import '../services/app_state.dart';
import 'role_home.dart';
import 'theme/app_theme.dart';

/// Gốc của cây widget. Một AppState được dùng chung cho phiên ứng dụng.
class CStoreApp extends StatefulWidget {
  const CStoreApp({super.key, this.state});

  // Test có thể truyền AppState dùng API giả; app thật tự tạo AppState.
  final AppState? state;

  @override
  State<CStoreApp> createState() => _CStoreAppState();
}

class _CStoreAppState extends State<CStoreApp> {
  late final state = widget.state ?? AppState();

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'C-Store Mobile',
      debugShowCheckedModeBanner: false,
      // Kéo quá mép không làm giãn ảnh hoặc các thẻ nội dung.
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        overscroll: false,
        physics: const ClampingScrollPhysics(),
      ),
      theme: buildAppTheme(),
      home: RoleHome(state: state),
    );
  }
}
