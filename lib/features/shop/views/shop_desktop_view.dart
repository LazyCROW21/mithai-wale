import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/models/category_model.dart';
import '../../../core/database/models/menu_item_model.dart';
import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../../cart/cart_providers.dart';
import '../../cart/models/cart_item_model.dart';
import '../shop_providers.dart';
import '../shop_state.dart';
import '../widgets/shop_quantity_control.dart';

class ShopDesktopView extends ConsumerWidget {
  const ShopDesktopView({super.key});

  static const _navItems = [
    (icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Home', route: AppRoutes.home),
    (icon: Icons.storefront_outlined, selectedIcon: Icons.storefront, label: 'Shop', route: AppRoutes.shop),
    (icon: Icons.restaurant_menu_outlined, selectedIcon: Icons.restaurant_menu, label: 'Menu', route: AppRoutes.menu),
    (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Orders', route: AppRoutes.orders),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', route: AppRoutes.profile),
    (icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings', route: AppRoutes.settings),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final shopState = ref.watch(shopViewModelProvider);
    final vm = ref.read(shopViewModelProvider.notifier);

    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: 1, // Shop index
            onDestinationSelected: (i) => AppNav.go(_navItems[i].route),
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
                  onChanged: vm.setSearchQuery,
                  padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 4),
                child: Text('SHOPPING', style: TextStyle(fontSize: 11, letterSpacing: 1.4)),
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
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _DesktopToolbar(
                  categories: shopState.categories,
                  selectedCategory: shopState.selectedCategory,
                  onCategoryChanged: vm.selectCategory,
                ),
                Expanded(
                  child: _DesktopProductGrid(
                    products: shopState.availableProducts,
                    shopState: shopState,
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          const SizedBox(width: 300, child: _CartPanel()),
        ],
      ),
    );
  }
}

class _DesktopToolbar extends StatelessWidget {
  const _DesktopToolbar({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final List<Category> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categoryList = ['All', ...categories.map((c) => c.name)];

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: cs.surface, border: Border(bottom: BorderSide(color: cs.outlineVariant))),
      child: Row(
        children: [
          Text('Shop Products', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 24),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categoryList.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final catName = categoryList[i];
                final selected = catName.toLowerCase() == selectedCategory.toLowerCase();
                String labelText = catName;
                if (i > 0) {
                  final catObj = categories[i - 1];
                  if (catObj.emoji != null && catObj.emoji!.isNotEmpty) {
                    labelText = '${catObj.emoji} $catName';
                  }
                } else {
                  labelText = '✨ All';
                }

                return FilterChip(
                  label: Text(labelText),
                  selected: selected,
                  onSelected: (_) => onCategoryChanged(catName),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopProductGrid extends ConsumerWidget {
  const _DesktopProductGrid({
    required this.products,
    required this.shopState,
  });

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
            Icon(Icons.inventory_2_outlined, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            const Text(
              'No products available in shop catalog',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              shopState.selectedCategory != 'All'
                  ? 'No available sweets in category "${shopState.selectedCategory}"'
                  : 'Products added in Menu will appear here',
              style: TextStyle(color: cs.outline, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.82,
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
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 56))),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, style: Theme.of(context).textTheme.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(p.unit, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${p.price.toStringAsFixed(p.price.truncateToDouble() == p.price ? 0 : 2)}',
                          style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        ShopQuantityControl(product: p),
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

class _CartPanel extends ConsumerWidget {
  const _CartPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cart = ref.watch(cartProvider);
    final cartItems = cart.items.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: cs.surface, border: Border(bottom: BorderSide(color: cs.outlineVariant))),
          child: Row(
            children: [
              Text('Cart Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Badge(
                isLabelVisible: cart.isNotEmpty,
                label: Text('${cart.totalUniqueItems}'),
                child: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        Expanded(
          child: cart.isEmpty
              ? const Center(
                  child: Text('Your cart is empty', style: TextStyle(color: Colors.grey)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, i) {
                    final cartItem = cartItems[i];
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cartItem.item.title, style: theme.textTheme.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(cartItem.summarySubtitle, style: theme.textTheme.bodySmall?.copyWith(color: cs.outline)),
                            ],
                          ),
                        ),
                        Text('₹${CartItem.formatNumber(cartItem.totalPrice)}', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
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
                  Text('Total Amount', style: theme.textTheme.titleMedium),
                  Text('₹${CartItem.formatNumber(cart.totalPrice)}', style: theme.textTheme.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: cart.isEmpty ? null : () => AppNav.showAddToCart(),
                icon: const Icon(Icons.payment),
                label: const Text('Checkout Order'),
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
