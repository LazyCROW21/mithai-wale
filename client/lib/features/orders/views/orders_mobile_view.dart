import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/shop_filter.dart';
import '../orders_providers.dart';
import '../widgets/order_card.dart';
import '../widgets/orders_filter_toolbar.dart';

class OrdersMobileView extends ConsumerWidget {
  const OrdersMobileView({super.key});

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
        actions: const [ShopFilterButton(), SizedBox(width: 8)],
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
                          onDateStatusChanged: (day, st) => vm.updateDateStatus(order.id, day, st),
 focusDate: state.isRange ? null : state.selectedDate,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
