import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/shop_filter.dart';
import '../orders_providers.dart';
import '../widgets/order_card.dart';
import '../widgets/orders_filter_toolbar.dart';

class OrdersTabletView extends ConsumerWidget {
  const OrdersTabletView({super.key});

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
                      const ShopFilterButton(),
                      const SizedBox(width: 8),
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
                                  onDateStatusChanged: (day, st) => vm.updateDateStatus(order.id, day, st),
 focusDate: state.isRange ? null : state.selectedDate,
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
