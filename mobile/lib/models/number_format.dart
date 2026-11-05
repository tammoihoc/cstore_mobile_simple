import 'dart:math';

/// Các hàm thuần: định dạng tiền và tính khoảng cách Haversine.
/// Haversine là đường chim bay; báo giá giao hàng lấy đường bộ từ backend.
String money(int amountInDong) {
  final formatted = amountInDong.toString().replaceAllMapped(
        RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
  return '$formattedđ';
}

double distance(
  double startLatitude,
  double startLongitude,
  double endLatitude,
  double endLongitude,
) {
  double toRadians(double degrees) => degrees * pi / 180;
  final haversineValue = pow(
        sin(toRadians(endLatitude - startLatitude) / 2),
        2,
      ) +
      cos(toRadians(startLatitude)) *
          cos(toRadians(endLatitude)) *
          pow(
            sin(toRadians(endLongitude - startLongitude) / 2),
            2,
          );
  return 6371 *
      2 *
      asin(sqrt(haversineValue.clamp(
        0,
        1,
      )));
}
