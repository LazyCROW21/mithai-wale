import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/models/menu_item_model.dart';
import '../../core/database/repositories/cart_repository.dart';
import '../../core/di/service_locator.dart';
import 'cart_state.dart';
import 'models/cart_item_model.dart';

class CartViewModel extends Notifier<CartState> {
  ICartRepository? get _cartRepo =>
      sl.isRegistered<ICartRepository>() ? sl<ICartRepository>() : null;

  @override
  CartState build() {
    final repo = _cartRepo;
    if (repo != null) {
      try {
        final stored = repo.getAllSync();
        return CartState(items: stored);
      } catch (_) {
        return const CartState();
      }
    }
    return const CartState();
  }

  /// Adds an item to the cart without showing any popup/modal.
  /// If the item is already in the cart, increases its quantity by [quantity].
  void addItem(MenuItem item, [double quantity = 1.0]) {
    final currentQty = state.getQuantity(item.id);
    final newQty = currentQty + quantity;

    final cartItem = CartItem(item: item, quantity: newQty);
    final newItems = Map<int, CartItem>.from(state.items);
    newItems[item.id] = cartItem;

    state = state.copyWith(items: newItems);
    _cartRepo?.save(cartItem);
  }

  /// Increments quantity of an item by [step] (default 1.0).
  void increment(MenuItem item, [double step = 1.0]) {
    addItem(item, step);
  }

  /// Decrements quantity of an item by [step] (default 1.0).
  /// If quantity reaches <= 0, the item is removed from the cart.
  void decrement(int itemId, [double step = 1.0]) {
    if (!state.contains(itemId)) return;

    final currentItem = state.items[itemId]!;
    final newQty = currentItem.quantity - step;

    final newItems = Map<int, CartItem>.from(state.items);
    if (newQty <= 0) {
      newItems.remove(itemId);
      state = state.copyWith(items: newItems);
      _cartRepo?.remove(itemId);
    } else {
      final updated = currentItem.copyWith(quantity: newQty);
      newItems[itemId] = updated;
      state = state.copyWith(items: newItems);
      _cartRepo?.save(updated);
    }
  }

  /// Sets the exact quantity for an item (e.g. from the edit quantity modal).
  /// If [quantity] <= 0, removes the item from the cart.
  void setQuantity(MenuItem item, double quantity) {
    final newItems = Map<int, CartItem>.from(state.items);

    if (quantity <= 0) {
      newItems.remove(item.id);
      state = state.copyWith(items: newItems);
      _cartRepo?.remove(item.id);
    } else {
      final updated = CartItem(item: item, quantity: quantity);
      newItems[item.id] = updated;
      state = state.copyWith(items: newItems);
      _cartRepo?.save(updated);
    }
  }

  /// Removes an item completely from the cart.
  void removeItem(int itemId) {
    if (!state.contains(itemId)) return;

    final newItems = Map<int, CartItem>.from(state.items);
    newItems.remove(itemId);
    state = state.copyWith(items: newItems);
    _cartRepo?.remove(itemId);
  }

  /// Clears all items from the cart.
  void clearCart() {
    state = const CartState();
    _cartRepo?.clear();
  }
}
