import 'package:flutter/material.dart';

class CStoreLogo extends StatelessWidget {
  const CStoreLogo({super.key, this.width = 144, this.height = 52});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/images/cstore-logo.png',
        width: width,
        height: height,
        fit: BoxFit.cover,
        alignment: Alignment.centerLeft,
        semanticLabel: 'C-Store',
      );
}

class CStoreAppBarTitle extends StatelessWidget {
  const CStoreAppBarTitle({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Flexible(child: CStoreLogo()),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                subtitle!,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      );
}
