import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/models/payment_model.dart';
import '../ledger_providers.dart';

class PaymentRecordCard extends ConsumerWidget {
  const PaymentRecordCard({
    super.key,
    required this.payment,
    this.showOrderId = true,
  });

  final PaymentModel payment;
  final bool showOrderId;

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $ampm';
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment Record?'),
        content: Text(
          'Are you sure you want to delete this payment record of ₹${payment.amount.toStringAsFixed(2)} for ${payment.orderId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              ref.read(ledgerViewModelProvider.notifier).deletePayment(payment.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Payment record ${payment.id} deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isCredit = payment.isCredit;
    final color = isCredit ? Colors.green : Colors.deepOrange;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon Badge
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line 1: <Customer Name> #<orderid>
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          payment.customerName.isNotEmpty
                              ? payment.customerName
                              : 'Customer',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showOrderId && payment.orderId.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          payment.orderId.startsWith('#')
                              ? payment.orderId
                              : '#${payment.orderId}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Line 2: Credit / Debit | Mode (cash or card)
                  Row(
                    children: [
                      Text(
                        isCredit ? 'Credit' : 'Debit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        ' | Mode (${payment.paymentMode})',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  if (payment.note.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      payment.note,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (payment.referenceNumber != null && payment.referenceNumber!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Ref: ${payment.referenceNumber}',
                      style: TextStyle(fontSize: 11, color: cs.outline),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    _formatDateTime(payment.createdAt),
                    style: TextStyle(fontSize: 11, color: cs.outline),
                  ),
                ],
              ),
            ),

            // Amount & Delete Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? "+" : "-"} ₹${payment.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: cs.outline),
                  tooltip: 'Delete Entry',
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
