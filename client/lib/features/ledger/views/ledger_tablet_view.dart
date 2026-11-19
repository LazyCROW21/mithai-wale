import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_shell.dart';
import '../../../core/state/shop_filter.dart';
import '../ledger_providers.dart';
import '../widgets/ledger_filter_toolbar.dart';
import '../widgets/ledger_metric_cards.dart';
import '../widgets/payment_record_card.dart';

class LedgerTabletView extends ConsumerWidget {
  const LedgerTabletView({super.key});

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
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                leading: MoreBackButton.of(context),
                title: const Text('Payment Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: const [ShopFilterButton(), SizedBox(width: 8)],
              ),
              body: RefreshIndicator(
                onRefresh: () => vm.loadPayments(),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const [
                            LedgerMetricCards(),
                            SizedBox(height: 20),
                            LedgerFilterToolbar(),
                            SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    if (payments.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_wallet_outlined, size: 64, color: cs.outline),
                              const SizedBox(height: 16),
                              Text('No payment records found', style: theme.textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text('Record an advance, settlement, or refund', style: TextStyle(color: cs.outline)),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => PaymentRecordCard(payment: payments[index]),
                            childCount: payments.length,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
