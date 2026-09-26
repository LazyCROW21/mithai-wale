import 'package:flutter/material.dart';

import '../../../core/database/models/order_model.dart';
import '../../orders/widgets/edit_order_modal.dart';

/// Card showing customer info, total bill, and 1-line item preview for an order.
///
/// Tapping the card opens the editable order summary modal/dialog via [showEditOrderModal]
/// (desktop = Dialog, mobile/tablet = Modal Bottom Sheet).
class OrderHighlightCard extends StatelessWidget {
  const OrderHighlightCard({
    super.key,
    required this.order,
  });

  final OrderModel order;

  static String _formatQuantity(double q) {
    if (q == q.roundToDouble()) {
      return q.toInt().toString();
    }
    return q.toStringAsFixed(1);
  }

  static String _formatOrderTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    if (isToday) {
      return 'Today, $hour:$min $ampm';
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]}, $hour:$min $ampm';
  }

  static Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'ready':
        return Colors.teal;
      case 'preparing':
        return Colors.orange;
      case 'placed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusColor = _getStatusColor(order.status);

    // Build the 1-line item list preview with quantities
    final oneLineItems = order.items.isEmpty
        ? 'No items'
        : order.items
            .map((i) => '${i.name} (${_formatQuantity(i.quantity)} ${i.unit})')
            .join(', ');

    final customerInitial = order.customerName.trim().isNotEmpty
        ? order.customerName.trim()[0].toUpperCase()
        : '?';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withAlpha(120)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showEditOrderModal(context, order),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar + Customer & Order Info + Total & Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      customerInitial,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                order.customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              order.id,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cs.outline,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${order.customerPhone.isNotEmpty ? '${order.customerPhone} • ' : ''}${_formatOrderTime(order.orderDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.outline,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${order.finalBill.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withAlpha(80)),
                        ),
                        child: Text(
                          order.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 1-line item list preview with edit hint
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withAlpha(70),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.restaurant_menu_outlined,
                      size: 14,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        oneLineItems,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.edit_outlined,
                      size: 13,
                      color: cs.outline,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
