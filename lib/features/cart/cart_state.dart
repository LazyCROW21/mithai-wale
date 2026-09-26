import 'package:flutter/foundation.dart';
import 'models/cart_item_model.dart';

@immutable
class CartState {
  const CartState({
    this.items = const {},
  });

  /// Map of items in cart, keyed by MenuItem id for O(1) lookups.
  final Map<int, CartItem> items;

  /// Number of distinct products in the cart.
  int get totalUniqueItems => items.length;

  /// Total sum of all units/quantities in the cart.
  double get totalUnitsCount =>
      items.values.fold<double>(0.0, (sum, item) => sum + item.quantity);

  /// Grand total price of all items in cart.
  double get totalPrice =>
      items.values.fold<double>(0.0, (sum, item) => sum + item.totalPrice);

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// Quantity of a specific item in the cart, or 0.0 if not added.
  double getQuantity(int itemId) => items[itemId]?.quantity ?? 0.0;

  /// Check if a specific item is in the cart.
  bool contains(int itemId) => items.containsKey(itemId);

  CartState copyWith({
    Map<int, CartItem>? items,
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
