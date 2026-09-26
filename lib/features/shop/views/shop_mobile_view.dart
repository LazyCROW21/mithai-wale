import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/models/category_model.dart';
import '../../../core/database/models/menu_item_model.dart';
import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../../cart/cart_providers.dart';
import '../shop_providers.dart';
import '../widgets/shop_quantity_control.dart';

class ShopMobileView extends ConsumerWidget {
  const ShopMobileView({super.key});

  static const _navItems = [
    NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.storefront), selectedIcon: Icon(Icons.storefront), label: 'Shop'),
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
    final shopState = ref.watch(shopViewModelProvider);
    final vm = ref.read(shopViewModelProvider.notifier);

    final categories = shopState.categories;
    final selectedCategory = shopState.selectedCategory;
    final products = shopState.availableProducts;

    final cartCount = ref.watch(cartProvider.select((c) => c.totalUniqueItems));

    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Sweets', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => AppNav.showAddToCart(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SearchBar(
            hintText: 'Search sweets & desserts…',
            leading: const Icon(Icons.search),
            onChanged: vm.setSearchQuery,
            padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
          ),
          const SizedBox(height: 16),
          Text('Categories', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length + 1, // +1 for 'All'
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                if (i == 0) {
                  final isSelected = selectedCategory == 'All';
                  return _CategoryChip(
                    label: 'All',
                    emoji: '✨',
                    isSelected: isSelected,
                    onTap: () => vm.selectCategory('All'),
                  );
                }
                final cat = categories[i - 1];
                final isSelected = selectedCategory.toLowerCase() == cat.name.toLowerCase();
                return _CategoryChip(
                  label: cat.name,
                  emoji: cat.emoji ?? '🍬',
                  isSelected: isSelected,
                  onTap: () => vm.selectCategory(cat.name),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Available Sweets', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                '${products.length} items',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 12),
                      const Text(
                        'No available products found',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedCategory != 'All'
                            ? 'No available sweets in category "$selectedCategory"'
                            : 'Products added in Menu will appear here',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.70,
              ),
              itemCount: products.length,
              itemBuilder: (context, i) {
                final product = products[i];
                final category = shopState.getCategoryFor(product);
                return _ProductCard(
                  product: product,
                  category: category,
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1, // Shop
        onDestinationSelected: (i) => AppNav.go(_navRoutes[i]),
        destinations: _navItems,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppNav.showAddToCart(),
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Cart'),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.emoji,
    this.isSelected = false,
    this.onTap,
  });

  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected ? cs.primary : cs.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: isSelected ? Border.all(color: cs.onPrimary, width: 2) : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                  : null,
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? cs.primary : null,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({
    required this.product,
    this.category,
  });

  final MenuItem product;
  final Category? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final emoji = category?.emoji ?? '🍬';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: cs.surfaceContainerHighest,
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 48))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: Theme.of(context).textTheme.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${product.price.toStringAsFixed(product.price.truncateToDouble() == product.price ? 0 : 2)}/${product.unit}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                ShopQuantityControl(
                  product: product,
                  compact: true,
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
