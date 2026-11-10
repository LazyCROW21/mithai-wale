import 'package:hive/hive.dart';
import '../../../features/cart/models/cart_item_model.dart';
import 'cart_repository.dart';

class HiveCartRepository implements ICartRepository {
  HiveCartRepository(this._box);

  final Box<Map> _box;

  @override
  Future<Map<String, CartItem>> getAll() async {
    return getAllSync();
  }

  @override
  Map<String, CartItem> getAllSync() {
    final map = <String, CartItem>{};
    for (final val in _box.values) {
      try {
        final item = CartItem.fromMap(val);
        map[item.cartKey] = item;
      } catch (_) {}
    }
    return map;
  }

  @override
  Future<void> save(CartItem item) async {
    await _box.put(item.cartKey, item.toMap());
  }

  @override
  Future<void> remove(String cartKey) async {
    await _box.delete(cartKey);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}
