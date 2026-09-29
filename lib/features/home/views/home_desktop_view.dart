import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../home_providers.dart';
import '../widgets/home_kpi_card.dart';
import '../widgets/menu_items_to_build_card.dart';
import '../widgets/order_highlight_section.dart';

class HomeDesktopView extends ConsumerWidget {
  const HomeDesktopView({super.key});

  static const _navItems = [
    (icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Home', route: AppRoutes.home),
    (icon: Icons.storefront_outlined, selectedIcon: Icons.storefront, label: 'Shop', route: AppRoutes.shop),
    (icon: Icons.restaurant_menu_outlined, selectedIcon: Icons.restaurant_menu, label: 'Menu', route: AppRoutes.menu),
    (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Orders', route: AppRoutes.orders),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', route: AppRoutes.profile),
    (icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings', route: AppRoutes.settings),
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
      body: Row(
        children: [
          // Left Navigation Drawer
          NavigationDrawer(
            selectedIndex: 0, // Home Dashboard index
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
                child: Text('DASHBOARD', style: TextStyle(fontSize: 11, letterSpacing: 1.4)),
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

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Header Toolbar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(bottom: BorderSide(color: cs.outlineVariant.withAlpha(100))),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Business Dashboard',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      Chip(
                        avatar: Icon(Icons.calendar_today, size: 14, color: cs.primary),
                        label: Text(_formatCurrentDate()),
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh Dashboard Data',
                        onPressed: () => ref.read(homeViewModelProvider.notifier).refreshDashboard(),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => AppNav.go(AppRoutes.shop),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Start New Order'),
                      ),
                    ],
                  ),
                ),

                // Dashboard Main Body Scrollable
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(32),
                    children: [
                      // Top 3 KPI Metric Cards
                      Row(
                        children: [
                          // Card 1: Total Money to Collect
                          Expanded(
                            child: HomeKpiCard(
                              title: 'Total Money to Collect',
                              value: '₹${state.todayMoneyToCollect.toStringAsFixed(0)}',
                              subtitle: '₹${state.todayNetReceived.toStringAsFixed(0)} collected • ${state.todayOrdersCount} orders',
                              icon: Icons.account_balance_wallet_outlined,
                              backgroundColor: cs.primaryContainer,
                              foregroundColor: cs.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Card 2: Total Order Count
                          Expanded(
                            child: HomeKpiCard(
                              title: 'Total Order Count',
                              value: '${state.totalOrdersCount}',
                              subtitle: '${state.todayOrdersCount} placed / delivering today',
                              icon: Icons.receipt_long_outlined,
                              backgroundColor: cs.tertiaryContainer,
                              foregroundColor: cs.onTertiaryContainer,
                              onTap: () => AppNav.go(AppRoutes.orders),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Card 3: Menu Items to Build
                          Expanded(
                            child: HomeKpiCard(
                              title: 'Menu Items to Build',
                              value: '${state.menuItemsToBuild.length}',
                              subtitle: 'Aggregated from all orders',
                              icon: Icons.soup_kitchen_outlined,
                              backgroundColor: cs.secondaryContainer,
                              foregroundColor: cs.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Two-Pane Main Layout:
                      // Left: Today's Order Highlight (customer + total + 1 line item list)
                      // Right: Total Menu Items to Build from All Orders (eg: Ladoo = 12 kg (total 5 orders))
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Pane: Today's Order Highlight
                          Expanded(
                            flex: 6,
                            child: OrderHighlightSection(),
                          ),
                          SizedBox(width: 24),

                          // Right Pane: Total Menu Items to Build
                          Expanded(
                            flex: 5,
                            child: MenuItemsToBuildCard(),
                          ),
                        ],
                      ),
                    ],
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
