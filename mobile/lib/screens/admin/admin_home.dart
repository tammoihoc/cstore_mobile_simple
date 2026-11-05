// Điểm vào quản trị: tải dữ liệu, xử lý thao tác và chọn tab; UI nằm ở widgets/, form ở pages/.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/widgets/common.dart';
import 'package:cstore_mobile/widgets/date_filter.dart';
import 'package:cstore_mobile/widgets/cstore_logo.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_colors.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_ui.dart';
import 'package:cstore_mobile/screens/admin/pages/brand_detail_page.dart';
import 'package:cstore_mobile/screens/admin/pages/create_partner_page.dart';
import 'package:cstore_mobile/screens/admin/pages/create_account_page.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_overview.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_account_filters.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_account_card.dart';

export 'pages/create_partner_page.dart';
export 'pages/create_account_page.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key, required this.state});
  final AppState state;
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  List<Account>? accounts;
  Map<String, dynamic>? revenue;
  String? error;
  int tab = 0;
  Role? filter;
  DateTimeRange? accountDates;
  bool newestFirst = true;
  String search = '';
  bool mutating = false, loading = false, showArchived = false;
  List<Map<String, dynamic>> get brands => adminRows(revenue?['brands']);

  @override
  void initState() {
    super.initState();
    load();
  }

  // Tải tài khoản, chi nhánh rồi số liệu doanh thu; luôn tắt loading trong finally.
  Future<void> load() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final users = await widget.state.api.accounts();
      await widget.state.reloadBranches();
      if (!mounted) return;
      setState(() => accounts = users);
      final data = await widget.state.api.request('/admin/revenue');
      if (data is! Map<String, dynamic>) {
        throw StateError('Chưa tải được thống kê thương hiệu.');
      }
      if (mounted) setState(() => revenue = data);
    } catch (e) {
      if (mounted) {
        setState(() {
          revenue = null;
          error = e is StateError
              ? e.message
              : 'Chưa tải được dữ liệu quản trị. Vui lòng thử lại.';
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> createStore({String? brand}) async {
    final created = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CreatePartner(state: widget.state, initialBrand: brand),
        ));
    if (created == true) {
      await load();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đã tạo thương hiệu / chi nhánh và tài khoản.'),
        ));
      }
    }
  }

  // Hỏi xác nhận trước khi cấm/xóa; máy chủ mới là nơi kiểm tra quyền cuối cùng.
  Future<void> editAccount(Account user, String action) async {
    if (mutating) return;
    if (action == 'avatar') {
      await changeAccountPhoto(user);
      return;
    }
    final remove = action == 'delete', block = !user.blocked;
    final business = remove && user.storeOwner;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
              title: Text(
                business
                    ? 'Xóa cửa hàng và tài khoản?'
                    : remove
                        ? 'Xóa tài khoản ${user.name}?'
                        : '${block ? 'Cấm' : 'Cho phép'} đăng nhập?',
              ),
              content: Text(
                business
                    ? 'Chi nhánh sẽ bị ẩn khỏi bản đồ, danh sách mua hàng và hình thức tạo mới. Tài khoản thuộc chi nhánh bị chặn. Doanh thu và lịch sử đơn được giữ lại.\n\nCần hoàn tất hoặc hủy các đơn đang xử lý trước khi xóa.'
                    : remove
                        ? 'Tài khoản sẽ không thể đăng nhập. Lịch sử đơn và doanh thu được giữ lại.${user.role == Role.store ? '\nĐây là tài khoản nhân viên; cửa hàng vẫn thuộc người quản lý chính.' : ''}'
                        : '${user.email}\n${block ? 'Tài khoản và các phiên hiện tại sẽ bị chặn.' : 'Cho phép tài khoản đăng nhập trở lại nếu chi nhánh còn hoạt động.'}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: Text(
                    business
                        ? 'Xóa cửa hàng'
                        : remove
                            ? 'Xóa tài khoản'
                            : block
                                ? 'Cấm đăng nhập'
                                : 'Cho phép',
                  ),
                )
              ],
            ));
    if (confirmed != true || !mounted) return;
    setState(() => mutating = true);
    await attempt(context, () async {
      await widget.state.api.request(
          '/admin/accounts/${user.id}${remove ? '' : '/status'}',
          method: remove ? 'DELETE' : 'PUT',
          body: remove ? null : {'blocked': block});
      await load();
    });
    if (mounted) setState(() => mutating = false);
  }

  Future<void> changeAccountPhoto(Account user) async {
    try {
      final image = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 88);
      if (image == null || !mounted) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw StateError('Chọn ảnh dưới 5 MB.');
      }
      if (!mounted) return;
      setState(() => mutating = true);
      await widget.state.api.uploadAccountAvatar(user.id, bytes, image.name);
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(e is StateError ? e.message : 'Chưa cập nhật được ảnh.'),
        ));
      }
    } finally {
      if (mounted) setState(() => mutating = false);
    }
  }

  void openBrand(Map<String, dynamic> brand) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (_) => BrandDetailPage(
                brand: brand,
                onAdd: brand['active'] == false
                    ? null
                    : () => createStore(brand: brand['name'] as String),
              )),
    );
  }

  // build chỉ dựng giao diện từ dữ liệu hiện tại; không tự gửi yêu cầu HTTP.
  @override
  Widget build(BuildContext context) {
    final users = (accounts ?? [])
        .where((a) =>
            !a.deleted &&
            inDateRange(a.createdAt, accountDates) &&
            (filter == null || a.role == filter) &&
            '${a.name} ${a.email}'.toLowerCase().contains(search.toLowerCase()))
        .toList()
      ..sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) {
          return b.id.compareTo(a.id);
        }
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        final compared = a.createdAt!.compareTo(b.createdAt!);
        return compared == 0
            ? b.id.compareTo(a.id)
            : newestFirst
                ? -compared
                : compared;
      });
    final visibleBrands = brands
        .where((b) =>
            (showArchived ? b['active'] == false : b['active'] != false) &&
            (b['name'] as String? ?? '')
                .toLowerCase()
                .contains(search.toLowerCase()))
        .toList();
    return Scaffold(
      backgroundColor: adminPaper,
      appBar: AppBar(
        backgroundColor: adminPaper,
        title: const CStoreAppBarTitle(subtitle: 'Admin'),
        actions: [
          IconButton(
            tooltip: 'Làm mới dữ liệu',
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: widget.state.logout,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: adminForest,
        foregroundColor: Colors.white,
        onPressed: tab == 2
            ? () async {
                final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateAccount(state: widget.state),
                    ));
                if (created == true) await load();
              }
            : () => createStore(),
        icon: const Icon(Icons.add_rounded),
        label: Text(tab == 2 ? 'Thêm tài khoản' : 'Tạo thương hiệu'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() {
          tab = i;
          search = '';
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.loyalty_outlined),
            selectedIcon: Icon(Icons.loyalty_rounded),
            label: 'Thương hiệu',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Tài khoản',
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          children: [
            if (loading) const LinearProgressIndicator(minHeight: 2),
            if (error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(error!),
                      TextButton(
                        onPressed: load,
                        child: const Text('Thử lại'),
                      )
                    ],
                  ),
                ),
              ),
            if (tab == 0)
              ...buildAdminOverview(
                revenue: revenue,
                brands: brands,
                onShowAllBrands: () => setState(() => tab = 1),
                onOpenBrand: openBrand,
              ),
            if (tab == 1) ...[
              heading('Mỗi thương hiệu, một câu chuyện',
                  '${revenue?['brandCount'] ?? '—'} thương hiệu đang hoạt động • ${revenue?['branchCount'] ?? '—'} chi nhánh'),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Tìm thương hiệu',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => search = v),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Đang hoạt động'),
                    selected: !showArchived,
                    onSelected: (_) => setState(() => showArchived = false),
                  ),
                  ChoiceChip(
                    label: const Text('Lịch sử đã ngừng'),
                    selected: showArchived,
                    onSelected: (_) => setState(() => showArchived = true),
                  )
                ],
              ),
              const SizedBox(height: 14),
              if (visibleBrands.isEmpty && !loading)
                empty(showArchived
                    ? 'Chưa có thương hiệu đã ngừng hoạt động.'
                    : 'Chưa có thương hiệu phù hợp.'),
              for (final brand in visibleBrands)
                buildAdminBrandCard(brand, onOpenBrand: openBrand),
            ],
            if (tab == 2) ...[
              ...buildAdminAccountFilters(
                accounts: accounts,
                users: users,
                filter: filter,
                accountDates: accountDates,
                newestFirst: newestFirst,
                onRoleChanged: (value) => setState(() => filter = value),
                onSearchChanged: (value) => setState(() => search = value),
                onDatesChanged: (value) => setState(() => accountDates = value),
                onSortChanged: (value) => setState(() => newestFirst = value),
                onReset: () => setState(() {
                  filter = null;
                  accountDates = null;
                }),
              ),
              if (users.isEmpty && accounts != null)
                empty('Chưa có tài khoản phù hợp.'),
              for (final user in users)
                buildAdminAccountCard(
                  user: user,
                  state: widget.state,
                  mutating: mutating,
                  onAction: (action) => editAccount(user, action),
                ),
            ]
          ],
        ),
      ),
    );
  }
}
