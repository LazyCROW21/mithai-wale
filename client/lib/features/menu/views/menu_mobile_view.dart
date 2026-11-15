import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/database/models/category_model.dart';
import '../menu_providers.dart';
import '../widgets/add_edit_menu_item_dialog.dart';
import '../widgets/manage_categories_dialog.dart';
import '../widgets/menu_item_card.dart';

class MenuMobileView extends ConsumerWidget {
  const MenuMobileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(menuViewModelProvider);
    final vm = ref.read(menuViewModelProvider.notifier);
    // Employees can view the catalog but not change it (server: owner/manager write).
    final canEdit = ref.watch(sessionProvider).role != AppRole.employee;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Menu Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (canEdit)
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
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16),
              ),
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
                ...state.categories.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(c.name),
                      selected: state.selectedCategoryFilter == c.name,
                      onSelected: (_) => vm.setCategoryFilter(c.name),
                    ),
                  ),
                ),
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
                        Icon(
                          Icons.restaurant_menu,
                          size: 48,
                          color: cs.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No menu items found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (canEdit)
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
                      final Category? category = state.categories
                          .cast<Category?>()
                          .firstWhere(
                            (c) => c?.id == item.categoryId,
                            orElse: () => null,
                          );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MenuItemCard(
                          product: item,
                          category: category,
                          onEdit: () => showAddEditMenuItemDialog(
                            context,
                            itemToEdit: item,
                          ),
                          onDelete: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Item?'),
                                content: Text(
                                  'Are you sure you want to delete "${item.title}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await vm.deleteMenuItem(item.id);
                            }
                          },
                          onToggleAvailability: (_) =>
                              vm.toggleAvailability(item),
                          readOnly: !canEdit,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: !canEdit
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showAddEditMenuItemDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
    );
  }
}
