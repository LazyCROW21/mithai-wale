import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/shop_filter.dart';
import '../../../core/widgets/account_menu_button.dart';
import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../home_providers.dart';
import '../widgets/home_kpi_card.dart';
import '../widgets/menu_items_to_build_card.dart';
import '../widgets/order_highlight_section.dart';

class HomeMobileView extends ConsumerWidget {
  const HomeMobileView({super.key});

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
          const ShopFilterButton(),
          const AccountMenuButton(),
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
                  title: 'To Collect',
                  value: '₹${state.todayMoneyToCollect.toStringAsFixed(0)}',
                  subtitle: '₹${state.todayNetReceived.toStringAsFixed(0)} collected',
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
          const SizedBox(height: 96), // Clearance for the shell's new-order button
        ],
      ),
    );
  }
}
