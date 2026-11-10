import 'package:hive/hive.dart';
import '../models/payment_model.dart';
import 'payments_repository.dart';

/// Hive implementation of [IPaymentsRepository].
class HivePaymentsRepository implements IPaymentsRepository {
  HivePaymentsRepository(this._box);

  final Box<Map> _box;

  @override
  Future<List<PaymentModel>> getAll() async {
    return getAllSync();
  }

  @override
  List<PaymentModel> getAllSync() {
    final list = <PaymentModel>[];
    for (final val in _box.values) {
      try {
        final payment = PaymentModel.fromMap(val);
        list.add(payment);
      } catch (_) {}
    }
    // Sort transactions by createdAt descending (newest transactions first)
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<PaymentModel>> getByOrderId(String orderId) async {
    return getByOrderIdSync(orderId);
  }

  @override
  List<PaymentModel> getByOrderIdSync(String orderId) {
    return getAllSync()
        .where((p) => p.orderId.toLowerCase() == orderId.toLowerCase())
        .toList();
  }

  @override
  Future<void> save(PaymentModel payment) async {
    await _box.put(payment.id, payment.toMap());
  }

  @override
  Future<void> delete(String paymentId) async {
    await _box.delete(paymentId);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}
