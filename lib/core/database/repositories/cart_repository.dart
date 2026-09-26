import '../../../features/cart/models/cart_item_model.dart';

abstract interface class ICartRepository {
  Future<Map<int, CartItem>> getAll();
  Map<int, CartItem> getAllSync();
  Future<void> save(CartItem item);
  Future<void> remove(int itemId);
  Future<void> clear();
}
