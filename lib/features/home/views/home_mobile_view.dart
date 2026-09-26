import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../home_providers.dart';
import '../widgets/home_kpi_card.dart';
import '../widgets/menu_items_to_build_card.dart';
import '../widgets/order_highlight_section.dart';

class HomeMobileView extends ConsumerWidget {
  const HomeMobileView({super.key});

  static const _navItems = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.storefront_outlined),
      selectedIcon: Icon(Icons.storefront),
      label: 'Shop',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: 'Orders',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

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
        title: Column(
          children: [
            Text(
              'मिठाई वाले',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Dashboard • ${_formatCurrentDate()}',
              style: theme.textTheme.labelSmall?.copyWith(color: cs.primary),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(homeViewModelProvider.notifier).refreshDashboard(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── SECTION 1: Top KPI Cards ──
          Row(
            children: [
              Expanded(
                child: HomeKpiCard(
                  title: "Today's Collection",
                  value: '₹${state.todayMoneyCollection.toStringAsFixed(0)}',
                  subtitle: '${state.todayOrdersCount} today',
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
                  subtitle: '${state.todayOrdersCount} today',
                  icon: Icons.receipt_long_outlined,
                  backgroundColor: cs.tertiaryContainer,
                  foregroundColor: cs.onTertiaryContainer,
                  onTap: () => AppNav.go(AppRoutes.orders),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── SECTION 2: Today's Order Highlight (Customer + Total + 1-line item list) ──
          const OrderHighlightSection(),
          const SizedBox(height: 20),

          // ── SECTION 3: Menu Items to Build from All Orders (eg: Ladoo = 12 kg (total 5 orders)) ──
          const MenuItemsToBuildCard(),
          const SizedBox(height: 80), // Padding for floating action button
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
