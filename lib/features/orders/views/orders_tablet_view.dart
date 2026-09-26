import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../orders_providers.dart';
import '../widgets/order_card.dart';

class OrdersTabletView extends ConsumerWidget {
  const OrdersTabletView({super.key});

  static const _navItems = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home', route: AppRoutes.home),
    (icon: Icons.store_outlined, selectedIcon: Icons.store, label: 'Shop', route: AppRoutes.shop),
    (icon: Icons.restaurant_menu_outlined, selectedIcon: Icons.restaurant_menu, label: 'Menu', route: AppRoutes.menu),
    (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Orders', route: AppRoutes.orders),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', route: AppRoutes.profile),
    (icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings', route: AppRoutes.settings),
  ];

  static const _statusOptions = [
    'All',
    'Placed',
    'Preparing',
    'Ready',
    'Delivering',
    'Delivered',
    'Completed',
    'Cancelled',
  ];

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

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
                // Top Header Toolbar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(bottom: BorderSide(color: cs.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Orders',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      // Search Bar
                      Expanded(
                        child: SearchBar(
                          hintText: 'Search item or customer…',
                          leading: const Icon(Icons.search, size: 20),
                          onChanged: vm.setSearchQuery,
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Date Filter
                      if (state.selectedDate != null)
                        Chip(
                          avatar: const Icon(Icons.calendar_today, size: 14),
                          label: Text(_formatDate(state.selectedDate!)),
                          onDeleted: vm.clearDateFilter,
                          deleteIcon: const Icon(Icons.close, size: 14),
                        )
                      else
                        IconButton.outlined(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2025),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              vm.setSelectedDate(picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_month_outlined, size: 18),
                          tooltip: 'Filter by Date',
                        ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        onPressed: () => vm.loadOrders(),
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: 'Refresh Orders',
                      ),
                    ],
                  ),
                ),

                // Status Filter Bar
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    border: Border(bottom: BorderSide(color: cs.outlineVariant)),
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _statusOptions.map((status) {
                      final count = status == 'All'
                          ? state.allOrders.length
                          : state.allOrders.where((o) => o.status.toLowerCase() == status.toLowerCase()).length;
                      final isSelected = state.statusFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Center(
                          child: FilterChip(
                            label: Text('$status ($count)'),
                            selected: isSelected,
                            onSelected: (_) => vm.setStatusFilter(status),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Orders List
                Expanded(
                  child: filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 48, color: cs.outline),
                              const SizedBox(height: 12),
                              Text('No orders found', style: theme.textTheme.titleMedium),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  vm.setSearchQuery('');
                                  vm.setStatusFilter('All');
                                  vm.clearDateFilter();
                                },
                                icon: const Icon(Icons.filter_alt_off, size: 16),
                                label: const Text('Reset Filters'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
