import '../../sync/sync_store.dart';
import '../models/order_model.dart';
import 'orders_repository.dart';

/// Offline-first orders. New orders belong to [OrderModel.shopId], falling back
/// to the device's active shop.
class HiveOrdersRepository implements IOrdersRepository {
  HiveOrdersRepository(this._store);

  final SyncStore _store;
  static const _c = SyncCollections.orders;

  @override
  Future<List<OrderModel>> getAll() async => getAllSync();

  @override
  List<OrderModel> getAllSync() {
    final list = <OrderModel>[];
    for (final val in _store.box(_c).values) {
      try {
        list.add(OrderModel.fromMap(val));
      } catch (_) {}
    }
    list.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return list;
  }

  @override
  Future<void> save(OrderModel order) async {
    final box = _store.box(_c);
    final before = box.get(order.id);
    if (before == null) {
      final shopId = order.shopId ?? _store.activeShopId;
      final record = {...order.toMap(), 'shopId': ?shopId};
      await box.put(order.id, record);
      await _store.enqueueCreate(_c, order.id, record, shopId: shopId);
    } else {
      final after = {...before, ...order.toMap()};
      await box.put(order.id, after);
      await _store.enqueueUpdate(_c, order.id, before, after);
    }
  }

  @override
  Future<void> updateStatus(String orderId, String newStatus) async {
    final raw = _store.box(_c).get(orderId);
    if (raw == null) return;
    // Applies to every delivery date of the order.
    await save(OrderModel.fromMap(raw).withAllStatus(newStatus));
  }

  @override
  Future<void> delete(String orderId) async {
    if (!_store.box(_c).containsKey(orderId)) return;
    await _store.box(_c).delete(orderId);
    await _store.enqueueDelete(_c, orderId);
  }

  /// Local-only: clears this device's copy (does not delete on the server).
  @override
  Future<void> clear() => _store.box(_c).clear();
}
