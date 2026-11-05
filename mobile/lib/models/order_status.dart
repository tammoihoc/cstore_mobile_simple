/// Trạng thái đơn và cách chuyển giữa giá trị Dart với chuỗi JSON của API.
enum OrderStatus {
  pending,
  accepted,
  assigned,
  pickedUp,
  delivering,
  delivered,
  rejected,
  cancelled
}

const statusNames = [
  'Chờ xác nhận',
  'Chờ shipper',
  'Đã nhận giao',
  'Đã lấy hàng',
  'Đang giao',
  'Đã giao',
  'Từ chối',
  'Đã hủy'
];

OrderStatus statusFromApi(String value) => switch (value) {
      'PENDING' => OrderStatus.pending,
      'ACCEPTED' => OrderStatus.accepted,
      'ASSIGNED' => OrderStatus.assigned,
      'PICKED_UP' => OrderStatus.pickedUp,
      'DELIVERING' => OrderStatus.delivering,
      'DELIVERED' => OrderStatus.delivered,
      'REJECTED' => OrderStatus.rejected,
      'CANCELLED' => OrderStatus.cancelled,
      _ => throw FormatException('Unknown order status: $value')
    };
String statusToApi(OrderStatus s) => [
      'PENDING',
      'ACCEPTED',
      'ASSIGNED',
      'PICKED_UP',
      'DELIVERING',
      'DELIVERED',
      'REJECTED',
      'CANCELLED'
    ][s.index];
