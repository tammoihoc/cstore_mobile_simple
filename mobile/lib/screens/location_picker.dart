import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/location_service.dart';
import '../services/geocoding_service.dart';
import '../widgets/product_image.dart';
import '../widgets/map_zoom_controls.dart';

class PinnedLocation {
  const PinnedLocation(this.address, this.lat, this.lng);
  final String address;
  final double lat, lng;
}

class LocationPicker extends StatefulWidget {
  const LocationPicker(
      {super.key,
      required this.title,
      required this.lat,
      required this.lng,
      this.address = '',
      this.initialPinConfirmed = false,
      this.branches = const [],
      this.geocodingService});
  final String title, address;
  final double lat, lng;
  final bool initialPinConfirmed;
  final List<Branch> branches;
  final GeocodingService? geocodingService;
  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late final geocodingService = widget.geocodingService ?? GeocodingService();
  final mapController = MapController();
  late final addressController = TextEditingController(
    text: widget.initialPinConfirmed ? widget.address : '',
  );
  LatLng? pin;
  bool locating = false, geocoding = false, tileError = false;
  bool mapReady = false;
  bool addressEdited = false;
  double? accuracy;
  String? gpsError, addressHint;
  int revision = 0, geocodeRevision = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialPinConfirmed) {
      pin = LatLng(widget.lat, widget.lng);
    }
  }

  @override
  void dispose() {
    geocodeRevision++;
    mapController.dispose();
    addressController.dispose();
    if (widget.geocodingService == null) geocodingService.dispose();
    super.dispose();
  }

  bool get canConfirm =>
      pin != null &&
      addressController.text.trim().isNotEmpty &&
      (!geocoding || addressEdited);

  // Ghim mới có mã yêu cầu mới; phản hồi tìm địa chỉ cho ghim cũ sẽ bị bỏ qua.
  Future<void> choose(LatLng point, {double? gpsAccuracy}) async {
    final requestId = ++geocodeRevision;
    setState(() {
      pin = point;
      accuracy = gpsAccuracy;
      geocoding = true;
      addressEdited = false;
      addressController.clear();
      addressHint = null;
    });
    final result =
        await geocodingService.reverse(point.latitude, point.longitude);
    if (!mounted || requestId != geocodeRevision) return;
    setState(() {
      geocoding = false;
      if (!addressEdited) addressController.text = result ?? '';
      if (result == null) {
        addressHint = 'Chưa tìm được địa chỉ. Nhập số nhà, tên đường bên dưới.';
      }
    });
  }

  Future<void> gps() async {
    setState(() {
      locating = true;
      gpsError = null;
    });
    try {
      final position = await LocationService.current();
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      mapController.move(point, 17);
      await choose(point, gpsAccuracy: position.accuracy);
    } catch (e) {
      if (mounted) {
        setState(() => gpsError = e is StateError
            ? e.message
            : 'Chưa lấy được GPS. Thử lại hoặc chọn điểm trên bản đồ.');
      }
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  void tilesFailed() {
    if (tileError) return;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (mounted) setState(() => tileError = true);
      },
    );
  }

  void showBranch(Branch branch) {
    showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ProductImage(
                        path: branch.image,
                        width: 74,
                        height: 74,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branch.brand ?? 'Cửa hàng',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          Text(
                            branch.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(branch.address),
                          const SizedBox(height: 6),
                          Text(
                            branch.open ? 'Đang mở cửa' : 'Đã đóng cửa',
                            style: const TextStyle(color: Color(0xFF214E3E)),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              tooltip: 'Lấy vị trí GPS',
              onPressed: locating ? null : gps,
              icon: locating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: widget.lat == 0 && widget.lng == 0
                          ? const LatLng(10.7731, 106.7030)
                          : LatLng(widget.lat, widget.lng),
                      initialZoom: 16,
                      minZoom: 3,
                      maxZoom: 19,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onMapReady: () {
                        if (mounted) setState(() => mapReady = true);
                      },
                      onTap: (_, point) => choose(point),
                    ),
                    children: [
                      TileLayer(
                        key: ValueKey(revision),
                        urlTemplate: const String.fromEnvironment(
                          'MAP_TILE_URL',
                          defaultValue:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        ),
                        userAgentPackageName: 'com.cstore.mobile.simple',
                        maxNativeZoom: 19,
                        panBuffer: 0,
                        errorTileCallback: (_, error, stack) => tilesFailed(),
                      ),
                      MarkerLayer(
                        markers: [
                          for (final branch in widget.branches)
                            Marker(
                              point: LatLng(branch.lat, branch.lng),
                              width: 110,
                              height: 64,
                              child: GestureDetector(
                                onTap: () => showBranch(branch),
                                child: Tooltip(
                                  message: branch.name,
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: branch.open
                                              ? const Color(0xFF214E3E)
                                              : Colors.grey,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.storefront_rounded,
                                          color: Colors.white,
                                          size: 23,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          branch.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (pin != null)
                            Marker(
                              point: pin!,
                              width: 48,
                              height: 56,
                              alignment: Alignment.topCenter,
                              child: const Icon(
                                Icons.location_pin,
                                size: 48,
                                color: Color(0xFFED6A2C),
                              ),
                            )
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Material(
                          color: Colors.white.withValues(alpha: .95),
                          child: InkWell(
                            onTap: () => launchUrl(Uri.parse(
                              'https://www.openstreetmap.org/copyright',
                            )),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                '© OpenStreetMap contributors',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF214E3E),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  Positioned(
                    right: 12,
                    bottom: 28,
                    child: MapZoomControls(
                        controller: mapController, ready: mapReady),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.storefront_rounded,
                              color: Color(0xFF214E3E),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tileError
                                    ? 'Chưa tải được nền bản đồ. Có thể dùng GPS hoặc ghim trực tiếp.'
                                    : '${widget.branches.length} cửa hàng • Chạm biểu tượng để xem',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            if (tileError)
                              TextButton(
                                onPressed: () => setState(() {
                                  tileError = false;
                                  revision++;
                                }),
                                child: const Text('Thử lại'),
                              )
                          ],
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
                  maxHeight: MediaQuery.sizeOf(context).height * .46,
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (gpsError != null)
                        Text(
                          gpsError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      if (pin == null)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.touch_app_outlined,
                                color: Color(0xFFED6A2C),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Chạm vào bản đồ để ghim vị trí chính xác',
                                  style: TextStyle(fontSize: 13),
                                ),
                              )
                            ],
                          ),
                        ),
                      if (pin != null) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Color(0xFFED6A2C),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                accuracy != null
                                    ? 'Vị trí Android • Độ chính xác ±${accuracy!.toStringAsFixed(0)} m'
                                    : 'Điểm giao hàng đã ghim',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (geocoding)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: addressController,
                          maxLines: 2,
                          minLines: 1,
                          decoration: InputDecoration(
                            labelText: 'Địa chỉ giao hàng',
                            hintText: 'Số nhà, tên đường, phường / xã',
                            helperText: addressHint ??
                                'Kiểm tra và bổ sung số nhà, tên đường cho đúng.',
                          ),
                          onChanged: (_) =>
                              setState(() => addressEdited = true),
                        ),
                        const SizedBox(height: 10),
                      ],
                      FilledButton(
                        onPressed: canConfirm
                            ? () => Navigator.pop(
                                  context,
                                  PinnedLocation(
                                    addressController.text.trim(),
                                    pin!.latitude,
                                    pin!.longitude,
                                  ),
                                )
                            : null,
                        child: const Text('Xác nhận vị trí đã ghim'),
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      );
}
