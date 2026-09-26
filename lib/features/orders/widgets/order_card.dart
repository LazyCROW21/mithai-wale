import 'package:flutter/material.dart';

import '../../../core/database/models/order_model.dart';
import 'edit_order_modal.dart';
import 'order_invoice_share.dart';

/// A table-like long row card for displaying an order with basic info
/// and an expandable breakdown view directly showing order items and pricing.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.isExpanded,
    required this.onToggleExpand,
    this.onStatusChanged,
  });

  final OrderModel order;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final ValueChanged<String>? onStatusChanged;

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final integerPart = parts[0].replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',');
    return '₹ $integerPart.${parts[1]}';
  }

  Color _getStatusColor(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'placed':
        return Colors.blue;
      case 'preparing':
        return Colors.orange;
      case 'ready':
        return Colors.purple;
      case 'delivering':
        return Colors.cyan;
      case 'delivered':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return cs.error;
      case 'pending':
        return Colors.amber;
      default:
        return cs.secondary;
    }
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      tooltip: 'Order Options',
      onSelected: (action) {
        if (action == 'edit') {
          showEditOrderModal(context, order);
        } else if (action == 'share') {
          shareOrderInvoice(context, order);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 10),
              Text('Edit Order'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share_outlined, size: 18),
              SizedBox(width: 10),
              Text('Share Invoice'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'print',
          enabled: false,
          child: Row(
            children: [
              Icon(Icons.print_outlined, size: 18, color: Colors.grey),
              SizedBox(width: 10),
              Text('Print (Disabled)', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusColor = _getStatusColor(context, order.status);

    return Card(
      elevation: isExpanded ? 3 : 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isExpanded ? cs.primary.withValues(alpha: 0.4) : cs.outlineVariant.withValues(alpha: 0.5),
          width: isExpanded ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onToggleExpand,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Main Header Row (Basic Info) ──────────────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 650;
                  if (isNarrow) {
                    return _buildMobileRow(context, theme, cs, statusColor);
                  }
                  return _buildDesktopRow(context, theme, cs, statusColor);
                },
              ),

              // ── Expandable Item Breakdown (Directly shows items) ──────────
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(height: 1),
                    ),

                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Item Name',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Quantity',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Unit Price',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Total Price',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Item Rows
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '₹${item.unitPrice.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '₹${item.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        )),

                    const Divider(height: 16),

                    // Discount Breakdown (if applied)
                    if (order.discountType != null && order.calculatedDiscount > 0) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal',
                              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                            ),
                            Text(
                              _formatCurrency(order.subtotal),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.discountType == DiscountType.percentage
                                  ? 'Discount (${order.discountAmount % 1 == 0 ? order.discountAmount.toInt() : order.discountAmount}%)'
                                  : 'Discount (Flat)',
                              style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '-${_formatCurrency(order.calculatedDiscount)}',
                              style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Grand Total & Customer Phone
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.customerPhone.isNotEmpty
                                ? 'Customer Phone: ${order.customerPhone}'
                                : 'No Phone Provided',
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                          Text(
                            'Grand Total: ${_formatCurrency(order.finalBill)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Wide desktop/tablet horizontal table-like row card layout.
  /// Items summary is placed in the leftmost column.
  Widget _buildDesktopRow(BuildContext context, ThemeData theme, ColorScheme cs, Color statusColor) {
    return Row(
      children: [
        // ── 1. Items Summary (Leftmost column) ──────────────────────────────
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    order.id,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${order.items.length} ${order.items.length == 1 ? 'item' : 'items'})',
                    style: TextStyle(fontSize: 11, color: cs.outline),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                order.itemsSummary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // ── 2. Customer Name & Phone ────────────────────────────────────────
        SizedBox(
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.customerName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                order.customerPhone.isNotEmpty ? order.customerPhone : 'No phone',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // ── 3. Delivery Date ────────────────────────────────────────────────
        SizedBox(
          width: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Date',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(order.deliveryDate),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // ── 4. Total Bill ───────────────────────────────────────────────────
        SizedBox(
          width: 115,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                order.discountType != null && order.calculatedDiscount > 0
                    ? 'Total (Disc.)'
                    : 'Total Bill',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                _formatCurrency(order.finalBill),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // ── 5. Status Badge ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            order.status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // ── 6. Popup Menu on the right (Edit, Share, Print) ─────────────────
        _buildPopupMenu(context),

        // ── 7. Expand/Collapse Icon ─────────────────────────────────────────
        AnimatedRotation(
          turns: isExpanded ? 0.5 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.keyboard_arrow_down,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Compact mobile row layout.
  /// Items summary is placed in the leftmost column.
  Widget _buildMobileRow(BuildContext context, ThemeData theme, ColorScheme cs, Color statusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top line: Leftmost Items summary & ID, Right status & popup & expand
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leftmost Items Overview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        order.id,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${order.items.length} ${order.items.length == 1 ? 'item' : 'items'})',
                        style: TextStyle(fontSize: 11, color: cs.outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.itemsSummary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                order.status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),

            // Popup Menu on the right (Edit, Share, Print)
            _buildPopupMenu(context),

            // Expand icon
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Customer Info line
        Row(
          children: [
            Icon(Icons.person_outline, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              order.customerName,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
            ),
            if (order.customerPhone.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '•  ${order.customerPhone}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // Delivery Date & Total Bill
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  _formatDate(order.deliveryDate),
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Text(
              _formatCurrency(order.finalBill),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
