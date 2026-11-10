import 'package:hive/hive.dart';
import '../models/order_model.dart';
import 'orders_repository.dart';

/// Hive implementation of [IOrdersRepository].
class HiveOrdersRepository implements IOrdersRepository {
  HiveOrdersRepository(this._box);

  final Box<Map> _box;

  @override
  Future<List<OrderModel>> getAll() async {
    return getAllSync();
  }

  @override
  List<OrderModel> getAllSync() {
    final list = <OrderModel>[];
    for (final val in _box.values) {
      try {
        final order = OrderModel.fromMap(val);
        list.add(order);
      } catch (_) {}
    }
    // Sort orders by orderDate descending (newest orders first)
    list.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return list;
  }

  @override
  Future<void> save(OrderModel order) async {
    await _box.put(order.id, order.toMap());
  }

  @override
  Future<void> updateStatus(String orderId, String newStatus) async {
    final raw = _box.get(orderId);
    if (raw != null) {
      final order = OrderModel.fromMap(raw);
      final updated = order.copyWith(status: newStatus);
      await _box.put(orderId, updated.toMap());
    }
  }

  @override
  Future<void> delete(String orderId) async {
    await _box.delete(orderId);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}
