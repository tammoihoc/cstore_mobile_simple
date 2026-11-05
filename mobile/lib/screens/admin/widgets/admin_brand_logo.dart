// Khung logo thương hiệu; ảnh phủ khung và được cắt theo hình tròn.

import 'package:flutter/material.dart';
import 'package:cstore_mobile/widgets/product_image.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_colors.dart';

class AdminBrandLogo extends StatelessWidget {
  const AdminBrandLogo(
      {super.key, required this.name, this.path = '', this.size = 52});
  final String name, path;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFDCE6D8)),
        ),
        child: ClipOval(
          child: path.isEmpty
              ? ColoredBox(
                  color: adminSage,
                  child: Center(
                    child: Text(
                      name.isEmpty ? 'C' : name.characters.first.toUpperCase(),
                      style: TextStyle(
                        color: adminForest,
                        fontSize: size * .35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
              : ProductImage(path: path),
        ),
      );
}
