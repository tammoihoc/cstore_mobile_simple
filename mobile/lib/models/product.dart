/// Sản phẩm và cách đọc JSON. Giá, tồn kho và trạng thái bán do server quản lý.
class Product {
  Product(
    this.id,
    this.branchId,
    this.name,
    this.price,
    this.stock,
    this.asset,
    this.category,
  );
  final int id;
  final int branchId;
  String name;
  String category;
  int price;
  int stock;
  String asset;
  bool active = true;
}

Product productFromJson(
  Map<String, dynamic> json,
) =>
    Product(
      json['id'] as int,
      json['storeId'] as int,
      json['name'] as String,
      (json['price'] as num).round(),
      json['stock'] as int,
      json['image'] as String? ?? '',
      json['category'] as String? ?? 'Khác',
    )..active = json['active'] as bool;
