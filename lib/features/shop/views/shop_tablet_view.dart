import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/models/category_model.dart';
import '../../../core/database/models/menu_item_model.dart';
import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../../cart/cart_providers.dart';
import '../shop_providers.dart';
import '../shop_state.dart';
import '../widgets/shop_quantity_control.dart';

class ShopTabletView extends ConsumerWidget {
  const ShopTabletView({super.key});

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
    final shopState = ref.watch(shopViewModelProvider);
    final vm = ref.read(shopViewModelProvider.notifier);
    final cartCount = ref.watch(cartProvider.select((c) => c.totalUniqueItems));

    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Catalog', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          SizedBox(
            width: 280,
            child: SearchBar(
              hintText: 'Search sweets…',
              leading: const Icon(Icons.search),
              onChanged: vm.setSearchQuery,
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => AppNav.showAddToCart(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: 1, // Shop
            onDestinationSelected: (i) => AppNav.go(_navRoutes[i]),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Home')),
              NavigationRailDestination(icon: Icon(Icons.storefront), selectedIcon: Icon(Icons.storefront), label: Text('Shop')),
              NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Orders')),
              NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profile')),
              NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 200,
                  child: _CategoriesPanel(
                    categories: shopState.categories,
                    selectedCategory: shopState.selectedCategory,
                    onCategorySelected: vm.selectCategory,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _ProductGrid(
                    crossAxisCount: 3,
                    products: shopState.availableProducts,
                    shopState: shopState,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppNav.showAddToCart(),
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Cart'),
      ),
    );
  }
}

class _CategoriesPanel extends StatelessWidget {
  const _CategoriesPanel({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final List<Category> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text('Categories', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.outline)),
        ),
        const SizedBox(height: 8),
        ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          leading: const Text('✨', style: TextStyle(fontSize: 18)),
          title: const Text('All Sweets'),
          selected: selectedCategory == 'All',
          selectedColor: cs.onPrimaryContainer,
          selectedTileColor: cs.primaryContainer,
          onTap: () => onCategorySelected('All'),
        ),
        ...categories.map(
          (c) => ListTile(
            dense: true,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            leading: Text(c.emoji ?? '🍬', style: const TextStyle(fontSize: 18)),
            title: Text(c.name),
            selected: c.name.toLowerCase() == selectedCategory.toLowerCase(),
            selectedColor: cs.onPrimaryContainer,
            selectedTileColor: cs.primaryContainer,
            onTap: () => onCategorySelected(c.name),
          ),
        ),
      ],
    );
  }
}

class _ProductGrid extends ConsumerWidget {
  const _ProductGrid({
    required this.crossAxisCount,
    required this.products,
    required this.shopState,
  });

  final int crossAxisCount;
  final List<MenuItem> products;
  final ShopState shopState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 56, color: cs.outline),
            const SizedBox(height: 12),
            const Text(
              'No products available in shop catalog',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              shopState.selectedCategory != 'All'
                  ? 'No available sweets in category "${shopState.selectedCategory}"'
                  : 'Products added in Menu will appear here',
              style: TextStyle(color: cs.outline, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: products.length,
      itemBuilder: (context, i) {
        final p = products[i];
        final cat = shopState.getCategoryFor(p);
        final emoji = cat?.emoji ?? '🍬';

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: cs.surfaceContainerHighest,
                  child: p.imageBytes != null
                      ? Image.memory(p.imageBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                      : Center(child: Text(emoji, style: const TextStyle(fontSize: 56))),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, style: Theme.of(context).textTheme.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${p.price.toStringAsFixed(p.price.truncateToDouble() == p.price ? 0 : 2)}/${p.unit}',
                          style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
                        ),
                        ShopQuantityControl(
                          product: p,
                          compact: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
