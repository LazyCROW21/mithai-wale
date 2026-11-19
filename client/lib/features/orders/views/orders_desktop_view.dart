import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/shop_filter.dart';
import '../orders_providers.dart';
import '../widgets/order_card.dart';
import '../widgets/orders_filter_toolbar.dart';
import '../../../core/widgets/refresh_button.dart';

class OrdersDesktopView extends ConsumerWidget {
  const OrdersDesktopView({super.key});

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
                      const ShopFilterButton(),
                      const SizedBox(width: 8),
                      RefreshButton(onPressed: () => vm.loadOrders()),
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
                                onDateStatusChanged: (day, st) => vm.updateDateStatus(order.id, day, st),
 focusDate: state.isRange ? null : state.selectedDate,
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
