import 'package:flutter/material.dart';
import '../services/account_api.dart';

class ProductImage extends StatelessWidget {
  const ProductImage(
      {super.key,
      required this.path,
      this.width,
      this.height,
      this.fit = BoxFit.cover});
  final String path;
  final double? width, height;
  final BoxFit fit;

  Widget placeholder() => Container(
        width: width,
        height: height,
        color: const Color(0xFFEDF2ED),
        child: const Center(
          child: Icon(Icons.photo_outlined, size: 30, color: Color(0xFF81968A)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (path.trim().isEmpty) return placeholder();
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, error, stack) => placeholder(),
      );
    }
    return Image.network(
      Uri.parse(AccountApi.base).resolve(path).toString(),
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder(),
      errorBuilder: (_, error, stack) => placeholder(),
    );
  }
}
