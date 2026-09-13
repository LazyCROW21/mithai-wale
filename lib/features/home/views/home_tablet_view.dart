import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../home_providers.dart';

/// Tablet layout for the Home feature.
///
/// Uses [ConsumerWidget] — nav index and category filter are read from
/// [homeViewModelProvider], not local widget state.
class HomeTabletView extends ConsumerWidget {
  const HomeTabletView({super.key});

  static const _navRoutes = [
    AppRoutes.home,
    AppRoutes.shop,
    AppRoutes.orders,
    AppRoutes.profile,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final navIndex = ref.watch(homeViewModelProvider.select((s) => s.selectedNavIndex));
    final vm = ref.read(homeViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('मिठाई वाले', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          SizedBox(
            width: 280,
            child: SearchBar(
              hintText: 'Search sweets…',
              leading: const Icon(Icons.search),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // ── Navigation Rail ──────────────────────────────────
          NavigationRail(
            selectedIndex: navIndex,
            onDestinationSelected: (i) {
              vm.selectNavItem(i);
              AppNav.go(_navRoutes[i]);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
              NavigationRailDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: Text('Shop')),
              NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Orders')),
              NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profile')),
            ],
          ),
          const VerticalDivider(width: 1),
          // ── Content Area ─────────────────────────────────────
          Expanded(
            child: _TabletBody(ref: ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppNav.showAddToCart(),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Add to Cart'),
      ),
    );
  }
}

class _TabletBody extends ConsumerWidget {
  const _TabletBody({required this.ref});
  // ignore: unused_field
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(homeViewModelProvider.select((s) => s.selectedCategory));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: Categories panel ────────────────────────────
        SizedBox(
          width: 180,
          child: _CategoriesPanel(
            selectedCategory: selectedCategory,
            onCategorySelected: ref.read(homeViewModelProvider.notifier).selectCategory,
          ),
        ),
        const VerticalDivider(width: 1),
        // ── Right: Product grid ───────────────────────────────
        const Expanded(child: _ProductGrid(crossAxisCount: 3)),
      ],
    );
  }
}

class _CategoriesPanel extends StatelessWidget {
  const _CategoriesPanel({required this.selectedCategory, required this.onCategorySelected});
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categories = ['All', 'Ladoo', 'Barfi', 'Halwa', 'Peda', 'Rasgulla', 'Jalebi', 'Chamcham'];
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text('Categories', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.outline)),
        ),
        const SizedBox(height: 8),
        ...categories.map(
          (c) => ListTile(
            dense: true,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            title: Text(c),
            selected: c == selectedCategory,
            selectedColor: cs.onPrimaryContainer,
            selectedTileColor: cs.primaryContainer,
            onTap: () => onCategorySelected(c),
          ),
        ),
        const Divider(),
        Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(colors: [cs.primary, cs.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Festival 🎉', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('20% off all sweets', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onPrimary.withAlpha(200))),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.crossAxisCount});
  final int crossAxisCount;

  static const _products = [
    (id: '1', name: 'Motichoor Ladoo', price: 480, emoji: '🟡'),
    (id: '2', name: 'Kaju Barfi', price: 720, emoji: '🍬'),
    (id: '3', name: 'Gajar Halwa', price: 360, emoji: '🍮'),
    (id: '4', name: 'Milk Peda', price: 400, emoji: '🟤'),
    (id: '5', name: 'Rasgulla', price: 320, emoji: '⚪'),
    (id: '6', name: 'Jalebi', price: 280, emoji: '🌀'),
    (id: '7', name: 'Chamcham', price: 500, emoji: '🍡'),
    (id: '8', name: 'Gulab Jamun', price: 350, emoji: '🟠'),
    (id: '9', name: 'Soan Papdi', price: 260, emoji: '🧁'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
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
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: Theme.of(context).textTheme.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('₹${p.price}/kg', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
                          IconButton.filledTonal(
                            iconSize: 18,
                            onPressed: () => AppNav.showAddToCart(),
                            icon: const Icon(Icons.add),
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
