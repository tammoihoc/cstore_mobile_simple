// Điều khiển bản đồ, tải tuyến đường và đồng bộ trạng thái giao hàng.

import 'package:flutter/material.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/widgets/common.dart';
import 'package:cstore_mobile/widgets/order_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cstore_mobile/widgets/map_zoom_controls.dart';
import 'package:cstore_mobile/services/location_service.dart';
import 'package:cstore_mobile/screens/shipper/models/delivery_navigation.dart';

export 'models/delivery_navigation.dart';

class ShipperNavigationPage extends StatefulWidget {
  const ShipperNavigationPage(
      {super.key, required this.state, required this.order});
  final AppState state;
  final ShopOrder order;
  @override
  State<ShipperNavigationPage> createState() => _ShipperNavigationPageState();
}

class _ShipperNavigationPageState extends State<ShipperNavigationPage> {
  final mapController = MapController();
  DeliveryNavigation? navigation;
  String? error;
  String signature = '';
  bool loading = false, working = false, mapReady = false, tilesFailed = false;
  int requestId = 0;
  AppState get state => widget.state;
  ShopOrder get order =>
      state.orders.where((o) => o.id == widget.order.id).firstOrNull ??
      state.offers.where((o) => o.id == widget.order.id).firstOrNull ??
      widget.order;

  @override
  void initState() {
    super.initState();
    state.addListener(sync);
    sync();
  }

