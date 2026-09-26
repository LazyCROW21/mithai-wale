import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/models/category_model.dart';
import '../../../core/database/models/menu_item_model.dart';
import '../../cart/cart_providers.dart';
import '../../cart/models/cart_item_model.dart';
import '../../cart/widgets/edit_quantity_dialog.dart';

class MenuItemCard extends ConsumerWidget {
  const MenuItemCard({
    super.key,
    required this.product,
    this.category,
    this.onEdit,
    this.onDelete,
    this.onToggleAvailability,
  });

  final MenuItem product;
  final Category? category;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleAvailability;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Reactively watch this specific item's quantity in cart
    final quantity = ref.watch(
      cartProvider.select((cart) => cart.getQuantity(product.id)),
    );
    final isInCart = quantity > 0;
    final cartVm = ref.read(cartProvider.notifier);

    final normalizedUnit = CartItem.normalizedUnit(product.unit);
    final step = (normalizedUnit == 'kg' || normalizedUnit == 'litre') ? 0.5 : 1.0;
    final priceLabel =
        'Rs. ${CartItem.formatNumber(product.price)}/$normalizedUnit';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isInCart ? cs.primary.withValues(alpha: 0.5) : cs.outlineVariant,
          width: isInCart ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Avatar, Item ID / Category, and Actions Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.primaryContainer,
                  child: const Icon(Icons.restaurant_menu, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#MW-${product.id.toString().padLeft(4, '0')}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category?.name ?? 'General',
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onEdit != null || onDelete != null || onToggleAvailability != null)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 20, color: cs.outline),
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
                              product.isAvailable ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(product.isAvailable ? 'Mark Out of Stock' : 'Mark In Stock'),
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
                              Icon(Icons.delete_outline, size: 18, color: cs.error),
                              const SizedBox(width: 8),
                              Text('Delete Item', style: TextStyle(color: cs.error)),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Item Title
            Text(
              product.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Item Description
            if (product.description != null && product.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                product.description!,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const Spacer(),

            // Price and Weight Label (e.g. Rs. 50/kg, Rs. 50/pc, Rs. 50/gm)
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            const SizedBox(height: 10),

            // Action: "Add to cart" or "- {qty} +" Stepper Control
            if (!product.isAvailable)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Unavailable'),
                ),
              )
            else if (!isInCart)
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    // Instantly add to cart without any modal or pop-up!
                    cartVm.addItem(product, 1.0);
                  },
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              )
            else
              // Dynamic "- {qty} +" Quantity Control
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    // Decrement button
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      color: cs.onPrimaryContainer,
                      onPressed: () => cartVm.decrement(product.id, step),
                    ),

                    // Tappable Quantity Display: Opens modal to edit quantity directly
                    Expanded(
                      child: Tooltip(
                        message: 'Tap to edit quantity',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => showEditQuantityDialog(
                            context,
                            item: product,
                            currentQuantity: quantity,
                          ),
                          child: Center(
                            child: Text(
                              '${CartItem.formatNumber(quantity)} $normalizedUnit',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: cs.onPrimaryContainer,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Increment button
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      color: cs.onPrimaryContainer,
                      onPressed: () => cartVm.increment(product, step),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
