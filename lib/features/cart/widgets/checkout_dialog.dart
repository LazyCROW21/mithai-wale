import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/models/order_model.dart';
import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../../orders/orders_providers.dart';
import '../cart_providers.dart';
import '../models/cart_item_model.dart';

/// Shows a dialog to confirm customer details, apply discount, and place an order.
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
  final _discountController = TextEditingController();

  DateTime _deliveryDate = DateTime.now();
  DiscountType? _discountType;
  String? _discountError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  double get _discountAmount {
    final parsed = double.tryParse(_discountController.text.trim()) ?? 0.0;
    return parsed < 0 ? 0.0 : parsed;
  }

  double _getCalculatedDiscount(double subtotal) {
    if (_discountType == null || _discountAmount <= 0) return 0.0;
    if (_discountType == DiscountType.percentage) {
      return (subtotal * _discountAmount) / 100.0;
    }
    return _discountAmount.clamp(0.0, subtotal);
  }

  bool _validateDiscount(double subtotal) {
    setState(() => _discountError = null);
    if (_discountType == null) {
      return true;
    }
    final text = _discountController.text.trim();
    if (text.isEmpty) {
      setState(() => _discountError = 'Enter discount value or select "None"');
      return false;
    }
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      setState(() => _discountError = 'Discount must be greater than 0');
      return false;
    }
    if (_discountType == DiscountType.percentage) {
      if (amount >= 100) {
        setState(() => _discountError = 'Percentage discount must be less than 100%');
        return false;
      }
    } else if (_discountType == DiscountType.flat) {
      if (amount >= subtotal) {
        setState(() => _discountError =
            'Flat discount must be less than bill subtotal (₹${subtotal.toStringAsFixed(2)})');
        return false;
      }
    }
    return true;
  }

  Future<void> _submitOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    if (!_validateDiscount(cart.totalPrice)) {
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
            discountType: _discountType,
            discountAmount: _discountType == null ? 0.0 : _discountAmount,
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

    final subtotal = cart.totalPrice;
    final discount = _getCalculatedDiscount(subtotal);
    final finalPayable = (subtotal - discount).clamp(0.0, double.infinity);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
        child: SingleChildScrollView(
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
              const SizedBox(height: 16),

              // Discount Section
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.discount_outlined, size: 18, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Add Discount',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('None'),
                          selected: _discountType == null,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _discountType = null;
                                _discountController.clear();
                                _discountError = null;
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Percentage (%)'),
                          selected: _discountType == DiscountType.percentage,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _discountType = DiscountType.percentage;
                                _discountError = null;
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Flat (₹)'),
                          selected: _discountType == DiscountType.flat,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _discountType = DiscountType.flat;
                                _discountError = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (_discountType != null) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _discountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: InputDecoration(
                          labelText: _discountType == DiscountType.percentage
                              ? 'Discount Percentage (e.g. 10 for 10%)'
                              : 'Flat Discount in ₹',
                          prefixIcon: Icon(
                            _discountType == DiscountType.percentage
                                ? Icons.percent
                                : Icons.currency_rupee,
                            size: 18,
                          ),
                          errorText: _discountError,
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (_) {
                          setState(() => _discountError = null);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Order Summary & Breakdown Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${cart.totalUniqueItems} ${cart.totalUniqueItems == 1 ? 'item' : 'items'} in cart',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹${CartItem.formatNumber(subtotal)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (_discountType != null && discount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _discountType == DiscountType.percentage
                                ? 'Discount ($_discountAmount%)'
                                : 'Flat Discount',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '-₹${CartItem.formatNumber(discount)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Payable',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${CartItem.formatNumber(finalPayable)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                    style: FilledButton.styleFrom(
                      elevation: 3,
                      shadowColor: Colors.black45,
                    ),
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
