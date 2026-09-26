import 'package:flutter/foundation.dart';
import '../../../core/database/models/menu_item_model.dart';

@immutable
class CartItem {
  const CartItem({
    required this.item,
    required this.quantity,
  });

  final MenuItem item;
  final double quantity;

  Map<String, dynamic> toMap() => {
        'item': item.toMap(),
        'quantity': quantity,
      };

  factory CartItem.fromMap(Map<dynamic, dynamic> map) {
    return CartItem(
      item: MenuItem.fromMap(map['item'] as Map<dynamic, dynamic>),
      quantity: (map['quantity'] as num).toDouble(),
    );
  }

  double get totalPrice => item.price * quantity;

  /// Helper to format numeric values cleanly (e.g. 2.0 -> '2', 2.4 -> '2.4', 50.0 -> '50')
  static String formatNumber(num value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    // Limit to 2 decimal places and strip trailing zeros
    return value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  /// Normalized unit representation (e.g. 'kg', 'pc', 'gm', 'litre')
  static String normalizedUnit(String unit) {
    final lower = unit.trim().toLowerCase();
    if (lower == 'per piece' || lower == 'piece' || lower == 'pcs') {
      return 'pc';
    }
    return lower;
  }

  /// Label showing price and unit rate, e.g. "Rs. 50/kg", "Rs. 50/pc", "Rs. 50/gm"
  String get pricePerUnitLabel {
    final u = normalizedUnit(item.unit);
    final p = formatNumber(item.price);
    return 'Rs. $p/$u';
  }

  /// Quantity and unit string according to qty, e.g. "4 kg", "2.4 litre", "2 pcs"
  String get formattedUnits {
    final qtyStr = formatNumber(quantity);
    final u = normalizedUnit(item.unit);
    if (u == 'pc') {
      return quantity == 1 ? '$qtyStr pc' : '$qtyStr pcs';
    }
    return '$qtyStr $u';
  }

  /// Formatted subtitle following pattern: `Qty: <qty> | Rs. <price>/kg (<total unit / weight>)`
  String get summarySubtitle {
    final qtyStr = formatNumber(quantity);
    return 'Qty: $qtyStr | $pricePerUnitLabel ($formattedUnits)';
  }

  CartItem copyWith({
    MenuItem? item,
    double? quantity,
  }) {
    return CartItem(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          item == other.item &&
          quantity == other.quantity;

  @override
  int get hashCode => Object.hash(item, quantity);
}
