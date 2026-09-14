import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/layout/layout_extensions.dart';
import '../menu_providers.dart';

/// Shows category management responsive modal (Bottom Sheet on Mobile, Dialog on Tablet/Desktop).
Future<void> showManageCategoriesModal(BuildContext context) {
  if (context.isMobile) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const ManageCategoriesSheet(),
    );
  } else {
    return showDialog(
      context: context,
      builder: (context) => const Dialog(
        child: SizedBox(
          width: 500,
          child: ManageCategoriesSheet(),
        ),
      ),
    );
  }
}

class ManageCategoriesSheet extends ConsumerStatefulWidget {
  const ManageCategoriesSheet({super.key});

  @override
  ConsumerState<ManageCategoriesSheet> createState() => _ManageCategoriesSheetState();
}

class _ManageCategoriesSheetState extends ConsumerState<ManageCategoriesSheet> {
  final _nameController = TextEditingController();
  final _emojiController = TextEditingController();
  Category? _editingCategory;

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _emojiController.clear();
    setState(() {
      _editingCategory = null;
    });
  }

  void _editCategory(Category cat) {
    setState(() {
      _editingCategory = cat;
      _nameController.text = cat.name;
      _emojiController.text = cat.emoji ?? '';
    });
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final emoji = _emojiController.text.trim();
    final vm = ref.read(menuViewModelProvider.notifier);

    if (_editingCategory != null) {
      await vm.updateCategory(_editingCategory!.copyWith(name: name, emoji: Value(emoji.isEmpty ? null : emoji)));
    } else {
      await vm.addCategory(name: name, emoji: emoji.isEmpty ? null : emoji);
    }

    _resetForm();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(menuViewModelProvider.select((s) => s.categories));
    final vm = ref.read(menuViewModelProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manage Categories',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Category entry form
          Card(
            color: cs.surfaceContainerLow,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 54,
                    child: TextField(
                      controller: _emojiController,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: '🟡',
                        labelText: 'Emoji',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Barfi',
                        labelText: 'Category Name',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saveCategory,
                    child: Text(_editingCategory != null ? 'Update' : 'Add'),
                  ),
                  if (_editingCategory != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined),
                      onPressed: _resetForm,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Existing Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Flexible(
            child: categories.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No categories added yet.')),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final cat = categories[i];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: cs.primaryContainer,
                          radius: 18,
                          child: Text(cat.emoji ?? '🍬', style: const TextStyle(fontSize: 16)),
                        ),
                        title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('ID: #${cat.id}', style: TextStyle(fontSize: 11, color: cs.outline)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _editCategory(cat),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Category?'),
                                    content: Text('Are you sure you want to delete "${cat.name}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                      FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await vm.deleteCategory(cat.id);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
