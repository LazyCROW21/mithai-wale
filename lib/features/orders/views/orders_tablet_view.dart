import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../orders_providers.dart';
import '../widgets/order_card.dart';
import '../widgets/orders_filter_toolbar.dart';

class OrdersTabletView extends ConsumerWidget {
  const OrdersTabletView({super.key});

  static const _navItems = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home', route: AppRoutes.home),
    (icon: Icons.store_outlined, selectedIcon: Icons.store, label: 'Shop', route: AppRoutes.shop),
    (icon: Icons.restaurant_menu_outlined, selectedIcon: Icons.restaurant_menu, label: 'Menu', route: AppRoutes.menu),
    (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Orders', route: AppRoutes.orders),
    (icon: Icons.account_balance_wallet_outlined, selectedIcon: Icons.account_balance_wallet, label: 'Ledger', route: AppRoutes.ledger),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', route: AppRoutes.profile),
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
          // Navigation Rail
          NavigationRail(
            selectedIndex: 3,
            onDestinationSelected: (i) => AppNav.go(_navItems[i].route),
            labelType: NavigationRailLabelType.selected,
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

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Header Toolbar: Page Title
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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

                // List of Orders
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => vm.loadOrders(),
                    child: filteredOrders.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 56, color: cs.outline),
                                  const SizedBox(height: 12),
                                  Text('No orders found', style: theme.textTheme.titleLarge),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Date: ${state.dateTitle}',
                                    style: TextStyle(color: cs.outline, fontSize: 13),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      vm.setSearchQuery('');
                                      vm.resetDefaultStatuses();
                                      vm.setDateFilter(DateTime.now());
                                    },
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Reset to Today & Default Statuses'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = filteredOrders[index];
                              final isExpanded = state.expandedOrderIds.contains(order.id);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
