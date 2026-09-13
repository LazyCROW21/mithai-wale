import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../home_providers.dart';

/// Desktop/laptop layout for the Home feature.
///
/// Uses [ConsumerWidget] — nav index and category filter come from
/// [homeViewModelProvider], not local widget state.
class HomeDesktopView extends ConsumerWidget {
  const HomeDesktopView({super.key});

  static const _navItems = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home', route: AppRoutes.home),
    (icon: Icons.store_outlined, selectedIcon: Icons.store, label: 'Shop', route: AppRoutes.shop),
    (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Orders', route: AppRoutes.orders),
    (icon: Icons.analytics_outlined, selectedIcon: Icons.analytics, label: 'Reports', route: AppRoutes.reports),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', route: AppRoutes.profile),
    (icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings', route: AppRoutes.settings),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final navIndex = ref.watch(homeViewModelProvider.select((s) => s.selectedNavIndex));
    final selectedCategory = ref.watch(homeViewModelProvider.select((s) => s.selectedCategory));
    final vm = ref.read(homeViewModelProvider.notifier);

    return Scaffold(
      body: Row(
        children: [
          // ── Persistent Navigation Drawer ─────────────────────
          NavigationDrawer(
            selectedIndex: navIndex,
            onDestinationSelected: (i) {
              vm.selectNavItem(i);
              AppNav.go(_navItems[i].route);
            },
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 16, 10),
                child: Text(
                  'मिठाई वाले',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SearchBar(
                  hintText: 'Search sweets…',
                  leading: const Icon(Icons.search, size: 18),
                  padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 4),
                child: Text('MENU', style: TextStyle(fontSize: 11, letterSpacing: 1.4)),
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
          // ── Main content ──────────────────────────────────────
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _DesktopToolbar(
                  selectedCategory: selectedCategory,
                  onCategoryChanged: vm.selectCategory,
                ),
                const Expanded(child: _DesktopProductGrid()),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // ── Cart panel ────────────────────────────────────────
          const SizedBox(width: 300, child: _CartPanel()),
        ],
      ),
    );
  }
}

class _DesktopToolbar extends StatelessWidget {
  const _DesktopToolbar({required this.selectedCategory, required this.onCategoryChanged});
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  static const _categories = ['All', 'Ladoo', 'Barfi', 'Halwa', 'Peda', 'Rasgulla', 'Jalebi', 'Chamcham', 'Gulab Jamun'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: cs.surface, border: Border(bottom: BorderSide(color: cs.outlineVariant))),
      child: Row(
        children: [
          Text('Products', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 24),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 4),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final selected = cat == selectedCategory;
                return FilterChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => onCategoryChanged(cat),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          IconButton.outlined(icon: const Icon(Icons.filter_list), onPressed: () {}),
          const SizedBox(width: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'grid', icon: Icon(Icons.grid_view, size: 18)),
              ButtonSegment(value: 'list', icon: Icon(Icons.view_list, size: 18)),
            ],
            selected: const {'grid'},
            onSelectionChanged: (_) {},
          ),
        ],
      ),
    );
  }
}

class _DesktopProductGrid extends StatelessWidget {
  const _DesktopProductGrid();

  static const _products = [
    (id: '1', name: 'Motichoor Ladoo', price: 480, emoji: '🟡', unit: '1 kg'),
    (id: '2', name: 'Kaju Barfi', price: 720, emoji: '🍬', unit: '500 g'),
    (id: '3', name: 'Gajar Halwa', price: 360, emoji: '🍮', unit: '1 kg'),
    (id: '4', name: 'Milk Peda', price: 400, emoji: '🟤', unit: '500 g'),
    (id: '5', name: 'Rasgulla', price: 320, emoji: '⚪', unit: '12 pcs'),
    (id: '6', name: 'Jalebi', price: 280, emoji: '🌀', unit: '1 kg'),
    (id: '7', name: 'Chamcham', price: 500, emoji: '🍡', unit: '500 g'),
    (id: '8', name: 'Gulab Jamun', price: 350, emoji: '🟠', unit: '12 pcs'),
    (id: '9', name: 'Soan Papdi', price: 260, emoji: '🧁', unit: '500 g'),
    (id: '10', name: 'Mysore Pak', price: 580, emoji: '🟨', unit: '500 g'),
    (id: '11', name: 'Imarti', price: 300, emoji: '🔶', unit: '1 kg'),
    (id: '12', name: 'Kheer Kadam', price: 420, emoji: '🟫', unit: '6 pcs'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _products.length,
      itemBuilder: (context, i) {
        final p = _products[i];
        return GestureDetector(
          onTap: () => AppNav.showProductDetail(p.id),
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    color: cs.surfaceContainerHighest,
                    child: Center(child: Text(p.emoji, style: const TextStyle(fontSize: 56))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: Theme.of(context).textTheme.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(p.unit, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('₹${p.price}', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                          FilledButton.tonal(
                            onPressed: () => AppNav.showAddToCart(),
                            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), minimumSize: Size.zero),
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel();

  static const _cartItems = [
    (name: 'Motichoor Ladoo', price: 480, qty: 2, emoji: '🟡'),
    (name: 'Kaju Barfi', price: 720, qty: 1, emoji: '🍬'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final total = _cartItems.fold<int>(0, (sum, item) => sum + item.price * item.qty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: cs.surface, border: Border(bottom: BorderSide(color: cs.outlineVariant))),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart_outlined),
              const SizedBox(width: 8),
              Text('Cart', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Badge(label: Text('${_cartItems.length}'), child: const SizedBox.shrink()),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _cartItems.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, i) {
              final item = _cartItems[i];
              return Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: theme.textTheme.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('₹${item.price} × ${item.qty}', style: theme.textTheme.bodySmall?.copyWith(color: cs.outline)),
                      ],
                    ),
                  ),
                  Text('₹${item.price * item.qty}', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: theme.textTheme.titleMedium),
                  Text('₹$total', style: theme.textTheme.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => AppNav.showAddToCart(),
                icon: const Icon(Icons.payment),
                label: const Text('Checkout'),
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
