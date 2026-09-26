import '../models/order_model.dart';

/// Repository interface for managing customer orders.
abstract interface class IOrdersRepository {
  /// Fetches all stored orders asynchronously.
  Future<List<OrderModel>> getAll();

  /// Fetches all stored orders synchronously from Hive.
  List<OrderModel> getAllSync();

  /// Saves or updates an order.
  Future<void> save(OrderModel order);

  /// Updates the status of an existing order by [orderId].
  Future<void> updateStatus(String orderId, String newStatus);

  /// Deletes an order by [orderId].
  Future<void> delete(String orderId);

  /// Clears all orders.
  Future<void> clear();
}
