import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../cart_providers.dart';
import '../models/cart_item_model.dart';
import 'edit_quantity_dialog.dart';

class CartSummarySheet extends ConsumerWidget {
  const CartSummarySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cart = ref.watch(cartProvider);
    final vm = ref.read(cartProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Drag Handle & Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              child: Row(
                children: [
                  Text(
                    'Cart Summary',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (cart.isNotEmpty)
                    Badge(
                      label: Text('${cart.totalUniqueItems}'),
                      backgroundColor: cs.primary,
                    ),
                  const Spacer(),
                  if (cart.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: cs.error),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Clear Cart?'),
                            content: const Text('Are you sure you want to remove all items from your cart?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          vm.clearCart();
                        }
                      },
                      icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                      label: const Text('Clear'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => AppNav.pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Cart Items or Empty State
            Flexible(
              child: cart.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove_shopping_cart_outlined, size: 64, color: cs.outline),
                          const SizedBox(height: 16),
                          Text(
                            'Your cart is empty',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Explore our delicious sweets and snacks to add items to your cart.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: cs.outline),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.tonal(
                            onPressed: () => AppNav.pop(),
                            child: const Text('Browse Menu'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final cartItem = cart.items.values.elementAt(index);
                        final item = cartItem.item;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Item Details: Title, price per unit, units
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      cartItem.summarySubtitle,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: cs.outline,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Total Price for this item
                                    Text(
                                      '₹${CartItem.formatNumber(cartItem.totalPrice)}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: cs.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Stepper Controls
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton.filledTonal(
                                    iconSize: 18,
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      final unit = CartItem.normalizedUnit(item.unit);
                                      final step = (unit == 'kg' || unit == 'litre') ? 0.5 : 1.0;
                                      vm.decrement(item.id, step);
                                    },
                                  ),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () => showEditQuantityDialog(
                                      context,
                                      item: item,
                                      currentQuantity: cartItem.quantity,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: cs.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        CartItem.formatNumber(cartItem.quantity),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    iconSize: 18,
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      final unit = CartItem.normalizedUnit(item.unit);
                                      final step = (unit == 'kg' || unit == 'litre') ? 0.5 : 1.0;
                                      vm.increment(item, step);
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, size: 20, color: cs.error),
                                    onPressed: () => vm.removeItem(item.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            if (cart.isNotEmpty) ...[
              const Divider(height: 1),
              // Cart Total & Checkout Footer
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total (${cart.totalUniqueItems} ${cart.totalUniqueItems == 1 ? 'item' : 'items'})',
                          style: theme.textTheme.titleMedium?.copyWith(color: cs.outline),
                        ),
                        Text(
                          '₹${CartItem.formatNumber(cart.totalPrice)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () {
                          AppNav.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Order placed for ₹${CartItem.formatNumber(cart.totalPrice)}!',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Proceed to Checkout', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
