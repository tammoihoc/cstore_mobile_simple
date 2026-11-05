import '../../widgets/sync_status.dart';
import '../../widgets/order_widgets.dart';
import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../orders.dart';
import '../../services/location_service.dart';
import 'navigation_route.dart';
import '../profile/profile_page.dart';
import '../../widgets/account_avatar.dart';
import '../../widgets/cstore_logo.dart';

class ShipperHome extends StatefulWidget {
  const ShipperHome({super.key, required this.state});
  final AppState state;
  @override
  State<ShipperHome> createState() => _ShipperHomeState();
}

class _ShipperHomeState extends State<ShipperHome> {
  int tab = 0;
  bool locating = false;

  Future<void> updatePosition({bool? online}) async {
    if (locating) return;
    if (online != false && widget.state.account?.photoRequired == true) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => ProfilePage(state: widget.state)),
      );
      return;
    }
    setState(() => locating = true);
    await attempt(context, () async {
      final s = widget.state;
      if (online == false) {
        await s.setShipperPosition(false, s.shipperLat, s.shipperLng,
            preserveSimulation: true);
      } else {
        final p = await LocationService.current();
        await s.setShipperPosition(online ?? s.online, p.latitude, p.longitude);
      }
    });
    if (mounted) setState(() => locating = false);
  }

  Widget preview(ShopOrder o) {
    final s = widget.state;
    final branch = s.branchList.where((b) => b.id == o.branchId).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrderPreview(
          order: o,
          branchName: branch?.name ?? 'Chi nhánh #${o.branchId}',
          delivery: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
                builder: (_) =>
                    OrderDetail(state: s, order: o, role: Role.shipper)),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (_) => ShipperNavigationPage(state: s, order: o)),
            ),
            icon: const Icon(Icons.map_outlined, size: 18),
            label: Text(
              [OrderStatus.accepted, OrderStatus.assigned].contains(o.status)
                  ? 'Xem đường đến cửa hàng'
                  : 'Xem đường giao đến khách',
            ),
          ),
        ),
        const SizedBox(height: 8)
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) {
          final s = widget.state;
          final completed = s.deliveries
              .where((o) => o.status == OrderStatus.delivered && o.paid)
              .toList();
          final active = s.deliveries.where((o) => o.activeDelivery).toList();
          return Scaffold(
            appBar: AppBar(
              title: const CStoreAppBarTitle(subtitle: 'Shipper'),
              actions: [
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
                    ? RefreshIndicator(
                        onRefresh: s.reload,
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            Row(
                              children: [
                                AccountAvatar(account: s.account, size: 66),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: heading(
                                      'Chào ${s.account?.name ?? 'bạn'}',
                                      'Sẵn sàng cho chuyến giao tiếp theo'),
                                )
                              ],
                            ),
                            if (s.account?.photoRequired == true)
                              Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEEE3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Thêm ảnh đại diện để nhận đơn',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: forest,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    const Text(
                                      'Khách cần nhìn thấy ảnh của người giao hàng.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                            builder: (_) => ProfilePage(
                                                  state: s,
                                                )),
                                      ),
                                      icon: const Icon(
                                        Icons.add_a_photo_outlined,
                                      ),
                                      label: const Text(
                                        'Hoàn thiện hồ sơ shipper',
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: forest,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.delivery_dining_rounded,
                                        color: Color(0xFFCCE2BB),
                                        size: 34,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s.online
                                                  ? 'Đang trực tuyến'
                                                  : 'Đang ngoại tuyến',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 19,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const Text(
                                              'Đường đi đến cửa hàng trong 5 km',
                                              style: TextStyle(
                                                color: Colors.white60,
                                                fontSize: 11,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: s.online,
                                        activeThumbColor:
                                            const Color(0xFFCCE2BB),
                                        onChanged: locating
                                            ? null
                                            : (v) => updatePosition(online: v),
                                      )
                                    ],
                                  ),
                                  const Divider(
                                    color: Colors.white24,
                                    height: 28,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${active.length}/3 đơn',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 23,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const Text(
                                              'Đang giao',
                                              style: TextStyle(
                                                color: Colors.white60,
                                                fontSize: 11,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${completed.length}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 23,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const Text(
                                              'Đã hoàn tất',
                                              style: TextStyle(
                                                color: Colors.white60,
                                                fontSize: 11,
                                              ),
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed:
                                  locating ? null : () => updatePosition(),
                              icon: locating
                                  ? const SizedBox(
                                      width: 17,
                                      height: 17,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.my_location_outlined,
                                      size: 18,
                                    ),
                              label: Text(
                                locating
                                    ? 'Đang lấy vị trí…'
                                    : 'Cập nhật GPS Android',
                              ),
                            ),
                            if (s.shipperSimulated)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0EAF8),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.science_outlined,
                                      color: Color(0xFF79529B),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Đang dùng vị trí mô phỏng. Cập nhật GPS Android để trở về vị trí thực tế.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF79529B),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            heading('Đề nghị giao hàng',
                                'Ảnh món hàng, điểm lấy và tiền cần thu trong chi tiết đơn'),
                            if (s.offers.isEmpty)
                              empty(s.online
                                  ? 'Chưa có đơn phù hợp trong khu vực. Đơn mới sẽ xuất hiện tại đây.'
                                  : 'Bật trực tuyến để xem đơn'),
                            for (final o in s.offers) preview(o)
                          ],
                        ),
                      )
                    : tab == 1
                        ? ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              heading('Lộ trình của bạn',
                                  '${active.length}/3 đơn đang giao'),
                              Container(
                                margin: const EdgeInsets.only(bottom: 18),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF2EC),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.route_outlined,
                                      color: forest,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Kiểm tra đúng món, thu đủ COD rồi xác nhận giao thành công.',
                                        style: TextStyle(
                                          color: forest,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              if (active.isEmpty) empty('Chưa nhận đơn giao'),
                              for (final o in active) preview(o)
                            ],
                          )
                        : tab == 2
                            ? OrderList(state: s, role: Role.shipper)
                            : ProfilePage(state: s, embedded: true),
              ),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (i) => setState(() => tab = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.radar),
                  label: 'Đơn gần',
                ),
                NavigationDestination(
                  icon: Icon(Icons.route),
                  label: 'Đang giao',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history),
                  label: 'Lịch sử',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Hồ sơ',
                )
              ],
            ),
          );
        },
      );
}
