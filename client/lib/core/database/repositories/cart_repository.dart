import '../../../features/cart/models/cart_item_model.dart';

abstract interface class ICartRepository {
  Future<Map<String, CartItem>> getAll();
  Map<String, CartItem> getAllSync();
  Future<void> save(CartItem item);
  Future<void> remove(String cartKey);
  Future<void> clear();
}
