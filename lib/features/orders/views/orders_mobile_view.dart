import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../orders_providers.dart';
import '../widgets/order_card.dart';

class OrdersMobileView extends ConsumerWidget {
  const OrdersMobileView({super.key});

  static const _navItems = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home', route: AppRoutes.home),
    (icon: Icons.store_outlined, selectedIcon: Icons.store, label: 'Shop', route: AppRoutes.shop),
    (icon: Icons.restaurant_menu_outlined, selectedIcon: Icons.restaurant_menu, label: 'Menu', route: AppRoutes.menu),
    (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Orders', route: AppRoutes.orders),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', route: AppRoutes.profile),
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
      appBar: AppBar(
        title: const Text('Orders Management'),
        actions: [
          if (state.selectedDate != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                avatar: const Icon(Icons.calendar_today, size: 14),
                label: Text(_formatDate(state.selectedDate!)),
                onPressed: vm.clearDateFilter,
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              tooltip: 'Filter by Date',
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
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SearchBar(
              hintText: 'Search order item, customer name…',
              leading: const Icon(Icons.search, size: 20),
              onChanged: vm.setSearchQuery,
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),

          // Status Filter Chips
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                      labelStyle: const TextStyle(fontSize: 12),
                      label: Text('$status ($count)'),
                      selected: isSelected,
                      onSelected: (_) => vm.setStatusFilter(status),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

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
