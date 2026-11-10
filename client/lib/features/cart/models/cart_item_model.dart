import 'package:flutter/material.dart';
import '../../../core/database/models/menu_item_model.dart';

@immutable
class CartItem {
  CartItem({
    String? id,
    required this.item,
    required this.quantity,
    DateTime? deliveryDate,
  })  : id = id ?? generateId(item.id),
        deliveryDate = deliveryDate != null
            ? DateTime(deliveryDate.year, deliveryDate.month, deliveryDate.day)
            : DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  static int _idCounter = 0;
  static String generateId(int itemId) =>
      '${itemId}_${DateTime.now().microsecondsSinceEpoch}_${++_idCounter}';

  final String id;
  final MenuItem item;
  final double quantity;
  final DateTime deliveryDate;

  /// Unique key for this cart item instance.
  String get cartKey => id;

  static String keyFor(int itemId, DateTime date) =>
      '${itemId}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {
        'id': id,
        'item': item.toMap(),
        'quantity': quantity,
        'deliveryDate': deliveryDate.toIso8601String(),
      };

  factory CartItem.fromMap(Map<dynamic, dynamic> map) {
    final parsedDate = map['deliveryDate'] != null
        ? DateTime.tryParse(map['deliveryDate'] as String)
        : null;
    final item = MenuItem.fromMap(map['item'] as Map<dynamic, dynamic>);
    final id = map['id'] as String? ?? generateId(item.id);
    return CartItem(
      id: id,
      item: item,
      quantity: (map['quantity'] as num).toDouble(),
      deliveryDate: parsedDate,
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

  /// Friendly representation of the delivery date (e.g. "Today, 21 Oct", "Tomorrow, 22 Oct", or "25 Oct 2026")
  String get formattedDeliveryDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${deliveryDate.day} ${months[deliveryDate.month - 1]}';

    if (deliveryDate == today) {
      return 'Today ($dateStr)';
    } else if (deliveryDate == tomorrow) {
      return 'Tomorrow ($dateStr)';
    }
    return '$dateStr ${deliveryDate.year}';
  }

  /// Returns a curated, harmonious shade of the primary color for a given [date].
  /// Items sharing the same delivery date receive the exact same color shade.
  static Color getDeliveryDateColor(
    DateTime date,
    ColorScheme cs, [
    List<DateTime>? sortedUniqueDates,
  ]) {
    final baseHsl = HSLColor.fromColor(cs.primary);

    int index = 0;
    if (sortedUniqueDates != null && sortedUniqueDates.isNotEmpty) {
      final normalized = DateTime(date.year, date.month, date.day);
      index = sortedUniqueDates.indexWhere(
        (d) => d.year == normalized.year && d.month == normalized.month && d.day == normalized.day,
      );
      if (index < 0) index = 0;
    } else {
      index = (date.year * 372 + date.month * 31 + date.day) % 5;
    }

    // Curated shades rooted in primary warm saffron:
    switch (index % 5) {
      case 0:
        return cs.primary;
      case 1:
        return baseHsl
            .withHue((baseHsl.hue - 12.0 + 360.0) % 360.0)
            .withLightness((baseHsl.lightness * 0.88).clamp(0.25, 0.75))
            .toColor();
      case 2:
        return baseHsl
            .withHue((baseHsl.hue + 14.0) % 360.0)
            .withLightness((baseHsl.lightness * 1.08).clamp(0.25, 0.75))
            .toColor();
      case 3:
        return baseHsl
            .withHue((baseHsl.hue - 24.0 + 360.0) % 360.0)
            .withSaturation((baseHsl.saturation * 0.95).clamp(0.3, 1.0))
            .toColor();
      case 4:
      default:
        return baseHsl
            .withHue((baseHsl.hue + 26.0) % 360.0)
            .withSaturation((baseHsl.saturation * 0.9).clamp(0.3, 1.0))
            .toColor();
    }
  }

  CartItem copyWith({
    String? id,
    MenuItem? item,
    double? quantity,
    DateTime? deliveryDate,
  }) {
    return CartItem(
      id: id ?? this.id,
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      deliveryDate: deliveryDate ?? this.deliveryDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          item == other.item &&
          quantity == other.quantity &&
          deliveryDate == other.deliveryDate;

  @override
  int get hashCode => Object.hash(id, item, quantity, deliveryDate);
}
