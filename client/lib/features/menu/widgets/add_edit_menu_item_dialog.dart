import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/models/menu_item_model.dart';
import '../../../core/layout/layout_extensions.dart';
import '../../../core/utils/image_utils.dart';
import '../menu_providers.dart';
import 'manage_categories_dialog.dart';

/// Shows Add/Edit Menu Item responsive dialog or bottom sheet.
Future<void> showAddEditMenuItemDialog(BuildContext context, {MenuItem? itemToEdit}) {
  if (context.isMobile) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddEditMenuItemForm(itemToEdit: itemToEdit),
    );
  } else {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 550,
          child: AddEditMenuItemForm(itemToEdit: itemToEdit),
        ),
      ),
    );
  }
}

class AddEditMenuItemForm extends ConsumerStatefulWidget {
  const AddEditMenuItemForm({super.key, this.itemToEdit});

  final MenuItem? itemToEdit;

  @override
  ConsumerState<AddEditMenuItemForm> createState() => _AddEditMenuItemFormState();
}

class _AddEditMenuItemFormState extends ConsumerState<AddEditMenuItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;

  int? _selectedCategoryId;
  String _selectedUnit = 'kg';
  bool _isAvailable = true;
  Uint8List? _selectedImageBytes;
  bool _isProcessingImage = false;

  static const _units = ['per piece', 'gm', 'kg', 'litre'];

  @override
  void initState() {
    super.initState();
    final item = widget.itemToEdit;
    _titleController = TextEditingController(text: item?.title ?? '');
    _descController = TextEditingController(text: item?.description ?? '');
    _priceController = TextEditingController(text: item != null ? item.price.toStringAsFixed(0) : '');
    _selectedCategoryId = item?.categoryId;
    _selectedUnit = item?.unit ?? 'kg';
    _isAvailable = item?.isAvailable ?? true;
    _selectedImageBytes = item?.imageBytes;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isProcessingImage = true);
    try {
      final bytes = await ImageUtils.pickAndCompressImage(
        source: source,
        maxDimension: 512,
        quality: 65,
      );
      if (bytes != null && mounted) {
        setState(() => _selectedImageBytes = bytes);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingImage = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final description = _descController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final vm = ref.read(menuViewModelProvider.notifier);

    if (widget.itemToEdit != null) {
      final updated = widget.itemToEdit!.copyWith(
        title: title,
        description: description.isEmpty ? null : description,
        categoryId: _selectedCategoryId,
        price: price,
        unit: _selectedUnit,
        isAvailable: _isAvailable,
        imageBytes: _selectedImageBytes,
      );
      await vm.updateMenuItem(updated);
    } else {
      await vm.addMenuItem(
        title: title,
        description: description.isEmpty ? null : description,
        categoryId: _selectedCategoryId,
        price: price,
        unit: _selectedUnit,
        isAvailable: _isAvailable,
        imageBytes: _selectedImageBytes,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(menuViewModelProvider.select((s) => s.categories));
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.itemToEdit != null;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Menu Item' : 'Add New Menu Item',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Image Upload Section (Max 512x512 pixels compressed)
            if (_selectedImageBytes != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _selectedImageBytes!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Item Image Selected',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Optimized JPEG (≤512×512 px) • Stored in Hive',
                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: _isProcessingImage ? null : () => _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.refresh, size: 14),
                                label: const Text('Change', style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: _isProcessingImage ? null : () => setState(() => _selectedImageBytes = null),
                                icon: Icon(Icons.delete_outline, size: 14, color: cs.error),
                                label: Text('Remove', style: TextStyle(fontSize: 12, color: cs.error)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              InkWell(
                onTap: _isProcessingImage ? null : () => _pickImage(ImageSource.gallery),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Center(
                    child: _isProcessingImage
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 12),
                              Text('Compressing image (max 512×512)...', style: TextStyle(fontSize: 13)),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 32, color: cs.primary),
                              const SizedBox(height: 6),
                              Text(
                                'Upload Item Image',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.onSurface),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Auto-resized to max 512×512 px and compressed for efficient storage',
                                style: TextStyle(fontSize: 11, color: cs.outline),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g. Motichoor Ladoo',
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter item title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g. Fresh pure ghee motichoor ladoo made with dry fruits',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Category Row (Dropdown + Add Category button)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Uncategorized'),
                      ),
                      ...categories.map(
                        (cat) => DropdownMenuItem<int?>(
                          value: cat.id,
                          child: Text(cat.name),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Manage Categories',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => showManageCategoriesModal(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Price and Unit Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Price (₹) *',
                      hintText: 'e.g. 480',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Enter price';
                      }
                      if (double.tryParse(val.trim()) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(),
                    ),
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedUnit = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Availability Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available for Sale'),
              subtitle: const Text('Disabling hides item from order taking'),
              value: _isAvailable,
              onChanged: (val) => setState(() => _isAvailable = val),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isProcessingImage ? null : _submit,
                  icon: Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(isEditing ? 'Save Changes' : 'Add Item'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
