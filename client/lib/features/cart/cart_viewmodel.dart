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

  /// Adds a new distinct item entry to the cart for a specific [deliveryDate] (defaults to today).
  /// Duplicate items on the same date are NOT combined, allowing multiple independent entries.
  void addItem(MenuItem item, [double quantity = 1.0, DateTime? deliveryDate]) {
    final now = DateTime.now();
    final d = deliveryDate != null
        ? DateTime(deliveryDate.year, deliveryDate.month, deliveryDate.day)
        : DateTime(now.year, now.month, now.day);

    final cartItem = CartItem(item: item, quantity: quantity, deliveryDate: d);
    final newItems = Map<String, CartItem>.from(state.items);
    newItems[cartItem.cartKey] = cartItem;

    state = state.copyWith(items: newItems);
    _cartRepo?.save(cartItem);
  }

  /// Increments quantity of an existing [cartItem] by [step] (default 1.0).
  void increment(CartItem cartItem, [double step = 1.0]) {
    setQuantity(cartItem, cartItem.quantity + step);
  }

  /// Decrements quantity of an item by [step] (default 1.0).
  /// If quantity reaches <= 0, the item entry is removed from the cart.
  void decrement(String cartKey, [double step = 1.0]) {
    if (!state.contains(cartKey)) return;

    final currentItem = state.items[cartKey]!;
    final newQty = currentItem.quantity - step;

    final newItems = Map<String, CartItem>.from(state.items);
    if (newQty <= 0) {
      newItems.remove(cartKey);
      state = state.copyWith(items: newItems);
      _cartRepo?.remove(cartKey);
    } else {
      final updated = currentItem.copyWith(quantity: newQty);
      newItems[cartKey] = updated;
      state = state.copyWith(items: newItems);
      _cartRepo?.save(updated);
    }
  }

  /// Decrements quantity using a product ID (decrements the earliest or only matching item).
  void decrementProduct(int productId, [double step = 1.0]) {
    final matching = state.items.values
        .where((ci) => ci.item.id == productId)
        .toList();
    if (matching.isEmpty) return;
    matching.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
    decrement(matching.first.cartKey, step);
  }

  /// Sets the exact quantity for a [cartItem].
  /// If [quantity] <= 0, removes the item from the cart.
  void setQuantity(CartItem cartItem, double quantity) {
    final newItems = Map<String, CartItem>.from(state.items);
    final key = cartItem.cartKey;

    if (quantity <= 0) {
      newItems.remove(key);
      state = state.copyWith(items: newItems);
      _cartRepo?.remove(key);
    } else {
      final updated = cartItem.copyWith(quantity: quantity);
      newItems[key] = updated;
      state = state.copyWith(items: newItems);
      _cartRepo?.save(updated);
    }
  }

  /// Sets quantity using a product ID (updates or creates an item for today).
  void setProductQuantity(MenuItem product, double quantity) {
    final matching = state.items.values
        .where((ci) => ci.item.id == product.id)
        .toList();

    if (quantity <= 0) {
      // Remove all entries for this product
      final newItems = Map<String, CartItem>.from(state.items);
      for (final ci in matching) {
        newItems.remove(ci.cartKey);
        _cartRepo?.remove(ci.cartKey);
      }
      state = state.copyWith(items: newItems);
    } else {
      if (matching.isNotEmpty) {
        setQuantity(matching.first, quantity);
      } else {
        addItem(product, quantity);
      }
    }
  }

  /// Updates the delivery date of [cartItem].
  /// Does NOT combine with other items on [newDate].
  void updateItemDeliveryDate(CartItem cartItem, DateTime newDate) {
    final normalizedNewDate = DateTime(newDate.year, newDate.month, newDate.day);
    if (cartItem.deliveryDate == normalizedNewDate) return;

    final updated = cartItem.copyWith(deliveryDate: normalizedNewDate);
    final newItems = Map<String, CartItem>.from(state.items);
    newItems[cartItem.cartKey] = updated;

    state = state.copyWith(items: newItems);
    _cartRepo?.save(updated);
  }

  /// Duplicates an item to be delivered on [newDate].
  /// If an item already exists on [newDate], combines by adding [quantity].
  void duplicateItemWithDate(CartItem cartItem, DateTime newDate, [double? quantity]) {
    addItem(cartItem.item, quantity ?? cartItem.quantity, newDate);
  }

  /// Removes a specific cart item entry completely from the cart.
  void removeItem(String cartKey) {
    if (!state.contains(cartKey)) return;

    final newItems = Map<String, CartItem>.from(state.items);
    newItems.remove(cartKey);
    state = state.copyWith(items: newItems);
    _cartRepo?.remove(cartKey);
  }

  /// Clears all items from the cart.
  void clearCart() {
    state = const CartState();
    _cartRepo?.clear();
  }

  /// Creates and saves an order from current cart items to Hive with status "Placed",
  /// applying any specified discount, then clears the cart.
  /// Note: Orders do not have an order-level delivery date; each item has its own delivery date.
  Future<OrderModel?> checkout({
    String customerName = 'Walk-in Customer',
    String customerPhone = '+91 98765 43210',
    DiscountType? discountType,
    double discountAmount = 0.0,
  }) async {
    if (state.isEmpty) return null;

    final id = '#ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final orderItems = state.sortedItems.map((ci) => OrderItemDetail(
      name: ci.item.title,
      quantity: ci.quantity,
      unit: ci.item.unit,
      unitPrice: ci.item.price,
      deliveryDate: ci.deliveryDate,
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
