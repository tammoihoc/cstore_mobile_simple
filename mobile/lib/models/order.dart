import 'order_status.dart';

/// Đơn hàng gồm thông tin giao nhận, dòng hàng và lịch sử trạng thái.
/// Giá trong OrderLine là giá đã chốt khi đặt, không phải giá catalog hiện tại.
class OrderLine {
  OrderLine(
    this.productId,
    this.name,
    this.price,
    this.quantity, {
    this.image = '',
  });
  final int productId;
  final int price;
  final int quantity;
  final String name;
  final String image;
}

class HistoryEntry {
  HistoryEntry(
    this.status, {
    DateTime? time,
  }) : at = time ?? DateTime.now();
  final OrderStatus status;
  final DateTime at;
}

class ShopOrder {
  ShopOrder(
    this.id,
    this.branchId,
    this.lines,
    this.recipient,
    this.phone,
    this.address,
    this.lat,
    this.lng,
    this.fee, {
    DateTime? createdAt,
  }) : created = createdAt ?? DateTime.now();
  final int id;
  final int branchId;
  final int fee;
  final List<OrderLine> lines;
  final String recipient;
  final String phone;
  final String address;
  final double lat;
  final double lng;
  final DateTime created;
  OrderStatus status = OrderStatus.pending;
  String? reason;
  String? shipperId;
  String? paidBy;
  String? customerId;
  String? shipperName;
  String? shipperPhone;
  String? shipperAvatar;
  double? distanceKm;
  String? distanceSource;
  double? durationSeconds;
  DateTime? paidAt;
  final List<HistoryEntry> history = [HistoryEntry(OrderStatus.pending)];
  int get subtotal => lines.fold(
        0,
        (s, line) => s + line.price * line.quantity,
      );
  int get total => subtotal + fee;
  bool get paid => paidAt != null;
  bool get activeDelivery => [
        OrderStatus.assigned,
        OrderStatus.pickedUp,
        OrderStatus.delivering
      ].contains(status);
}

ShopOrder orderFromJson(
  Map<String, dynamic> json,
) {
  final order = ShopOrder(
    json['id'] as int,
    json['storeId'] as int,
    [
      for (final line in json['items'] as List)
        OrderLine(
          line['productId'] as int,
          line['name'] as String,
          (line['unitPrice'] as num).round(),
          line['quantity'] as int,
          image: line['image'] as String? ?? '',
        )
    ],
    json['recipient'] as String? ?? '',
    json['phone'] as String? ?? '',
    json['address'] as String? ?? '',
    (json['latitude'] as num?)?.toDouble() ?? 0,
    (json['longitude'] as num?)?.toDouble() ?? 0,
    (json['fee'] as num).round(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
  order.status = statusFromApi(json['status'] as String);
  order.reason = json['reason'] as String?;
  order.customerId = '${json['customerId']}';
  order.shipperId = json['shipperId']?.toString();
  order.shipperName = json['shipperName'] as String?;
  order.shipperPhone = json['shipperPhone'] as String?;
  order.shipperAvatar = json['shipperAvatar'] as String?;
  order.distanceKm = (json['distanceKm'] as num?)?.toDouble();
  order.distanceSource = json['distanceSource'] as String?;
  order.durationSeconds = (json['durationSeconds'] as num?)?.toDouble();
  order.paidBy = json['paidBy'] as String?;
  order.paidAt =
      json['paidAt'] == null ? null : DateTime.parse(json['paidAt'] as String);
  order.history.clear();
  order.history.addAll(
    [
      for (final entry in json['history'] as List)
        HistoryEntry(
          statusFromApi(entry['status'] as String),
          time: DateTime.parse(entry['at'] as String),
        )
    ],
  );
  return order;
}
