import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/shop_filter.dart';
import '../ledger_providers.dart';
import '../widgets/ledger_filter_toolbar.dart';
import '../widgets/ledger_metric_cards.dart';
import '../widgets/payment_record_card.dart';
import '../../../core/widgets/refresh_button.dart';

class LedgerDesktopView extends ConsumerWidget {
  const LedgerDesktopView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(ledgerViewModelProvider);
    final vm = ref.read(ledgerViewModelProvider.notifier);
    final payments = state.filteredPayments;

    return Scaffold(
      body: Row(
        children: [
          // Main Content
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: const Text('Payment Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
                actions: [
                  const ShopFilterButton(),
                  RefreshButton(onPressed: () => vm.loadPayments()),
                  const SizedBox(width: 8),
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const LedgerMetricCards(),
                    const SizedBox(height: 20),
                    const LedgerFilterToolbar(),
                    const SizedBox(height: 16),

                    // Table / List of records
                    Expanded(
                      child: payments.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.account_balance_wallet_outlined, size: 64, color: cs.outline),
                                  const SizedBox(height: 16),
                                  Text('No payment records found', style: theme.textTheme.titleMedium),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Record payments received or refunds given to track customer balances.',
                                    style: TextStyle(color: cs.outline),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: payments.length,
                              itemBuilder: (context, index) {
                                return PaymentRecordCard(payment: payments[index]);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
