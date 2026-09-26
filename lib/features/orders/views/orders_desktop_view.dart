import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../orders_providers.dart';
import '../widgets/order_card.dart';

class OrdersDesktopView extends ConsumerWidget {
  const OrdersDesktopView({super.key});

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
          // Side Navigation Drawer
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
                // Top Header Toolbar
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
                      const SizedBox(width: 24),
                      // Search Bar (search by order item, customer name)
                      SizedBox(
                        width: 320,
                        child: SearchBar(
                          hintText: 'Search order item, customer name…',
                          leading: const Icon(Icons.search, size: 20),
                          onChanged: vm.setSearchQuery,
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 14),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Filter by Date Picker button
                      if (state.selectedDate != null)
                        Chip(
                          avatar: const Icon(Icons.calendar_today, size: 16),
                          label: Text(_formatDate(state.selectedDate!)),
                          onDeleted: vm.clearDateFilter,
                          deleteIcon: const Icon(Icons.close, size: 16),
                        )
                      else
                        OutlinedButton.icon(
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
                          label: const Text('Filter by Date'),
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
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    border: Border(bottom: BorderSide(color: cs.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Status:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _statusOptions.map((status) {
                            final count = status == 'All'
                                ? state.allOrders.length
                                : state.allOrders.where((o) => o.status.toLowerCase() == status.toLowerCase()).length;
                            final isSelected = state.statusFilter == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
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
                    ],
                  ),
                ),

                // Orders List
                Expanded(
                  child: filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: cs.outline),
                              const SizedBox(height: 16),
                              Text('No orders found', style: theme.textTheme.headlineSmall),
                              const SizedBox(height: 8),
                              Text(
                                'Try clearing your search query or adjusting your filters.',
                                style: TextStyle(color: cs.outline),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () {
                                  vm.setSearchQuery('');
                                  vm.setStatusFilter('All');
                                  vm.clearDateFilter();
                                },
                                icon: const Icon(Icons.filter_alt_off),
                                label: const Text('Reset All Filters'),
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
