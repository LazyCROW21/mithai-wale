import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../home_providers.dart';
import '../widgets/home_kpi_card.dart';
import '../widgets/menu_items_to_build_card.dart';
import '../widgets/order_highlight_section.dart';

class HomeTabletView extends ConsumerWidget {
  const HomeTabletView({super.key});

  static const _navRoutes = [
    AppRoutes.home,
    AppRoutes.shop,
    AppRoutes.orders,
    AppRoutes.profile,
    AppRoutes.settings,
  ];

  static String _formatCurrentDate() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(homeViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'मिठाई वाले',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Dashboard • ${_formatCurrentDate()}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () => ref.read(homeViewModelProvider.notifier).refreshDashboard(),
          ),
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
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: Text('Shop'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Orders'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Profile'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Top Summary KPI Row
                  Row(
                    children: [
                      Expanded(
                        child: HomeKpiCard(
                          title: 'Total Money to Collect',
                          value: '₹${state.todayMoneyToCollect.toStringAsFixed(0)}',
                          subtitle: '₹${state.todayNetReceived.toStringAsFixed(0)} collected • ${state.todayOrdersCount} today',
                          icon: Icons.account_balance_wallet_outlined,
                          backgroundColor: cs.primaryContainer,
                          foregroundColor: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: HomeKpiCard(
                          title: 'Total Orders',
                          value: '${state.totalOrdersCount}',
                          subtitle: '${state.todayOrdersCount} orders today',
                          icon: Icons.receipt_long_outlined,
                          backgroundColor: cs.tertiaryContainer,
                          foregroundColor: cs.onTertiaryContainer,
                          onTap: () => AppNav.go(AppRoutes.orders),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: HomeKpiCard(
                          title: 'Items to Build',
                          value: '${state.menuItemsToBuild.length}',
                          subtitle: 'From all orders',
                          icon: Icons.soup_kitchen_outlined,
                          backgroundColor: cs.secondaryContainer,
                          foregroundColor: cs.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2-Pane Split: Left Order Highlight, Right Menu Items to Build
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: OrderHighlightSection(),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        flex: 1,
                        child: MenuItemsToBuildCard(),
                      ),
                    ],
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
