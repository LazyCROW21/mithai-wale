import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/shop_filter.dart';
import '../../../core/widgets/account_menu_button.dart';
import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../../../l10n/l10n.dart';
import '../home_providers.dart';
import '../widgets/home_kpi_card.dart';
import '../widgets/menu_items_to_build_card.dart';
import '../widgets/order_highlight_section.dart';

class HomeDesktopView extends ConsumerWidget {
  const HomeDesktopView({super.key});

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
                      const ShopFilterButton(),
                      const AccountMenuButton(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh Dashboard Data',
                        onPressed: () => ref.read(homeViewModelProvider.notifier).refreshDashboard(),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => AppNav.showCreateOrder(),
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
                              // Today's deliveries only (the card below lists the next 7 days).
 value: '${state.todayItemsToBuild.length}',
                              subtitle: context.l10n.homeItemsToBuildTodayDesc,
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
