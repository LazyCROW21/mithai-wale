import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../home_providers.dart';

class HomeMobileView extends ConsumerWidget {
  const HomeMobileView({super.key});

  static const _navItems = [
    NavigationDestination(icon: Icon(Icons.dashboard), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Shop'),
    NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
    NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
  ];

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
        title: Column(
          children: [
            Text('मिठाई वाले', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text('Dashboard • Summary Today', style: theme.textTheme.labelSmall?.copyWith(color: cs.primary)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── SECTION 1: Total Money to Collect Today (Customer-wise + Overall) ──
          Card(
            elevation: 0,
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: cs.onPrimaryContainer),
                          const SizedBox(width: 8),
                          Text(
                            'Money to Collect Today',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.surface.withAlpha(200),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${state.customerCollections.length} Customers',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₹${state.totalMoneyToCollect.toStringAsFixed(0)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Overall pending collection balance today',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onPrimaryContainer.withAlpha(200)),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Text(
                    'Customer-wise Breakdown:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
                  ),
                  const SizedBox(height: 8),
                  ...state.customerCollections.map(
                    (c) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: cs.primary.withAlpha(40),
                            child: Text(c.customerName[0], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('${c.orderCount} Orders • ${c.phone}', style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${c.amountDue.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: c.status == 'Paid'
                                      ? Colors.green.withAlpha(30)
                                      : Colors.amber.withAlpha(40),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  c.status,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: c.status == 'Paid' ? Colors.green[800] : Colors.amber[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── SECTION 2: Total Items Count (Middle Sum Metric e.g., 3+2+5 = 10) ──
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: cs.outlineVariant)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, color: cs.primary),
                      const SizedBox(width: 8),
                      Text('Total Items Count Across Overall Orders', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Middle Sum Display (e.g. 3 + 2 + 5 = 10)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withAlpha(120),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Sum = ${state.totalItemsSum}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: cs.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '(e.g., 3 + 2 + 5 cakes / items ordered today)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Itemized Summary:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.itemSummaries.map((item) {
                      return Chip(
                        avatar: Text(item.emoji),
                        label: Text('${item.name}: ${item.quantity} ${item.unit}'),
                        backgroundColor: cs.surfaceContainerHighest,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── SECTION 3: Total Orders & Recent Customer Orders ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Customer Orders', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: cs.primary.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '${state.totalOrdersCount} Orders Today',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: cs.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, i) {
              final ord = state.recentOrders[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
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
                      Text(ord.itemsSummary, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ord.status == 'Ready'
                          ? Colors.green.withAlpha(30)
                          : ord.status == 'Preparing'
                              ? Colors.orange.withAlpha(30)
                              : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ord.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: ord.status == 'Ready'
                            ? Colors.green[800]
                            : ord.status == 'Preparing'
                                ? Colors.orange[900]
                                : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0, // Home
        onDestinationSelected: (i) => AppNav.go(_navRoutes[i]),
        destinations: _navItems,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppNav.go(AppRoutes.shop),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Start Order'),
      ),
    );
  }
}
