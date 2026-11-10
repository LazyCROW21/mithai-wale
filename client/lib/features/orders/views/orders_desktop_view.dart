import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../orders_providers.dart';
import '../widgets/order_card.dart';
import '../widgets/orders_filter_toolbar.dart';

class OrdersDesktopView extends ConsumerWidget {
  const OrdersDesktopView({super.key});

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
    final state = ref.watch(ordersViewModelProvider);
    final vm = ref.read(ordersViewModelProvider.notifier);
    final filteredOrders = state.filteredOrders;

    return Scaffold(
      body: Row(
        children: [
          // Navigation Drawer
          NavigationDrawer(
            selectedIndex: 3, // Orders selected
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
                // Top Header: Page Title
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(bottom: BorderSide(color: cs.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Orders Management',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton.outlined(
                        onPressed: () => vm.loadOrders(),
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: 'Refresh Orders',
                      ),
                    ],
                  ),
                ),

                // Between page title and status select: Search + Date filter row, then Multi-Select Statuses
                const OrdersFilterToolbar(),

                // Main Content Body (List of Order Cards)
                Expanded(
                  child: filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: cs.outline),
                              const SizedBox(height: 16),
                              Text('No orders found', style: theme.textTheme.headlineSmall),
                              const SizedBox(height: 6),
                              Text(
                                'Filtered by: ${state.dateTitle}',
                                style: TextStyle(color: cs.outline, fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () {
                                  vm.setSearchQuery('');
                                  vm.resetDefaultStatuses();
                                  vm.setDateFilter(DateTime.now());
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reset to Today & Default Statuses'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = filteredOrders[index];
                            final isExpanded = state.expandedOrderIds.contains(order.id);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: OrderCard(
                                order: order,
                                isExpanded: isExpanded,
                                onToggleExpand: () => vm.toggleExpanded(order.id),
                                onStatusChanged: (newStatus) => vm.updateOrderStatus(order.id, newStatus),
                              ),
                            );
                          },
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
