/// Chi nhánh lấy từ API. Logo thương hiệu và tên chi nhánh là dữ liệu server.
class Branch {
  const Branch(
    this.id,
    this.name,
    this.address,
    this.lat,
    this.lng, {
    this.brand,
    this.open = true,
    this.image = '',
  });
  final int id;
  final String name;
  final String address;
  final String? brand;
  final String image;
  final double lat;
  final double lng;
  final bool open;
}
