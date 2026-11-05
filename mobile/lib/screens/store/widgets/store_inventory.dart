// Sản phẩm: lọc dữ liệu đã tải và phát callback tìm kiếm/chỉnh sửa.

import 'package:flutter/material.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/widgets/common.dart';
import 'package:cstore_mobile/widgets/product_image.dart';
import 'package:cstore_mobile/screens/store/widgets/store_styles.dart';

/// Chỉ lọc danh sách trong bộ nhớ; onEdit chuyển việc chỉnh sửa về StoreHome.
Widget buildStoreInventory({
  required AppState state,
  required String search,
  required String stockFilter,
  required String category,
  required ValueChanged<String> onSearchChanged,
  required ValueChanged<String> onCategoryChanged,
  required ValueChanged<String> onStockFilterChanged,
  required void Function([Product? product]) onEdit,
}) {
  final s = state;
  final stock = s.products
      .where((product) => product.branchId == s.storeBranchId && product.active)
      .toList();

  final categories = stock.map((p) => p.category).toSet().toList()..sort();
  final effectiveCategory =
      categories.contains(category) ? category : 'Tất cả danh mục';
  final visible = stock
      .where((p) =>
          (effectiveCategory == 'Tất cả danh mục' ||
              p.category == effectiveCategory) &&
          p.name.toLowerCase().contains(search.toLowerCase()) &&
          (stockFilter == 'Tất cả' ||
              (stockFilter == 'Hết hàng'
                  ? p.stock == 0
                  : p.stock > 0 && p.stock <= 5)))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  return RefreshIndicator(
    onRefresh: s.reload,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        heading('Sản phẩm & tồn kho',
            '${stock.length} sản phẩm • ${categories.length} danh mục'),
        FilledButton.icon(
          onPressed: () => onEdit(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Thêm sản phẩm'),
        ),
        const SizedBox(height: 20),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Tìm sản phẩm',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
            key: ValueKey(effectiveCategory),
            initialValue: effectiveCategory,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Danh mục',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: [
              for (final c in ['Tất cả danh mục', ...categories])
                DropdownMenuItem(value: c, child: Text(c))
            ],
            onChanged: (v) => onCategoryChanged(v!)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final status in ['Tất cả', 'Sắp hết', 'Hết hàng'])
              ChoiceChip(
                label: Text(status),
                selected: stockFilter == status,
                onSelected: (_) => onStockFilterChanged(status),
              )
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${visible.length} sản phẩm phù hợp',
          style: const TextStyle(color: storeMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty) empty('Không có sản phẩm phù hợp'),
        for (final p in visible)
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onEdit(p),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: ProductImage(
                        path: p.asset,
                        width: 92,
                        height: 108,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.category,
                            style: const TextStyle(
                              fontSize: 11,
                              color: storeMuted,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: storeForest,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            money(p.price),
                            style: const TextStyle(
                              color: storeForest,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: p.stock <= 5
                                  ? const Color(0xFFFFEEE3)
                                  : storeSage,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              p.stock == 0
                                  ? 'Hết hàng'
                                  : 'Còn ${p.stock} sản phẩm',
                              style: TextStyle(
                                fontSize: 11,
                                color: p.stock <= 5
                                    ? const Color(0xFF9B581C)
                                    : storeForest,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: storeMuted,
                    )
                  ],
                ),
              ),
            ),
          )
      ],
    ),
  );
}
