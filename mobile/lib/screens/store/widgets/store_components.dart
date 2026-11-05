// Các ô thống kê, khung nội dung và dòng số liệu của cửa hàng.

import 'package:flutter/material.dart';
import 'package:cstore_mobile/screens/store/widgets/store_styles.dart';

Widget storePanel(Widget child, {Color color = Colors.white}) => Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
      child: child,
    );
Widget storeMetric(String title, String value, IconData icon,
        {VoidCallback? onTap, String? detail}) =>
    Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: storeForest, size: 23),
              const SizedBox(height: 14),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: storeForest,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(color: storeMuted, fontSize: 12),
              ),
              if (detail != null)
                Text(
                  detail,
                  style: const TextStyle(
                    color: storeMuted,
                    fontSize: 10,
                  ),
                )
            ],
          ),
        ),
      ),
    );

Widget storeFinanceRow(String name, String value, {bool strong = false}) => Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              color: strong ? Colors.white : Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: strong ? storeLime : Colors.white,
              fontSize: strong ? 19 : 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        )
      ],
    );
Widget storeStockRow(String title, String value) => Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: storeMuted, fontSize: 12),
          ),
        ),
        Text(
          value,
          style:
              const TextStyle(color: storeForest, fontWeight: FontWeight.w700),
        )
      ],
    );
