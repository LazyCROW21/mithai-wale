import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/models/menu_item_model.dart';
import '../../../core/layout/layout_extensions.dart';
import '../cart_providers.dart';
import '../models/cart_item_model.dart';

/// Opens the quick edit quantity dialog/sheet.
Future<void> showEditQuantityDialog(
  BuildContext context, {
  required MenuItem item,
  required double currentQuantity,
}) {
  if (context.isMobile) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _EditQuantityContent(
        item: item,
        initialQuantity: currentQuantity > 0 ? currentQuantity : 1.0,
      ),
    );
  } else {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 420,
          child: _EditQuantityContent(
            item: item,
            initialQuantity: currentQuantity > 0 ? currentQuantity : 1.0,
          ),
        ),
      ),
    );
  }
}

class _EditQuantityContent extends ConsumerStatefulWidget {
  const _EditQuantityContent({
    required this.item,
    required this.initialQuantity,
  });

  final MenuItem item;
  final double initialQuantity;

  @override
  ConsumerState<_EditQuantityContent> createState() => _EditQuantityContentState();
}

class _EditQuantityContentState extends ConsumerState<_EditQuantityContent> {
  late final TextEditingController _controller;
  late double _currentQty;

  @override
  void initState() {
    super.initState();
    _currentQty = widget.initialQuantity;
    _controller = TextEditingController(text: CartItem.formatNumber(_currentQty));
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed != null && parsed >= 0) {
      setState(() {
        _currentQty = parsed;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _applyPreset(double qty) {
    setState(() {
      _currentQty = qty;
      _controller.text = CartItem.formatNumber(qty);
    });
  }

  List<double> _getPresetsForUnit(String unit) {
    final u = CartItem.normalizedUnit(unit);
    if (u == 'kg' || u == 'litre') {
      return [0.25, 0.5, 1.0, 1.5, 2.0, 5.0];
    } else if (u == 'gm') {
      return [100.0, 250.0, 500.0, 750.0, 1000.0];
    } else {
      // pieces
      return [1.0, 2.0, 4.0, 6.0, 10.0, 12.0];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final unit = CartItem.normalizedUnit(widget.item.unit);
    final presets = _getPresetsForUnit(widget.item.unit);
    final calculatedTotal = widget.item.price * _currentQty;

    final tempItem = CartItem(item: widget.item, quantity: _currentQty);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tempItem.pricePerUnitLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Numeric Text Input with Stepper Controls
          Text(
            'Quantity ($unit)',
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.remove),
                onPressed: _currentQty > 0.5
                    ? () {
                        final step = (unit == 'kg' || unit == 'litre') ? 0.5 : 1.0;
                        final newQty = (_currentQty - step).clamp(0.0, 9999.0);
                        _applyPreset(newQty);
                      }
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    suffixText: unit,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.add),
                onPressed: () {
                  final step = (unit == 'kg' || unit == 'litre') ? 0.5 : 1.0;
                  final newQty = _currentQty + step;
                  _applyPreset(newQty);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Presets
          Text(
            'Quick Select',
            style: theme.textTheme.labelSmall?.copyWith(color: cs.outline),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((p) {
              final isSelected = (_currentQty == p);
              final pLabel = (unit == 'pc' && p == 1.0)
                  ? '1 pc'
                  : (unit == 'pc')
                      ? '${CartItem.formatNumber(p)} pcs'
                      : '${CartItem.formatNumber(p)} $unit';

              return ChoiceChip(
                label: Text(pLabel),
                selected: isSelected,
                onSelected: (_) => _applyPreset(p),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Total Price Calculation Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total for quantity', style: TextStyle(fontSize: 12)),
                    Text(
                      tempItem.formattedUnits,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '₹${CartItem.formatNumber(calculatedTotal)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              if (ref.read(cartProvider).contains(widget.item.id)) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error),
                  ),
                  onPressed: () {
                    ref.read(cartProvider.notifier).removeItem(widget.item.id);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove'),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: _currentQty > 0
                      ? () {
                          ref
                              .read(cartProvider.notifier)
                              .setQuantity(widget.item, _currentQty);
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: const Text('Update Cart'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
