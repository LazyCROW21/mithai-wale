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

class MenuDesktopView extends ConsumerWidget {
  const MenuDesktopView({super.key});

  static const _navItems = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home', route: AppRoutes.home),
    (icon: Icons.store_outlined, selectedIcon: Icons.store, label: 'Shop', route: AppRoutes.shop),
    (icon: Icons.restaurant_menu_outlined, selectedIcon: Icons.restaurant_menu, label: 'Menu', route: AppRoutes.menu),
    (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Orders', route: AppRoutes.orders),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', route: AppRoutes.profile),
    (icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings', route: AppRoutes.settings),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(menuViewModelProvider);
    final vm = ref.read(menuViewModelProvider.notifier);
    final cartCount = ref.watch(cartProvider.select((c) => c.totalUniqueItems));

    return Scaffold(
      body: Row(
        children: [
          // Navigation Drawer
          NavigationDrawer(
            selectedIndex: 2, // Menu Management selected
            onDestinationSelected: (i) => AppNav.go(_navItems[i].route),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 16, 10),
                child: Text(
                  'मिठाई वाले',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 4),
                child: Text('MANAGEMENT', style: TextStyle(fontSize: 11, letterSpacing: 1.4)),
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

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Header Toolbar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(bottom: BorderSide(color: cs.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Menu Management',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 280,
                        child: SearchBar(
                          hintText: 'Search items…',
                          leading: const Icon(Icons.search, size: 20),
                          onChanged: vm.setSearchQuery,
                          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => showManageCategoriesModal(context),
                        icon: const Icon(Icons.category_outlined),
                        label: const Text('Manage Categories'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () => showAddEditMenuItemDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Menu Item'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonalIcon(
                        onPressed: () => AppNav.showAddToCart(),
                        icon: Badge(
                          isLabelVisible: cartCount > 0,
                          label: Text('$cartCount'),
                          child: const Icon(Icons.shopping_cart_outlined, size: 20),
                        ),
                        label: const Text('Cart'),
                      ),
                    ],
                  ),
                ),

                // Category Filter Bar
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    border: Border(bottom: BorderSide(color: cs.outlineVariant)),
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Center(
                        child: FilterChip(
                          label: const Text('All Items'),
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

                // Main Content Body (Grid view of cards)
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.filteredItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.restaurant_menu, size: 64, color: cs.outline),
                                  const SizedBox(height: 16),
                                  Text('No menu items found', style: theme.textTheme.headlineSmall),
                                  const SizedBox(height: 8),
                                  Text('Add items to start managing your Mithai shop menu.', style: TextStyle(color: cs.outline)),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () => showAddEditMenuItemDialog(context),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add First Menu Item'),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(24),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
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
