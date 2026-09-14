import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../home_providers.dart';

class HomeDesktopView extends ConsumerWidget {
  const HomeDesktopView({super.key});

  static const _navItems = [
    (icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Home', route: AppRoutes.home),
    (icon: Icons.storefront_outlined, selectedIcon: Icons.storefront, label: 'Shop', route: AppRoutes.shop),
    (icon: Icons.restaurant_menu_outlined, selectedIcon: Icons.restaurant_menu, label: 'Menu', route: AppRoutes.menu),
    (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Orders', route: AppRoutes.orders),
    (icon: Icons.analytics_outlined, selectedIcon: Icons.analytics, label: 'Reports', route: AppRoutes.reports),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', route: AppRoutes.profile),
    (icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings', route: AppRoutes.settings),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(homeViewModelProvider);

    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: 0, // Home Dashboard index
            onDestinationSelected: (i) => AppNav.go(_navItems[i].route),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 16, 10),
                child: Text(
                  'मिठाई वाले',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 4),
                child: Text('DASHBOARD', style: TextStyle(fontSize: 11, letterSpacing: 1.4)),
              ),
              ..._navItems.map(
                (item) => NavigationDrawerDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: Text(item.label),
                ),
              ),
              const Divider(indent: 28, endIndent: 28),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 28),
                leading: const Icon(Icons.logout_outlined),
                title: const Text('Sign out'),
                onTap: () => AppNav.push(AppRoutes.confirmLogout),
              ),
            ],
          ),
          const VerticalDivider(width: 1),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Header Toolbar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(bottom: BorderSide(color: cs.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      Text('Business Dashboard', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      Chip(label: const Text('15 Sep 2026'), backgroundColor: cs.surfaceContainerHighest),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => AppNav.go(AppRoutes.shop),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Start New Order'),
                      ),
                    ],
                  ),
                ),

                // Dashboard Main Body
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(32),
                    children: [
                      // Top 3 Summary Cards
                      Row(
                        children: [
                          // Card 1: Money to collect
                          Expanded(
                            child: Card(
                              color: cs.primaryContainer,
                              elevation: 0,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Money to Collect Today', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
                                    const SizedBox(height: 8),
                                    Text('₹${state.totalMoneyToCollect.toStringAsFixed(0)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
                                    const SizedBox(height: 4),
                                    Text('${state.customerCollections.length} Customer Accounts Pending', style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer.withAlpha(200))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Card 2 (Middle): Total Items Count Sum
                          Expanded(
                            child: Card(
                              color: cs.secondaryContainer,
                              elevation: 0,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text('Total Items Overall Orders', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSecondaryContainer)),
                                    const SizedBox(height: 4),
                                    Text('Sum = ${state.totalItemsSum}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cs.onSecondaryContainer)),
                                    const SizedBox(height: 4),
                                    Text('(e.g., 3 + 2 + 5 cakes / items sum)', style: TextStyle(fontSize: 11, color: cs.onSecondaryContainer.withAlpha(200))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Card 3: Today's Orders Count
                          Expanded(
                            child: Card(
                              color: cs.tertiaryContainer,
                              elevation: 0,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Today\'s Total Orders', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onTertiaryContainer)),
                                    const SizedBox(height: 8),
                                    Text('${state.totalOrdersCount}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cs.onTertiaryContainer)),
                                    const SizedBox(height: 4),
                                    Text('Active orders across Mithai Shop', style: TextStyle(fontSize: 12, color: cs.onTertiaryContainer.withAlpha(200))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Two Pane Grid: Left Collections table, Right Customer Orders
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Customer Collections Breakdown
                          Expanded(
                            flex: 1,
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: cs.outlineVariant)),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Customer Money Collection', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    ...state.customerCollections.map(
                                      (c) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          children: [
                                            CircleAvatar(child: Text(c.customerName[0])),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(c.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  Text('${c.orderCount} orders • ${c.phone}', style: theme.textTheme.bodySmall),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text('₹${c.amountDue.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
                                                Text(c.status, style: TextStyle(fontSize: 10, color: cs.outline)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Customer Orders History
                          Expanded(
                            flex: 1,
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: cs.outlineVariant)),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Recent Orders & Customer Info', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    ...state.recentOrders.map(
                                      (ord) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: cs.primaryContainer,
                                              child: Icon(Icons.receipt_long, color: cs.onPrimaryContainer, size: 20),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(ord.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  Text('${ord.orderId} • ${ord.itemsSummary}', style: theme.textTheme.bodySmall),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text('₹${ord.totalAmount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
                                                Text(ord.status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
