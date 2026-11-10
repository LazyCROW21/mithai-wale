import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../orders_providers.dart';
import '../widgets/order_card.dart';
import '../widgets/orders_filter_toolbar.dart';

class OrdersMobileView extends ConsumerWidget {
  const OrdersMobileView({super.key});

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
      appBar: AppBar(
        title: const Text('Orders Management', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Between status select and page title: Search + Date filter row, followed by multi-select Statuses
          const OrdersFilterToolbar(),

          // List of Order Cards
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
                            Icon(Icons.receipt_long_outlined, size: 48, color: cs.outline),
                            const SizedBox(height: 12),
                            Text('No orders found', style: theme.textTheme.titleMedium),
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
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        final isExpanded = state.expandedOrderIds.contains(order.id);
                        return OrderCard(
                          order: order,
                          isExpanded: isExpanded,
                          onToggleExpand: () => vm.toggleExpanded(order.id),
                          onStatusChanged: (newStatus) => vm.updateOrderStatus(order.id, newStatus),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
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
