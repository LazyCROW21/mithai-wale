import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../menu_providers.dart';
import '../widgets/add_edit_menu_item_dialog.dart';
import '../widgets/manage_categories_dialog.dart';

class MenuMobileView extends ConsumerWidget {
  const MenuMobileView({super.key});

  static const _navItems = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: 'Shop'),
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
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(menuViewModelProvider);
    final vm = ref.read(menuViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Manage Categories',
            icon: const Icon(Icons.category_outlined),
            onPressed: () => showManageCategoriesModal(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: 'Search menu items…',
              leading: const Icon(Icons.search),
              onChanged: vm.setSearchQuery,
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
            ),
          ),

          // Categories horizontal scroll
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: state.selectedCategoryFilter == 'All',
                  onSelected: (_) => vm.setCategoryFilter('All'),
                ),
                const SizedBox(width: 8),
                ...state.categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('${c.emoji ?? '🍬'} ${c.name}'),
                        selected: state.selectedCategoryFilter == c.name,
                        onSelected: (_) => vm.setCategoryFilter(c.name),
                      ),
                    )),
              ],
            ),
          ),

          const Divider(height: 1),

          // Items list
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu, size: 48, color: cs.outline),
                            const SizedBox(height: 12),
                            Text('No menu items found', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: () => showAddEditMenuItemDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Menu Item'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.filteredItems.length,
                        itemBuilder: (context, i) {
                          final item = state.filteredItems[i];
                          final category = state.categories.firstWhere(
                            (c) => c.id == item.categoryId,
                            orElse: () => Category(id: -1, name: 'Uncategorized', emoji: null, createdAt: DateTime.now()),
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: cs.primaryContainer,
                                    child: Text(category.emoji ?? '🍬', style: const TextStyle(fontSize: 20)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '#MW-${item.id.toString().padLeft(4, '0')}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: cs.primary,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: cs.secondaryContainer,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                category.name,
                                                style: TextStyle(fontSize: 10, color: cs.onSecondaryContainer),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        if (item.description != null && item.description!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item.description!,
                                            style: Theme.of(context).textTheme.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Text(
                                          '₹${item.price.toStringAsFixed(0)} / ${item.unit}',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Switch(
                                        value: item.isAvailable,
                                        onChanged: (_) => vm.toggleAvailability(item),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 20),
                                            onPressed: () => showAddEditMenuItemDialog(context, itemToEdit: item),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline, size: 20, color: cs.error),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddEditMenuItemDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 4, // Settings / Menu
        onDestinationSelected: (i) => AppNav.go(_navRoutes[i]),
        destinations: _navItems,
      ),
    );
  }
}
