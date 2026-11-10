import 'package:flutter/foundation.dart';
import 'models/cart_item_model.dart';

@immutable
class CartState {
  const CartState({
    this.items = const {},
  });

  /// Map of items in cart, keyed by unique composite `cartKey` (itemId_yyyy-mm-dd).
  final Map<String, CartItem> items;

  /// Number of distinct item entries in the cart.
  int get totalUniqueItems => items.length;

  /// Total sum of all units/quantities in the cart.
  double get totalUnitsCount =>
      items.values.fold<double>(0.0, (sum, item) => sum + item.quantity);

  /// Grand total price of all items in cart.
  double get totalPrice =>
      items.values.fold<double>(0.0, (sum, item) => sum + item.totalPrice);

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// Quantity of a specific cart item entry, or 0.0 if not added.
  double getQuantity(String cartKey) => items[cartKey]?.quantity ?? 0.0;

  /// Total aggregated quantity of a product in the cart across all delivery dates.
  double getQuantityForProduct(int itemId) {
    return items.values
        .where((ci) => ci.item.id == itemId)
        .fold<double>(0.0, (sum, ci) => sum + ci.quantity);
  }

  /// Check if a specific product (any delivery date) is in the cart.
  bool containsProduct(int itemId) =>
      items.values.any((ci) => ci.item.id == itemId);

  /// Check if a specific item + delivery date key is in the cart.
  bool contains(String cartKey) => items.containsKey(cartKey);

  /// Returns items sorted by delivery date ascending, then by product name.
  List<CartItem> get sortedItems {
    final list = items.values.toList();
    list.sort((a, b) {
      final dateComp = a.deliveryDate.compareTo(b.deliveryDate);
      if (dateComp != 0) return dateComp;
      return a.item.title.compareTo(b.item.title);
    });
    return list;
  }

  /// Groups items by normalized delivery date (year, month, day), sorted ascending.
  Map<DateTime, List<CartItem>> get groupedByDeliveryDate {
    final groups = <DateTime, List<CartItem>>{};
    for (final item in sortedItems) {
      final key = DateTime(item.deliveryDate.year, item.deliveryDate.month, item.deliveryDate.day);
      groups.putIfAbsent(key, () => []).add(item);
    }
    return groups;
  }

  CartState copyWith({
    Map<String, CartItem>? items,
  }) {
    return CartState(
      items: items ?? this.items,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartState && mapEquals(items, other.items);

  @override
  int get hashCode => items.hashCode;
}
