import 'package:flutter/foundation.dart';

import '../../sync/sync_store.dart';
import '../models/payment_model.dart';
import 'payments_repository.dart';

/// Offline-first ledger. Payments are append-only on the server: a payment is
/// created or deleted, never edited (corrections are new entries).
class HivePaymentsRepository implements IPaymentsRepository {
  HivePaymentsRepository(this._store);

  final SyncStore _store;
  static const _c = SyncCollections.payments;

  @override
  Future<List<PaymentModel>> getAll() async => getAllSync();

  @override
  List<PaymentModel> getAllSync() {
    final list = <PaymentModel>[];
    for (final val in _store.box(_c).values) {
      try {
        list.add(PaymentModel.fromMap(val));
      } catch (_) {}
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<PaymentModel>> getByOrderId(String orderId) async => getByOrderIdSync(orderId);

  @override
  List<PaymentModel> getByOrderIdSync(String orderId) => getAllSync()
      .where((p) => p.orderId.toLowerCase() == orderId.toLowerCase())
      .toList();

  @override
  Future<void> save(PaymentModel payment) async {
    final box = _store.box(_c);
    if (box.containsKey(payment.id)) {
      debugPrint('Payments are append-only; edit of ${payment.id} is kept local only.');
      await box.put(payment.id, {...box.get(payment.id)!, ...payment.toMap()});
      return;
    }
    // A payment belongs to its order's shop, else the shop picked when recording
    // it, else the active shop.
    final orderShop = _store.box(SyncCollections.orders).get(payment.orderId)?['shopId'] as String?;
    final shopId = orderShop ?? payment.shopId ?? _store.activeShopId;
    final record = {...payment.toMap(), 'shopId': ?shopId};
    await box.put(payment.id, record);
    await _store.enqueueCreate(_c, payment.id, record, shopId: shopId);
  }

  @override
  Future<void> delete(String paymentId) async {
    if (!_store.box(_c).containsKey(paymentId)) return;
    await _store.box(_c).delete(paymentId);
    await _store.enqueueDelete(_c, paymentId);
  }

  /// Local-only: clears this device's copy (does not delete on the server).
  @override
  Future<void> clear() => _store.box(_c).clear();
}
