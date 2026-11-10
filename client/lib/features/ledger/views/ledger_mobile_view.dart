import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../ledger_providers.dart';
import '../widgets/ledger_filter_toolbar.dart';
import '../widgets/ledger_metric_cards.dart';
import '../widgets/payment_record_card.dart';

class LedgerMobileView extends ConsumerWidget {
  const LedgerMobileView({super.key});

  static const _navItems = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home', route: AppRoutes.home),
    (icon: Icons.store_outlined, selectedIcon: Icons.store, label: 'Shop', route: AppRoutes.shop),
    (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Orders', route: AppRoutes.orders),
    (icon: Icons.account_balance_wallet_outlined, selectedIcon: Icons.account_balance_wallet, label: 'Ledger', route: AppRoutes.ledger),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', route: AppRoutes.profile),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(ledgerViewModelProvider);
    final vm = ref.read(ledgerViewModelProvider.notifier);
    final payments = state.filteredPayments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () => vm.loadPayments(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    LedgerMetricCards(),
                    SizedBox(height: 16),
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
                      Icon(Icons.account_balance_wallet_outlined, size: 56, color: cs.outline),
                      const SizedBox(height: 12),
                      Text('No payment records found', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text('Record an advance, settlement, or refund', style: TextStyle(color: cs.outline)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => PaymentRecordCard(payment: payments[index]),
                    childCount: payments.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 3, // Ledger
        onDestinationSelected: (i) => AppNav.go(_navItems[i].route),
        destinations: _navItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
