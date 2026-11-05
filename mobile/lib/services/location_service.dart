import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static Future<Position> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError(
        'GPS đang tắt. Bật vị trí trong cài đặt hoặc chọn trên bản đồ.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw StateError('Bạn chưa cấp quyền vị trí. Có thể chọn trên bản đồ.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'Quyền vị trí đã bị chặn. Mở cài đặt ứng dụng để cấp quyền.',
      );
    }
    return Geolocator.getCurrentPosition(
      locationSettings: defaultTargetPlatform == TargetPlatform.android
          ? AndroidSettings(
              forceLocationManager: true,
              accuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 20),
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 20),
            ),
    );
  }
}
