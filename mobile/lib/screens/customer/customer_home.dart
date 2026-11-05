import '../../widgets/sync_status.dart';
import '../../widgets/product_image.dart';
import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../orders.dart';
import 'shop_page.dart';
import '../location_picker.dart';
import '../profile/profile_page.dart';
import '../../widgets/account_avatar.dart';
import '../../widgets/cstore_logo.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key, required this.state});
  final AppState state;
  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: const CStoreAppBarTitle(),
            actions: [
              IconButton(
                tooltip: 'Hồ sơ của tôi',
                onPressed: () => setState(() => tab = 2),
                icon: AccountAvatar(account: widget.state.account, size: 34),
              ),
              IconButton(
                tooltip: 'Đăng xuất',
                onPressed: () {
                  widget.state.select(null);
                  widget.state.logout();
                },
                icon: const Icon(Icons.logout),
              )
            ],
          ),
          body: SafeArea(
            child: SyncStatus(
              state: widget.state,
              child: tab == 0
                  ? home()
                  : tab == 1
                      ? OrderList(state: widget.state, role: Role.customer)
                      : ProfilePage(
                          state: widget.state,
                          embedded: true,
                          onLocation: location,
                        ),
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.storefront),
                label: 'Cửa hàng',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long),
                label: 'Đơn hàng',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'Hồ sơ',
              )
            ],
          ),
        ),
      );
  Widget home() {
    final s = widget.state;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
      children: [
        InkWell(
          onTap: location,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEE3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.near_me_outlined,
                    color: orange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GIAO ĐẾN',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.8,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        s.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      )
                    ],
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded)
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Chào ${s.account?.name ?? 'bạn'} 👋',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 4),
        const Text(
          'Hôm nay, mua gì nhỉ?',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 168,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF214E3E),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12,
                top: 18,
                child: Transform.rotate(
                  angle: .15,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/images/orange.webp',
                      width: 144,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 20,
                top: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TƯƠI NGON MỖI NGÀY',
                      style: TextStyle(
                        color: Color(0xFFC9DDAC),
                        fontSize: 10,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Đủ món ngon,\ntrọn ngày vui.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Chọn cửa hàng gần bạn →',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Cửa hàng gần bạn',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Đường đi ≤ 10 km',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            )
          ],
        ),
        const SizedBox(height: 12),
        if (s.nearbyLoading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (s.nearbyError != null)
          Column(
            children: [
              Text(s.nearbyError!),
              TextButton(
                onPressed: s.loadNearby,
                child: const Text('Thử lại tuyến đường'),
              )
            ],
          )
        else if (s.nearby.isEmpty)
          empty(s.positionKnown
              ? 'Chưa có cửa hàng trong phạm vi 10 km đường đi. Bạn có thể xem các chi nhánh trên bản đồ.'
              : 'Chọn điểm giao hàng để khám phá cửa hàng gần bạn.'),
        for (final b in s.nearby)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: b.open
                    ? () {
                        s.select(b);
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                              builder: (_) => ShopPage(state: s)),
                        );
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 68,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4EE),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ProductImage(
                          path: b.image,
                          width: 68,
                          height: 76,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.brand ?? 'Cửa hàng độc lập',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              b.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              b.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Wrap(
                              spacing: 12,
                              runSpacing: 5,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 6,
                                      color: b.open
                                          ? const Color(0xFF43856B)
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      b.open ? 'Đang mở cửa' : 'Đã đóng',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF43856B),
                                      ),
                                    )
                                  ],
                                ),
                                Text(
                                  '${s.nearbyQuotes[b.id]!.distanceKm.toStringAsFixed(1)} km đường đi',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
      ],
    );
  }

  Future<void> location() async {
    final s = widget.state;
    final p = await Navigator.push<PinnedLocation>(
        context,
        MaterialPageRoute(
          builder: (_) => LocationPicker(
            title: 'Chọn điểm giao hàng',
            lat: s.lat,
            lng: s.lng,
            address: s.positionKnown ? s.location : '',
            initialPinConfirmed: s.positionKnown,
            branches: s.branchList,
          ),
        ));
    if (p != null) {
      if (mounted) {
        await attempt(context, () => s.setLocation(p.address, p.lat, p.lng));
      }
    }
  }
}
