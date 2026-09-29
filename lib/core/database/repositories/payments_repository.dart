import '../models/payment_model.dart';

/// Repository interface for managing payment ledger transactions.
abstract interface class IPaymentsRepository {
  /// Fetches all stored payments asynchronously.
  Future<List<PaymentModel>> getAll();

  /// Fetches all stored payments synchronously from Hive.
  List<PaymentModel> getAllSync();

  /// Fetches all payments associated with [orderId].
  Future<List<PaymentModel>> getByOrderId(String orderId);

  /// Fetches all payments associated with [orderId] synchronously.
  List<PaymentModel> getByOrderIdSync(String orderId);

  /// Saves or updates a payment entry.
  Future<void> save(PaymentModel payment);

  /// Deletes a payment entry by [paymentId].
  Future<void> delete(String paymentId);

  /// Clears all payment records.
  Future<void> clear();
}
