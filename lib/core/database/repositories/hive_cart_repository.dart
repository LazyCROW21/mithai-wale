import 'package:hive/hive.dart';
import '../../../features/cart/models/cart_item_model.dart';
import 'cart_repository.dart';

class HiveCartRepository implements ICartRepository {
  HiveCartRepository(this._box);

  final Box<Map> _box;

  @override
  Future<Map<int, CartItem>> getAll() async {
    return getAllSync();
  }

  @override
  Map<int, CartItem> getAllSync() {
    final map = <int, CartItem>{};
    for (final val in _box.values) {
      try {
        final item = CartItem.fromMap(val);
        map[item.item.id] = item;
      } catch (_) {}
    }
    return map;
  }

  @override
  Future<void> save(CartItem item) async {
    await _box.put(item.item.id, item.toMap());
  }

  @override
  Future<void> remove(int itemId) async {
    await _box.delete(itemId);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}
