import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../ledger_providers.dart';
import '../widgets/ledger_filter_toolbar.dart';
import '../widgets/ledger_metric_cards.dart';
import '../widgets/payment_record_card.dart';

class LedgerTabletView extends ConsumerWidget {
  const LedgerTabletView({super.key});

  static const _navItems = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home', route: AppRoutes.home),
    (icon: Icons.store_outlined, selectedIcon: Icons.store, label: 'Shop', route: AppRoutes.shop),
    (icon: Icons.restaurant_menu_outlined, selectedIcon: Icons.restaurant_menu, label: 'Menu', route: AppRoutes.menu),
    (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Orders', route: AppRoutes.orders),
    (icon: Icons.account_balance_wallet_outlined, selectedIcon: Icons.account_balance_wallet, label: 'Ledger', route: AppRoutes.ledger),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', route: AppRoutes.profile),
    (icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings', route: AppRoutes.settings),
  ];

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
          NavigationRail(
            selectedIndex: 4, // Ledger
            onDestinationSelected: (i) => AppNav.go(_navItems[i].route),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Text(
                  'मि',
                  style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
                ),
              ),
            ),
            destinations: _navItems
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Payment Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
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
