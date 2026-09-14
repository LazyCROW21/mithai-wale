import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../menu_providers.dart';
import '../widgets/add_edit_menu_item_dialog.dart';
import '../widgets/manage_categories_dialog.dart';

class MenuDesktopView extends ConsumerWidget {
  const MenuDesktopView({super.key});

  static const _navItems = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home', route: AppRoutes.home),
    (icon: Icons.store_outlined, selectedIcon: Icons.store, label: 'Shop', route: AppRoutes.shop),
    (icon: Icons.restaurant_menu_outlined, selectedIcon: Icons.restaurant_menu, label: 'Menu', route: AppRoutes.menu),
    (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Orders', route: AppRoutes.orders),
    (icon: Icons.analytics_outlined, selectedIcon: Icons.analytics, label: 'Reports', route: AppRoutes.reports),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', route: AppRoutes.profile),
    (icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings', route: AppRoutes.settings),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(menuViewModelProvider);
    final vm = ref.read(menuViewModelProvider.notifier);

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
                              label: Text('${c.emoji ?? '🍬'} ${c.name}'),
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
                                childAspectRatio: 1.45,
                              ),
                              itemCount: state.filteredItems.length,
                              itemBuilder: (context, i) {
                                final item = state.filteredItems[i];
                                final category = state.categories.firstWhere(
                                  (c) => c.id == item.categoryId,
                                  orElse: () => Category(id: -1, name: 'Uncategorized', emoji: null, createdAt: DateTime.now()),
                                );

                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: cs.outlineVariant),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: cs.primaryContainer,
                                              child: Text(category.emoji ?? '🍬', style: const TextStyle(fontSize: 20)),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '#MW-${item.id.toString().padLeft(4, '0')}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: cs.primary,
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                  Text(
                                                    category.name,
                                                    style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Tooltip(
                                              message: item.isAvailable ? 'In Stock' : 'Out of Stock',
                                              child: Switch(
                                                value: item.isAvailable,
                                                onChanged: (_) => vm.toggleAvailability(item),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          item.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.description != null && item.description!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            item.description!,
                                            style: theme.textTheme.bodySmall,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        const Spacer(),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '₹${item.price.toStringAsFixed(0)} / ${item.unit}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: cs.primary,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton.outlined(
                                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                                  onPressed: () => showAddEditMenuItemDialog(context, itemToEdit: item),
                                                ),
                                                const SizedBox(width: 6),
                                                IconButton.outlined(
                                                  icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                                                  onPressed: () async {
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
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
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
