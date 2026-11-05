// Gom các chi nhánh thành thương hiệu để chọn khi tạo cửa hàng.

import 'package:cstore_mobile/models/models.dart';

class BrandOption {
  BrandOption(this.name, this.branches);
  final String name;
  final List<Branch> branches;
  String get key => normalizeBrandName(name);
  String get image =>
      branches.map((b) => b.image).where((p) => p.isNotEmpty).firstOrNull ?? '';
}

List<BrandOption> brandOptions(List<Branch> branches) {
  final groups = <String, List<Branch>>{};
  for (final b in branches) {
    groups.putIfAbsent(normalizeBrandName(b.brand ?? b.name), () => []).add(b);
  }
  return groups.values
      .map((v) => BrandOption(v.first.brand ?? v.first.name, v))
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

String normalizeBrandName(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
