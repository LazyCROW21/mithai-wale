import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/models/order_model.dart';
import '../../../core/layout/layout_extensions.dart';
import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../../orders/orders_providers.dart';
import '../cart_providers.dart';
import '../models/cart_item_model.dart';

/// Shows a dialog to confirm customer details, apply discount, and place an order.
///
/// On mobile devices, displays in full-screen mode to take maximum comfortable space.
/// On tablet and desktop devices, displays as a spacious wide dialog.
Future<void> showCheckoutDialog(BuildContext context) {
  if (context.isMobile) {
    return showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (context) => const Dialog.fullscreen(
        child: CheckoutDialog(),
      ),
    );
  } else {
    return showDialog<void>(
      context: context,
      builder: (context) => const CheckoutDialog(),
    );
  }
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

        // Show confirmation snackbar with action to view orders & dismiss
        final messenger = ScaffoldMessenger.of(context);
        final theme = Theme.of(context);
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: theme.colorScheme.primaryContainer,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Row(
              children: [
                Expanded(
                  child: Text(
                    'Order ${order.id} placed with status "Placed" (₹${CartItem.formatNumber(order.totalBill)})',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 1.5,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    AppNav.go(AppRoutes.orders);
                  },
                  child: const Text(
                    'View Orders',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    elevation: 1,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    side: BorderSide(
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.35),
                    ),
                  ),
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                  },
                  child: const Text(
                    'Dismiss',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
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
    final isMobile = context.isMobile;

    final subtotal = cart.totalPrice;
    final discount = _getCalculatedDiscount(subtotal);
    final finalPayable = (subtotal - discount).clamp(0.0, double.infinity);

    final formContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (isMobile)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                Text(
                  'Confirm Order',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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

        // Customer Info Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 12),
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Order Items (Formed by Date then by Title)
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order Items',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: cs.primary,
                      ),
                    ),
                    Text(
                      '${cart.items.length} ${cart.items.length == 1 ? 'item' : 'items'}',
                      style: TextStyle(fontSize: 12, color: cs.outline),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ...() {
                  final uniqueDates = cart.sortedItems
                      .map((i) => DateTime(i.deliveryDate.year, i.deliveryDate.month, i.deliveryDate.day))
                      .toSet()
                      .toList()
                    ..sort();

                  return cart.sortedItems.map((ci) {
                    final dateColor = CartItem.getDeliveryDateColor(ci.deliveryDate, cs, uniqueDates);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: dateColor, width: 2.0),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: dateColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: dateColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.event_outlined, size: 12, color: dateColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(ci.deliveryDate),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: dateColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  ci.item.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${CartItem.formatNumber(ci.quantity)} ${CartItem.normalizedUnit(ci.item.unit)} × ₹${CartItem.formatNumber(ci.item.price)}',
                                  style: TextStyle(fontSize: 12, color: cs.outline),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${CartItem.formatNumber(ci.totalPrice)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: dateColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  });
                }(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Discount Section
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('None'),
                      selected: _discountType == null,
                      onSelected: (selected) {
                        if (selected) {
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
                      onSelected: (selected) {
                        setState(() {
                          _discountType = selected ? DiscountType.percentage : null;
                          _discountError = null;
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Flat (₹)'),
                      selected: _discountType == DiscountType.flat,
                      onSelected: (selected) {
                        setState(() {
                          _discountType = selected ? DiscountType.flat : null;
                          _discountError = null;
                        });
                      },
                    ),
                  ],
                ),
                if (_discountType != null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (_) => setState(() => _discountError = null),
                    decoration: InputDecoration(
                      labelText: _discountType == DiscountType.percentage
                          ? 'Discount Percentage (e.g. 10 for 10%)'
                          : 'Flat Discount Amount in Rupees',
                      prefixText: _discountType == DiscountType.flat ? '₹ ' : null,
                      suffixText: _discountType == DiscountType.percentage ? '%' : null,
                      errorText: _discountError,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Bill Summary Calculation Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal', style: TextStyle(color: cs.onSurfaceVariant)),
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
                          ? 'Discount (${CartItem.formatNumber(_discountAmount)}%)'
                          : 'Flat Discount',
                      style: TextStyle(color: cs.error),
                    ),
                    Text(
                      '- ₹${CartItem.formatNumber(discount)}',
                      style: TextStyle(color: cs.error, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Payable',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  elevation: 1,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  elevation: 3,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSubmitting ? null : _submitOrder,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _isSubmitting ? 'Placing Order...' : 'Confirm & Place Order',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    if (isMobile) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: formContent,
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 860),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: formContent,
        ),
      ),
    );
  }
}
