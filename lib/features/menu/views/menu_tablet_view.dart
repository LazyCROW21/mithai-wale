import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/models/category_model.dart';
import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../../cart/cart_providers.dart';
import '../menu_providers.dart';
import '../widgets/add_edit_menu_item_dialog.dart';
import '../widgets/manage_categories_dialog.dart';
import '../widgets/menu_item_card.dart';

class MenuTabletView extends ConsumerWidget {
  const MenuTabletView({super.key});

  static const _navRoutes = [
    AppRoutes.home,
    AppRoutes.shop,
    AppRoutes.orders,
    AppRoutes.profile,
    AppRoutes.settings,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(menuViewModelProvider);
    final vm = ref.read(menuViewModelProvider.notifier);
    final cartCount = ref.watch(cartProvider.select((c) => c.totalUniqueItems));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          SizedBox(
            width: 240,
            child: SearchBar(
              hintText: 'Search items…',
              leading: const Icon(Icons.search),
              onChanged: vm.setSearchQuery,
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => showManageCategoriesModal(context),
            icon: const Icon(Icons.category_outlined),
            label: const Text('Categories'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => showAddEditMenuItemDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'View Cart',
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => AppNav.showAddToCart(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: 4, // Settings
            onDestinationSelected: (i) => AppNav.go(_navRoutes[i]),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
              NavigationRailDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: Text('Shop')),
              NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Orders')),
              NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profile')),
              NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                // Category Filter Bar
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cs.outlineVariant))),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Center(
                        child: FilterChip(
                          label: const Text('All Categories'),
                          selected: state.selectedCategoryFilter == 'All',
                          onSelected: (_) => vm.setCategoryFilter('All'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...state.categories.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Center(
                            child: FilterChip(
                              label: Text(c.name),
                              selected: state.selectedCategoryFilter == c.name,
                              onSelected: (_) => vm.setCategoryFilter(c.name),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Grid
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.filteredItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.restaurant_menu, size: 56, color: cs.outline),
                                  const SizedBox(height: 12),
                                  Text('No items found', style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 8),
                                  FilledButton.icon(
                                    onPressed: () => showAddEditMenuItemDialog(context),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Menu Item'),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.25,
                              ),
                              itemCount: state.filteredItems.length,
                              itemBuilder: (context, i) {
                                final item = state.filteredItems[i];
                                final Category? category = state.categories.cast<Category?>().firstWhere(
                                  (c) => c?.id == item.categoryId,
                                  orElse: () => null,
                                );

                                return MenuItemCard(
                                  product: item,
                                  category: category,
                                  onEdit: () => showAddEditMenuItemDialog(context, itemToEdit: item),
                                  onDelete: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Item?'),
                                        content: Text('Are you sure you want to delete "${item.title}"?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await vm.deleteMenuItem(item.id);
                                    }
                                  },
                                  onToggleAvailability: (_) => vm.toggleAvailability(item),
                                );
                              },
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
