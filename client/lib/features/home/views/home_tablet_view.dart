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
import '../../../core/widgets/refresh_button.dart';

class HomeTabletView extends ConsumerWidget {
  const HomeTabletView({super.key});

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
          const ShopFilterButton(),
          const AccountMenuButton(),
          RefreshButton(
            onPressed: () => ref.read(homeViewModelProvider.notifier).refreshDashboard(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
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
    );
  }
}
