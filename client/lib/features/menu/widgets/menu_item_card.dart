import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../../core/database/models/category_model.dart';
import '../../../core/database/models/menu_item_model.dart';
import '../../../core/utils/format_utils.dart';

class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    super.key,
    required this.product,
    this.category,
    this.onEdit,
    this.onDelete,
    this.onToggleAvailability,
    this.readOnly = false,
  });

  final MenuItem product;
  final Category? category;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleAvailability;

  /// Hides the edit/delete/stock options (e.g. for employees).
  final bool readOnly;

  void _showFullImage(BuildContext context, String title, Uint8List bytes) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppBar(
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 512, maxHeight: 512),
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final unit = normalizedUnit(product.unit);
    final priceLabel = 'Rs. ${formatNumber(product.price)}/$unit';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant, width: 1.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isFiniteHeight = constraints.maxHeight.isFinite;
          return Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: isFiniteHeight
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              children: [
                // Header Row: Optional Uploaded Image, Title (line 1), Category (sub title), and Actions Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // If item has an uploaded image, show it cleanly (no icon if no image)
                    if (product.imageBytes != null) ...[
                      Tooltip(
                        message: 'Tap to view full image',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _showFullImage(
                            context,
                            product.title,
                            product.imageBytes!,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: cs.outlineVariant),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.memory(
                                product.imageBytes!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

                    // First line: Title of item | Subtitle: Category (NO item ID, NO icon)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // First line: Title of item
                          Text(
                            product.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Sub title: Category
                          Text(
                            category?.name ?? 'General',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Popup menu for Edit / Delete / Out of stock toggle
                    if (!readOnly &&
                        (onEdit != null ||
                            onDelete != null ||
                            onToggleAvailability != null))
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 20,
                          color: cs.outline,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Item options',
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit?.call();
                          } else if (value == 'delete') {
                            onDelete?.call();
                          } else if (value == 'toggle') {
                            onToggleAvailability?.call(!product.isAvailable);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(
                              children: [
                                Icon(
                                  product.isAvailable
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  product.isAvailable
                                      ? 'Mark Out of Stock'
                                      : 'Mark In Stock',
                                ),
                              ],
                            ),
                          ),
                          if (onEdit != null)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit Item'),
                                ],
                              ),
                            ),
                          if (onDelete != null)
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: cs.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delete Item',
                                    style: TextStyle(color: cs.error),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),

                // Item Description
                if (product.description != null &&
                    product.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    product.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.outline,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                if (isFiniteHeight)
                  const Spacer()
                else
                  const SizedBox(height: 14),

                // Price and Stock status
                Row(
                  children: [
                    Text(
                      priceLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    const Spacer(),
                    if (!product.isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.errorContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Out of Stock',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: cs.onErrorContainer,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
