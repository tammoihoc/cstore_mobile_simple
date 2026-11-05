import 'package:flutter/material.dart';
import '../models/models.dart';
import 'product_image.dart';

class AccountAvatar extends StatelessWidget {
  const AccountAvatar(
      {super.key,
      this.account,
      this.path,
      this.gender,
      this.role,
      this.size = 52});
  final Account? account;
  final String? path, gender;
  final Role? role;
  final double size;
  @override
  Widget build(BuildContext context) {
    final kind = role ?? account?.role ?? Role.customer;
    final photo = path ?? account?.avatar ?? '';
    final selection = gender ?? account?.gender ?? 'UNSPECIFIED';
    final image = photo.isNotEmpty
        ? photo
        : kind == Role.customer
            ? switch (selection) {
                'MALE' => 'assets/images/avatar-default-male.png',
                'FEMALE' => 'assets/images/avatar-default-female.png',
                _ => ''
              }
            : '';
    return Semantics(
      label: kind == Role.store
          ? 'Logo thương hiệu'
          : photo.isNotEmpty
              ? 'Ảnh đại diện'
              : 'Avatar mặc định',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFEAF0E5),
          border: Border.all(color: const Color(0xFFDCE6D8)),
        ),
        clipBehavior: Clip.antiAlias,
        child: image.isNotEmpty
            ? ClipOval(
                child: ProductImage(path: image, width: size, height: size),
              )
            : Icon(
                kind == Role.store
                    ? Icons.storefront_rounded
                    : kind == Role.shipper
                        ? Icons.delivery_dining_rounded
                        : Icons.person_rounded,
                size: size * .52,
                color: const Color(0xFF173F35),
              ),
      ),
    );
  }
}
