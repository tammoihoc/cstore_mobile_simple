import 'package:flutter/material.dart';
import '../models/models.dart';
import 'product_image.dart';

const forest = Color(0xFF214E3E);

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final OrderStatus status;
  @override
  Widget build(BuildContext context) {
    final stopped =
        [OrderStatus.rejected, OrderStatus.cancelled].contains(status);
    final done = status == OrderStatus.delivered;
    final color = stopped
        ? const Color(0xFF9F4940)
        : done
            ? forest
            : const Color(0xFFA05A22);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        statusNames[status.index],
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class OrderItemRow extends StatelessWidget {
  const OrderItemRow({super.key, required this.line, this.imageFallback = ''});
  final OrderLine line;
  final String imageFallback;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ProductImage(
                path: line.image.isEmpty ? imageFallback : line.image,
                width: 66,
                height: 66,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${line.quantity} × ${money(line.price)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  )
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              money(line.price * line.quantity),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            )
          ],
        ),
      );
}

class OrderPreview extends StatelessWidget {
  const OrderPreview(
      {super.key,
      required this.order,
      required this.branchName,
      required this.onTap,
      this.delivery = false});
  final ShopOrder order;
  final String branchName;
  final VoidCallback onTap;
  final bool delivery;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '#CS${order.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      StatusPill(order.status)
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ProductImage(
                          path: order.lines.firstOrNull?.image ?? '',
                          width: 64,
                          height: 64,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              branchName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.lines
                                  .map((l) => '${l.quantity} ${l.name}')
                                  .join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            )
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.black38,
                      )
                    ],
                  ),
                  if (delivery) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: forest,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.address,
                            style: const TextStyle(fontSize: 12),
                          ),
                        )
                      ],
                    )
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          delivery
                              ? 'Thu COD ${money(order.paid ? 0 : order.total)}'
                              : order.paid
                                  ? 'Đã thanh toán'
                                  : 'Thanh toán khi nhận',
                          style: TextStyle(
                            fontSize: 11,
                            color: order.paid ? forest : Colors.black54,
                          ),
                        ),
                      ),
                      Text(
                        money(delivery ? order.fee : order.total),
                        style: const TextStyle(
                          color: forest,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (delivery)
                        const Text(
                          ' phí giao',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      );
}

class AmountRow extends StatelessWidget {
  const AmountRow(this.label, this.amount, {super.key, this.total = false});
  final String label;
  final int amount;
  final bool total;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: total ? forest : Colors.black54,
                  fontWeight: total ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
            Text(
              money(amount),
              style: TextStyle(
                color: forest,
                fontSize: total ? 22 : 14,
                fontWeight: total ? FontWeight.w800 : FontWeight.w600,
              ),
            )
          ],
        ),
      );
}
