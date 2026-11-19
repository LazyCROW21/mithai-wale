import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ledger_providers.dart';

class LedgerMetricCards extends ConsumerWidget {
  const LedgerMetricCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(ledgerViewModelProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        final cards = [
          _buildMetric(
            context: context,
            title: 'Total Received (Credit)',
            amount: state.totalCredit,
            count: state.creditCount,
            color: Colors.green,
            icon: Icons.arrow_downward,
          ),
          _buildMetric(
            context: context,
            title: 'Total Refunded (Debit)',
            amount: state.totalDebit,
            count: state.debitCount,
            color: Colors.deepOrange,
            icon: Icons.arrow_upward,
          ),
          _buildMetric(
            context: context,
            title: 'Net Collections',
            amount: state.netBalance,
            count: state.filteredPayments.length,
            color: cs.primary,
            icon: Icons.account_balance_wallet,
          ),
        ];

        if (isCompact) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: cards
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SizedBox(width: 200, child: c),
                      ))
                  .toList(),
            ),
          );
        }

        return Row(
          children: cards
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: c,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildMetric({
    required BuildContext context,
    required String title,
    required double amount,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count ${count == 1 ? "entry" : "entries"}',
            style: TextStyle(fontSize: 11, color: cs.outline),
          ),
        ],
      ),
    );
  }
}
