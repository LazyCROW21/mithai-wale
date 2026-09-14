import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../shop_providers.dart';

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
    final vm = ref.read(shopViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Sweets', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
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
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _CategoryChip(
                label: _categories[i].label,
                emoji: _categories[i].emoji,
                onTap: () => vm.selectCategory(_categories[i].label),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Available Sweets', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: _demoProducts.length,
            itemBuilder: (context, i) => _ProductCard(product: _demoProducts[i]),
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
  const _CategoryChip({required this.label, required this.emoji, this.onTap});
  final String label;
  final String emoji;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final _Product product;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => AppNav.showProductDetail(product.id),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: cs.surfaceContainerHighest,
                child: Center(child: Text(product.emoji, style: const TextStyle(fontSize: 48))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: Theme.of(context).textTheme.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${product.price}/${product.unit}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
                      IconButton.filledTonal(
                        iconSize: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
  }
}

class _Category {
  const _Category({required this.label, required this.emoji});
  final String label;
  final String emoji;
}

class _Product {
  const _Product({required this.id, required this.name, required this.price, required this.emoji, required this.unit});
  final String id;
  final String name;
  final int price;
  final String emoji;
  final String unit;
}

const _categories = [
  _Category(label: 'Ladoo', emoji: '🟡'),
  _Category(label: 'Barfi', emoji: '🍬'),
  _Category(label: 'Halwa', emoji: '🍮'),
  _Category(label: 'Peda', emoji: '🟤'),
  _Category(label: 'Rasgulla', emoji: '⚪'),
  _Category(label: 'Jalebi', emoji: '🌀'),
];

const _demoProducts = [
  _Product(id: '1', name: 'Motichoor Ladoo', price: 480, emoji: '🟡', unit: 'kg'),
  _Product(id: '2', name: 'Kaju Barfi', price: 720, emoji: '🍬', unit: 'kg'),
  _Product(id: '3', name: 'Gajar Halwa', price: 360, emoji: '🍮', unit: 'kg'),
  _Product(id: '4', name: 'Milk Peda', price: 400, emoji: '🟤', unit: 'kg'),
  _Product(id: '5', name: 'Rasgulla', price: 320, emoji: '⚪', unit: 'pcs'),
  _Product(id: '6', name: 'Jalebi', price: 280, emoji: '🌀', unit: 'kg'),
];
