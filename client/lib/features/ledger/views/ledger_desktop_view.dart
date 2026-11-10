import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../ledger_providers.dart';
import '../widgets/ledger_filter_toolbar.dart';
import '../widgets/ledger_metric_cards.dart';
import '../widgets/payment_record_card.dart';

class LedgerDesktopView extends ConsumerWidget {
  const LedgerDesktopView({super.key});

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
          // Persistent Navigation Drawer
          NavigationDrawer(
            selectedIndex: 4, // Ledger
            onDestinationSelected: (i) => AppNav.go(_navItems[i].route),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 16, 10),
                child: Text(
                  'मिठाई वाले',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 4),
                child: Text('MANAGEMENT', style: TextStyle(fontSize: 11, letterSpacing: 1.4)),
              ),
              ..._navItems.map(
                (item) => NavigationDrawerDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: Text(item.label),
                ),
              ),
            ],
          ),

          // Main Content
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Payment Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Ledger',
                    onPressed: () => vm.loadPayments(),
                  ),
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
