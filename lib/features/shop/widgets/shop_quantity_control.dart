import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/models/menu_item_model.dart';
import '../../cart/cart_providers.dart';
import '../../cart/models/cart_item_model.dart';

/// 3-button quantity control for shop menu items:
/// - When not in cart: Displays an "Add to Cart" button.
/// - When in cart: Displays a 3-button layout: `[-]`, editable `[qty]`, `[+]`.
/// - Center `[qty]` allows manual click-to-edit via keyboard with min value = 0.
/// - Does not open any modal bottom sheet.
class ShopQuantityControl extends ConsumerStatefulWidget {
  const ShopQuantityControl({
    super.key,
    required this.product,
    this.compact = false,
    this.fullWidth = false,
  });

  final MenuItem product;
  final bool compact;
  final bool fullWidth;

  @override
  ConsumerState<ShopQuantityControl> createState() => _ShopQuantityControlState();
}

class _ShopQuantityControlState extends ConsumerState<ShopQuantityControl> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _isEditing = true;
      // Select all text on focus for immediate overwrite
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      _isEditing = false;
      _commitQuantity();
    }
  }

  void _commitQuantity() {
    final text = _controller.text.trim();
    final currentQty = ref.read(cartProvider).getQuantity(widget.product.id);

    if (text.isEmpty) {
      _controller.text = CartItem.formatNumber(currentQty);
      return;
    }

    final parsed = double.tryParse(text);
    if (parsed == null) {
      _controller.text = CartItem.formatNumber(currentQty);
      return;
    }

    // Enforce minimum value = 0
    final clamped = parsed < 0 ? 0.0 : parsed;
    ref.read(cartProvider.notifier).setQuantity(widget.product, clamped);
    _controller.text = CartItem.formatNumber(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Reactively watch this item's quantity in cart
    final quantity = ref.watch(
      cartProvider.select((c) => c.getQuantity(widget.product.id)),
    );
    final isInCart = quantity > 0;
    final cartVm = ref.read(cartProvider.notifier);

    final normalizedUnit = CartItem.normalizedUnit(widget.product.unit);
    final step = (normalizedUnit == 'kg' || normalizedUnit == 'litre') ? 0.5 : 1.0;

    // Keep controller text in sync with cart quantity when not actively typing
    if (!_isEditing) {
      final formatted = CartItem.formatNumber(quantity);
      if (_controller.text != formatted) {
        _controller.text = formatted;
      }
    }

    // ── State 1: Not in cart -> "Add to Cart" button ────────────────────────
    if (!isInCart) {
      final btn = FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 8 : 12,
            vertical: widget.compact ? 4 : 6,
          ),
          minimumSize: Size(0, widget.compact ? 32 : 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          // Immediately add to cart without any modal or bottom sheet
          cartVm.addItem(widget.product, 1.0);
        },
        icon: Icon(
          Icons.add_shopping_cart,
          size: widget.compact ? 15 : 17,
        ),
        label: Text(
          widget.compact ? 'Add' : 'Add to Cart',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: widget.compact ? 12 : 13,
          ),
        ),
      );

      if (widget.fullWidth) {
        return SizedBox(width: double.infinity, child: btn);
      }
      return btn;
    }

    // ── State 2: In cart -> 3-button layout: [-], [qty], [+] ────────────────
    final content = Container(
      height: widget.compact ? 32 : 36,
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Minus Button [-]
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
              onTap: () {
                _focusNode.unfocus();
                cartVm.decrement(widget.product.id, step);
              },
              child: Container(
                constraints: BoxConstraints(
                  minWidth: widget.compact ? 28 : 34,
                  minHeight: widget.compact ? 32 : 36,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.remove,
                  size: widget.compact ? 15 : 18,
                  color: cs.primary,
                ),
              ),
            ),
          ),

          // 2. Center Quantity Field [qty] (Manual click & keyboard edit, min = 0)
          widget.fullWidth
              ? Expanded(
                  child: _buildQuantityTextField(cs, theme),
                )
              : SizedBox(
                  width: widget.compact ? 44 : 54,
                  child: _buildQuantityTextField(cs, theme),
                ),

          // 3. Plus Button [+]
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
              onTap: () {
                _focusNode.unfocus();
                cartVm.increment(widget.product, step);
              },
              child: Container(
                constraints: BoxConstraints(
                  minWidth: widget.compact ? 28 : 34,
                  minHeight: widget.compact ? 32 : 36,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.add,
                  size: widget.compact ? 15 : 18,
                  color: cs.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.fullWidth) {
      return SizedBox(width: double.infinity, child: content);
    }
    return content;
  }

  Widget _buildQuantityTextField(ColorScheme cs, ThemeData theme) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      textAlign: TextAlign.center,
      textInputAction: TextInputAction.done,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: cs.onPrimaryContainer,
        fontSize: widget.compact ? 13 : 14,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      onTap: () {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      },
      onSubmitted: (_) {
        _focusNode.unfocus();
      },
    );
  }
}
