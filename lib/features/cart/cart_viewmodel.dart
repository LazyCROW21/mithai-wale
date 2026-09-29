import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/models/menu_item_model.dart';
import '../../core/database/models/order_model.dart';
import '../../core/database/repositories/cart_repository.dart';
import '../../core/database/repositories/orders_repository.dart';
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

  /// Creates and saves an order from current cart items to Hive with status "Placed",
  /// applying any specified discount, then clears the cart.
  Future<OrderModel?> checkout({
    String customerName = 'Walk-in Customer',
    String customerPhone = '+91 98765 43210',
    DateTime? deliveryDate,
    DiscountType? discountType,
    double discountAmount = 0.0,
  }) async {
    if (state.isEmpty) return null;

    final id = '#ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final orderItems = state.items.values.map((ci) => OrderItemDetail(
      name: ci.item.title,
      quantity: ci.quantity,
      unit: ci.item.unit,
      unitPrice: ci.item.price,
    )).toList();

    final subtotal = state.totalPrice;
    double calcDiscount = 0.0;
    if (discountType != null && discountAmount > 0) {
      if (discountType == DiscountType.percentage) {
        calcDiscount = (subtotal * discountAmount) / 100.0;
      } else {
        calcDiscount = discountAmount.clamp(0.0, subtotal);
      }
    }
    final finalBill = (subtotal - calcDiscount).clamp(0.0, double.infinity);

    final order = OrderModel(
      id: id,
      customerName: customerName.trim().isEmpty ? 'Walk-in Customer' : customerName.trim(),
      customerPhone: customerPhone.trim().isEmpty ? '+91 98765 43210' : customerPhone.trim(),
      items: orderItems,
      deliveryDate: deliveryDate ?? DateTime.now(),
      orderDate: DateTime.now(),
      totalBill: finalBill,
      status: 'Placed',
      discountType: discountType,
      discountAmount: discountAmount,
    );

    if (sl.isRegistered<IOrdersRepository>()) {
      await sl<IOrdersRepository>().save(order);
    }

    clearCart();
    return order;
  }
}

