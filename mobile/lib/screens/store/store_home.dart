// Điểm vào cửa hàng: giữ tab/bộ lọc và chuyển sự kiện cho từng khối giao diện.

import 'package:flutter/material.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/widgets/date_filter.dart';
import 'package:cstore_mobile/widgets/cstore_logo.dart';
import 'package:cstore_mobile/widgets/sync_status.dart';
import 'package:cstore_mobile/screens/store/widgets/store_styles.dart';
import 'package:cstore_mobile/screens/store/widgets/store_dashboard.dart';
import 'package:cstore_mobile/screens/store/widgets/store_inventory.dart';
import 'package:cstore_mobile/screens/store/widgets/store_branch_details.dart';
import 'package:cstore_mobile/screens/orders.dart';
import 'package:cstore_mobile/screens/profile/profile_page.dart';
import 'package:cstore_mobile/screens/store/product_editor.dart';

class StoreHome extends StatefulWidget {
  const StoreHome({super.key, required this.state});
  final AppState state;
  @override
  State<StoreHome> createState() => _StoreHomeState();
}

class _StoreHomeState extends State<StoreHome> {
  int tab = 0;
  DateTimeRange? reportDates =
      DateFilterBar.presets(DateTime.now())['Tháng này'];
  String search = '', stockFilter = 'Tất cả', category = 'Tất cả danh mục';
  AppState get s => widget.state;
  Future<void> editProduct([Product? product]) => Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => ProductEditor(state: s, product: product)),
      );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: s,
        builder: (context, _) => Scaffold(
          backgroundColor: storePaper,
          appBar: AppBar(
            backgroundColor: storePaper,
            title: const CStoreAppBarTitle(subtitle: 'Cửa hàng'),
            actions: [
              IconButton(
                tooltip: 'Làm mới dữ liệu',
                onPressed: s.loading ? null : s.reload,
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: 'Đăng xuất',
                onPressed: s.logout,
                icon: const Icon(Icons.logout),
              )
            ],
          ),
          body: SafeArea(
            child: SyncStatus(
              state: s,
              child: tab == 0
                  ? buildStoreDashboard(
                      state: s,
                      reportDates: reportDates,
                      onReportDatesChanged: (value) =>
                          setState(() => reportDates = value),
                      onOrdersTap: () => setState(() => tab = 2),
                      onInventoryTap: () => setState(() => tab = 1),
                    )
                  : tab == 1
                      ? buildStoreInventory(
                          state: s,
                          search: search,
                          stockFilter: stockFilter,
                          category: category,
                          onSearchChanged: (value) =>
                              setState(() => search = value),
                          onCategoryChanged: (value) =>
                              setState(() => category = value),
                          onStockFilterChanged: (value) =>
                              setState(() => stockFilter = value),
                          onEdit: editProduct,
                        )
                      : tab == 2
                          ? OrderList(state: s, role: Role.store)
                          : buildStoreBranchDetails(
                              state: s,
                              onChangePassword: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                    builder: (_) =>
                                        ChangePasswordPage(state: s)),
                              ),
                            ),
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard_rounded),
                label: 'Tổng quan',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2_rounded),
                label: 'Sản phẩm',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Đơn hàng',
              ),
              NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront_rounded),
                label: 'Chi nhánh',
              )
            ],
          ),
        ),
      );
}
