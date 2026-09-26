import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../../orders/orders_providers.dart';
import '../cart_providers.dart';
import '../models/cart_item_model.dart';

/// Shows a dialog to confirm customer details and place an order.
Future<void> showCheckoutDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const CheckoutDialog(),
  );
}

class CheckoutDialog extends ConsumerStatefulWidget {
  const CheckoutDialog({super.key});

  @override
  ConsumerState<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<CheckoutDialog> {
  final _nameController = TextEditingController(text: 'Walk-in Customer');
  final _phoneController = TextEditingController(text: '+91 98765 43210');
  DateTime _deliveryDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _submitOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      final order = await ref.read(cartProvider.notifier).checkout(
            customerName: name.isEmpty ? 'Walk-in Customer' : name,
            customerPhone: phone.isEmpty ? '+91 98765 43210' : phone,
            deliveryDate: _deliveryDate,
          );

      if (!mounted) return;

      if (order != null) {
        // Update Riverpod Orders state immediately
        ref.read(ordersViewModelProvider.notifier).addOrder(order);

        // Pop checkout dialog
        Navigator.of(context).pop();

        // Also pop the cart summary sheet if open
        AppNav.pop();

        // Show confirmation snackbar with action to view orders
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            content: Text(
              'Order ${order.id} placed with status "Placed" (₹${CartItem.formatNumber(order.totalBill)})',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'View Orders',
              textColor: Theme.of(context).colorScheme.primary,
              onPressed: () {
                AppNav.go(AppRoutes.orders);
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cart = ref.watch(cartProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Title & Initial Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Confirm Order',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 14, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          'Status: Placed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Order Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cart.totalUniqueItems} ${cart.totalUniqueItems == 1 ? 'item' : 'items'} in cart',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total Payable',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.outline,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹${CartItem.formatNumber(cart.totalPrice)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Customer Name Field
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              // Customer Phone Field
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              // Delivery Date Selector
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _deliveryDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _deliveryDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 18, color: cs.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Date',
                              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                            ),
                            Text(
                              _formatDate(_deliveryDate),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submitOrder,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.shopping_bag_outlined),
                    label: Text(_isSubmitting ? 'Placing...' : 'Place Order'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
