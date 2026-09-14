import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../home_providers.dart';

class HomeTabletView extends ConsumerWidget {
  const HomeTabletView({super.key});

  static const _navRoutes = [
    AppRoutes.home,
    AppRoutes.shop,
    AppRoutes.orders,
    AppRoutes.profile,
    AppRoutes.settings,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(homeViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('मिठाई वाले', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(6)),
              child: Text('Dashboard', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
            ),
          ],
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => AppNav.go(AppRoutes.shop),
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Start Order'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: 0, // Home
            onDestinationSelected: (i) => AppNav.go(_navRoutes[i]),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard), selectedIcon: Icon(Icons.dashboard), label: Text('Home')),
              NavigationRailDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: Text('Shop')),
              NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Orders')),
              NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profile')),
              NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Pane: Financials & Items Sum
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Money Collection Card
                        Card(
                          elevation: 0,
                          color: cs.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Money to Collect Today', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
                                    Chip(
                                      label: Text('${state.customerCollections.length} Customers'),
                                      backgroundColor: cs.surface,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('₹${state.totalMoneyToCollect.toStringAsFixed(0)}', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                Text('Customer Breakdown:', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
                                const SizedBox(height: 8),
                                ...state.customerCollections.map(
                                  (c) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      children: [
                                        CircleAvatar(radius: 14, child: Text(c.customerName[0])),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(c.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              Text('${c.orderCount} Orders • ${c.phone}', style: theme.textTheme.bodySmall),
                                            ],
                                          ),
                                        ),
                                        Text('₹${c.amountDue.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Middle Sum Card (Total Items)
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: cs.outlineVariant)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Text('Total Items Count Across Overall Orders', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  decoration: BoxDecoration(color: cs.secondaryContainer.withAlpha(120), borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    children: [
                                      Text('Sum = ${state.totalItemsSum}', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: cs.onSecondaryContainer)),
                                      const SizedBox(height: 4),
                                      const Text('(e.g., 3 + 2 + 5 cakes / items overall)', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: state.itemSummaries.map((item) {
                                    return Chip(
                                      avatar: Text(item.emoji),
                                      label: Text('${item.name}: ${item.quantity} ${item.unit}'),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Right Pane: Recent Orders & Customer Details
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Today\'s Orders', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            Chip(label: Text('${state.totalOrdersCount} Orders Today'), backgroundColor: cs.primaryContainer),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.recentOrders.length,
                          itemBuilder: (context, i) {
                            final ord = state.recentOrders[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: cs.primaryContainer,
                                  child: Icon(Icons.receipt_long, color: cs.onPrimaryContainer, size: 20),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(ord.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('₹${ord.totalAmount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text('${ord.orderId} • ${ord.time} • ${ord.customerPhone}', style: theme.textTheme.bodySmall),
                                    Text(ord.itemsSummary, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: ord.status == 'Ready' ? Colors.green.withAlpha(30) : Colors.orange.withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(ord.status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppNav.go(AppRoutes.shop),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Start Order'),
      ),
    );
  }
}