  @override
  void didUpdateWidget(covariant ShipperNavigationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != state) {
      oldWidget.state.removeListener(sync);
      state.addListener(sync);
    }
    sync();
  }

  @override
  void dispose() {
    requestId++;
    state.removeListener(sync);
    mapController.dispose();
    super.dispose();
  }

  // Chỉ tải tuyến mới khi mã đơn, trạng thái hoặc tọa độ thực sự thay đổi.
  void sync() {
    final next =
        '${order.id}:${order.status.name}:${state.shipperLat.toStringAsFixed(6)}:'
        '${state.shipperLng.toStringAsFixed(6)}:${state.shipperSimulated}';
    if (signature == next) return;
    signature = next;
    load();
  }

  // requestId giúp bỏ qua phản hồi cũ đến muộn sau một yêu cầu mới hơn.
  Future<void> load() async {
    final id = ++requestId;
    setState(() {
      loading = true;
      error = null;
      final toStore =
          [OrderStatus.accepted, OrderStatus.assigned].contains(order.status);
      if (navigation != null && navigation!.toStore != toStore) {
        navigation = null;
      }
    });
    try {
      final json = await state.api.request('/shipper/orders/${order.id}/route')
          as Map<String, dynamic>;
      final result = DeliveryNavigation.fromJson(json);
      if (!mounted || id != requestId) return;
      setState(() {
        navigation = result;
        loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (mounted && id == requestId) fit();
        },
      );
    } catch (e) {
      if (mounted && id == requestId) {
        setState(() {
          navigation = null;
          loading = false;
          error = e is StateError
              ? e.message
              : 'Chưa tải được đường đi. Thử lại hoặc cập nhật GPS.';
        });
      }
    }
  }

  void fit() {
    final nav = navigation;
    if (!mapReady || nav == null) return;
    final points = [
      ...nav.active.points,
      nav.driver,
      nav.store,
      nav.customer,
      if (nav.toStore) ...nav.delivery.points
    ];
    mapController.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: const EdgeInsets.all(54),
      maxZoom: 17,
    ));
  }

  Future<void> useGps() async {
    if (working) return;
    setState(() => working = true);
    await attempt(context, () async {
      final p = await LocationService.current();
      if (!mounted) return;
      await state.setShipperPosition(state.online, p.latitude, p.longitude);
    });
    if (mounted) setState(() => working = false);
  }

  // Mô phỏng phải được xác nhận riêng; GPS thực và tọa độ mô phỏng không bị lẫn.
  Future<void> pickup({bool simulate = false}) async {
    if (working) return;
    if (simulate) {
      final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Mô phỏng nhận hàng tại cửa hàng?'),
                content: const Text(
                  'Đặt vị trí tài xế tại cửa hàng trên bản đồ, nhận hàng và xem đường giao đến khách.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Hủy'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Xác nhận mô phỏng'),
                  )
                ],
              ));
      if (confirm != true || !mounted) return;
    }
    setState(() => working = true);
    await attempt(
        context,
        () => state.transition(order, OrderStatus.pickedUp, Role.shipper,
            simulateArrival: simulate));
    if (mounted) setState(() => working = false);
  }

  Marker marker(LatLng point, String label, IconData icon, Color color) =>
      Marker(
        point: point,
        width: 116,
        height: 74,
        child: Tooltip(
          message: label,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8)
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final nav = navigation;
    final branch =
        state.branchList.where((b) => b.id == order.branchId).firstOrNull;
    final storePoint = nav?.store ??
        LatLng(branch?.lat ?? order.lat, branch?.lng ?? order.lng);
    final customerPoint = nav?.customer ?? LatLng(order.lat, order.lng);
    final driverPoint =
        nav?.driver ?? LatLng(state.shipperLat, state.shipperLng);
    final assigned = order.status == OrderStatus.assigned &&
        order.shipperId == state.shipperId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ giao hàng'),
        actions: [
          IconButton(
            tooltip: 'Dùng GPS Android',
            onPressed: working ? null : useGps,
            icon: const Icon(Icons.my_location_rounded),
          ),
          IconButton(
            tooltip: 'Tải lại đường đi',
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh_rounded),
          )
        ],
      ),
      body: Column(
        children: [
          if (loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: storePoint,
                    initialZoom: 15,
                    minZoom: 3,
                    maxZoom: 19,
                    interactionOptions:
                        const InteractionOptions(flags: InteractiveFlag.all),
                    onMapReady: () {
                      setState(() => mapReady = true);
                      fit();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: const String.fromEnvironment(
                        'MAP_TILE_URL',
                        defaultValue:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      userAgentPackageName: 'com.cstore.mobile.simple',
                      maxNativeZoom: 19,
                      panBuffer: 0,
                      errorTileCallback: (_, error, stack) {
                        if (tilesFailed) return;
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) {
                            if (mounted && !tilesFailed) {
                              setState(() => tilesFailed = true);
                            }
                          },
                        );
                      },
                    ),
                    if (nav != null)
                      PolylineLayer(
                        polylines: [
                          if (nav.toStore)
                            Polyline(
                              points: nav.delivery.points,
                              strokeWidth: 4,
                              color: const Color(0xFF8CABA0),
                            ),
                          Polyline(
                            points: nav.active.points,
                            strokeWidth: 6,
                            color: forest,
                            borderStrokeWidth: 2,
                            borderColor: Colors.white,
                          )
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        marker(storePoint, 'Cửa hàng', Icons.storefront_rounded,
                            forest),
                        marker(customerPoint, 'Khách hàng', Icons.home_rounded,
                            orange),
                        if (state.shipperLat != 0 ||
                            state.shipperLng != 0 ||
                            nav != null)
                          marker(
                              driverPoint,
                              'Tài xế',
                              Icons.delivery_dining_rounded,
                              const Color(0xFF3E6DAD))
                      ],
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Material(
                        color: Colors.white,
                        child: InkWell(
                          onTap: () => launchUrl(Uri.parse(
                            'https://www.openstreetmap.org/copyright',
                          )),
                          child: const Padding(
                            padding: EdgeInsets.all(5),
                            child: Text(
                              '© OpenStreetMap contributors',
                              style: TextStyle(fontSize: 9),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: MapZoomControls(
                    controller: mapController,
                    ready: mapReady,
                    onFit: fit,
                  ),
                ),
                if (nav != null)
                  Positioned(
                    left: 12,
                    right: 72,
                    top: 12,
                    child: Material(
                      key: const ValueKey('navigation-route-ready'),
                      color: forest,
                      borderRadius: BorderRadius.circular(18),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nav.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${nav.active.distanceLabel} · ${nav.active.durationLabel}',
                              style: const TextStyle(
                                color: Color(0xFFCEE5BD),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'Thời gian di chuyển ước tính',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                if (tilesFailed)
                  const Positioned(
                    left: 12,
                    right: 12,
                    bottom: 32,
                    child: Material(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'Chưa tải được nền bản đồ. Tuyến đường và số km vẫn được hiển thị.',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  )
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .45,
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (error != null) ...[
                      Text(
                        error!,
                        style: const TextStyle(color: Color(0xFF9F4940)),
                      ),
                      TextButton(
                        onPressed: loading ? null : load,
                        child: const Text('Thử tải lại đường đi'),
                      )
                    ],
                    if (nav == null && loading)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Đang tìm đường đi…',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (nav != null) ...[
                      if (nav.simulated)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EAF8),
                            borderRadius: BorderRadius.circular(14),
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
                                  'Đang mô phỏng vị trí tài xế. Nhấn GPS để dùng vị trí Android thực tế.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF79529B),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      legRow('Tài xế → Cửa hàng', nav.pickup,
                          done: !nav.toStore),
                      const SizedBox(height: 8),
                      legRow(
                          nav.toStore
                              ? 'Cửa hàng → Khách hàng'
                              : 'Tài xế → Khách hàng',
                          nav.delivery,
                          highlighted: !nav.toStore),
                      const SizedBox(height: 10),
                      const Text(
                        'Tuyến ngắn nhất trong các phương án tìm được.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text(
                          'Hướng dẫn đường đi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        children: [
                          for (final step in nav.active.steps)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: Icon(step.icon, color: forest),
                              title: Text(step.instruction),
                              subtitle: step.distanceMeters > 0
                                  ? Text(
                                      step.distanceMeters < 1000
                                          ? '${step.distanceMeters.round()} m'
                                          : '${(step.distanceMeters / 1000).toStringAsFixed(1)} km',
                                    )
                                  : null,
                            )
                        ],
                      ),
                    ],
                    if (assigned) ...[
                      OutlinedButton.icon(
                        onPressed: working ? null : () => pickup(),
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text('Đã lấy hàng'),
                      ),
                      TextButton.icon(
                        onPressed:
                            working ? null : () => pickup(simulate: true),
                        icon: const Icon(Icons.science_outlined),
                        label: const Text(
                          'Mô phỏng đã tới cửa hàng và nhận hàng',
                          textAlign: TextAlign.center,
                        ),
                      )
                    ],
                    if (working) const LinearProgressIndicator(minHeight: 2),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget legRow(String title, RoadLeg? leg,
          {bool done = false, bool highlighted = false}) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFFEAF2EC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.route_rounded,
              color: forest,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (done)
                    const Text(
                      'Đã nhận hàng',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    )
                ],
              ),
            ),
            if (!done && leg != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    leg.distanceLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: forest,
                    ),
                  ),
                  Text(
                    leg.durationLabel,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  )
                ],
              )
          ],
        ),
      );
}
