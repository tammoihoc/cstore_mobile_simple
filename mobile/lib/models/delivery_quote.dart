/// Báo giá đường bộ do backend tính; ứng dụng chỉ đọc và kiểm tra dữ liệu trả về.
class DeliveryQuote {
  const DeliveryQuote(
    this.storeId,
    this.distanceKm,
    this.durationSeconds,
    this.fee,
  );
  final int storeId;
  final int fee;
  final double distanceKm;
  final double durationSeconds;
  factory DeliveryQuote.fromJson(
    Map<String, dynamic> json,
  ) {
    final result = DeliveryQuote(
      (json['storeId'] as num).toInt(),
      (json['distanceKm'] as num).toDouble(),
      (json['durationSeconds'] as num).toDouble(),
      (json['fee'] as num).round(),
    );
    if (!result.distanceKm.isFinite ||
        result.distanceKm < 0 ||
        !result.durationSeconds.isFinite ||
        result.durationSeconds < 0 ||
        result.fee < 0) {
      throw const FormatException('Khoảng cách đường đi không hợp lệ');
    }
    return result;
  }
}
