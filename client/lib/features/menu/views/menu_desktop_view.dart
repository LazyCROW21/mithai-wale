import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/database/models/category_model.dart';
import '../menu_providers.dart';
import '../widgets/add_edit_menu_item_dialog.dart';
import '../widgets/manage_categories_dialog.dart';
import '../widgets/menu_item_card.dart';

class MenuDesktopView extends ConsumerWidget {
  const MenuDesktopView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(menuViewModelProvider);
    final vm = ref.read(menuViewModelProvider.notifier);
    // Employees can view the catalog but not change it (server: owner/manager write).
    final canEdit = ref.watch(sessionProvider).role != AppRole.employee;

    return Scaffold(
      body: Row(
        children: [
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
                    border: Border(
                      bottom: BorderSide(color: cs.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Menu Management',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 280,
                        child: SearchBar(
                          hintText: 'Search items…',
                          leading: const Icon(Icons.search, size: 20),
                          onChanged: vm.setSearchQuery,
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 14),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (canEdit)
                        OutlinedButton.icon(
                          onPressed: () => showManageCategoriesModal(context),
                          icon: const Icon(Icons.category_outlined),
                          label: const Text('Manage Categories'),
                        ),
                      if (canEdit) const SizedBox(width: 12),
                      if (canEdit)
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
                    border: Border(
                      bottom: BorderSide(color: cs.outlineVariant),
                    ),
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
                              Icon(
                                Icons.restaurant_menu,
                                size: 64,
                                color: cs.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No menu items found',
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add items to start managing your Mithai shop menu.',
                                style: TextStyle(color: cs.outline),
                              ),
                              const SizedBox(height: 16),
                              if (canEdit)
                                FilledButton.icon(
                                  onPressed: () =>
                                      showAddEditMenuItemDialog(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add First Menu Item'),
                                ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.25,
                              ),
                          itemCount: state.filteredItems.length,
                          itemBuilder: (context, i) {
                            final item = state.filteredItems[i];
                            final Category? category = state.categories
                                .cast<Category?>()
                                .firstWhere(
                                  (c) => c?.id == item.categoryId,
                                  orElse: () => null,
                                );

                            return MenuItemCard(
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
