import 'package:flutter/material.dart';
import 'models.dart';
import '../widgets/date_filter.dart';

DateTime? completedAt(ShopOrder order) {
  if (order.status != OrderStatus.delivered || !order.paid) return null;
  final delivered = order.history
      .where((e) => e.status == OrderStatus.delivered)
      .map((e) => e.at)
      .toList()
    ..sort();
  final time = delivered.lastOrNull;
  if (time == null) return order.paidAt;
  return order.paidAt!.isAfter(time) ? order.paidAt : time;
}

class ProductSales {
  ProductSales(this.line);
  final OrderLine line;
  int quantity = 0, revenue = 0;
}

class StoreMetrics {
  StoreMetrics(
    List<ShopOrder> orders,
    DateTimeRange? range,
  ) {
    placed = orders
        .where((o) => inDateRange(
              o.created,
              range,
            ))
        .toList();
    completed = orders
        .where(
          (o) =>
              completedAt(o) != null &&
              inDateRange(
                completedAt(o),
                range,
              ),
        )
        .toList();
    revenue = completed.fold<int>(0, (sum, o) => sum + o.subtotal);
    commission = (revenue * 15 / 100).round();
    deliveryFees = completed.fold<int>(0, (sum, o) => sum + o.fee);
    final grouped = <int, ProductSales>{};
    for (final o in completed) {
      final day = localDay(completedAt(o)!);
      dailyRevenue.update(
        day,
        (v) => v + o.subtotal,
        ifAbsent: () => o.subtotal,
      );
      for (final line in o.lines) {
        final product = grouped.putIfAbsent(
          line.productId,
          () => ProductSales(line),
        );
        product.quantity += line.quantity;
        product.revenue += line.price * line.quantity;
      }
    }
    bestSellers = grouped.values.toList()
      ..sort(
        (a, b) {
          final amount = b.revenue.compareTo(a.revenue);
          return amount == 0
              ? a.line.productId.compareTo(b.line.productId)
              : amount;
        },
      );
  }
  late final List<ShopOrder> placed, completed;
  late final int revenue, commission, deliveryFees;
  late final List<ProductSales> bestSellers;
  final Map<DateTime, int> dailyRevenue = {};
  int get estimatedNet => revenue - commission;
  int get waiting =>
      placed.where((o) => o.status == OrderStatus.pending).length;
  int get accepted =>
      placed.where((o) => o.status == OrderStatus.accepted).length;
  int get delivering => placed.where((o) => o.activeDelivery).length;
  int get stopped => placed
      .where(
        (o) => [OrderStatus.cancelled, OrderStatus.rejected].contains(o.status),
      )
      .length;
  int get unpaidDelivered =>
      placed.where((o) => o.status == OrderStatus.delivered && !o.paid).length;
  int get placedCompleted =>
      placed.where((o) => o.status == OrderStatus.delivered && o.paid).length;
}
