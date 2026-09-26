import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/repositories/orders_repository.dart';
import '../../core/di/service_locator.dart';
import 'orders_state.dart';

/// ViewModel managing state, search, filter, and expandable cards for Orders.
class OrdersViewModel extends Notifier<OrdersState> {
  IOrdersRepository? get _ordersRepo =>
      sl.isRegistered<IOrdersRepository>() ? sl<IOrdersRepository>() : null;

  @override
  OrdersState build() {
    final repo = _ordersRepo;
    if (repo != null) {
      try {
        final list = repo.getAllSync();
        return OrdersState(allOrders: list);
      } catch (_) {
        return const OrdersState();
      }
    }
    return const OrdersState();
  }

  /// Reloads all orders from Hive DB asynchronously.
  Future<void> loadOrders() async {
    final repo = _ordersRepo;
    if (repo != null) {
      state = state.copyWith(isLoading: true);
      try {
        final list = await repo.getAll();
        state = state.copyWith(allOrders: list, isLoading: false);
      } catch (_) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Adds a new order (e.g. placed from cart) and persists to Hive.
  Future<void> addOrder(OrderModel order) async {
    final updated = [order, ...state.allOrders.where((o) => o.id != order.id)];
    state = state.copyWith(allOrders: updated);
    await _ordersRepo?.save(order);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
  }

  void setSelectedDate(DateTime? date) {
    state = state.copyWith(selectedDate: () => date);
  }

  void clearDateFilter() {
    state = state.copyWith(selectedDate: () => null);
  }

  void toggleExpanded(String orderId) {
    final current = Set<String>.from(state.expandedOrderIds);
    if (current.contains(orderId)) {
      current.remove(orderId);
    } else {
      current.add(orderId);
    }
    state = state.copyWith(expandedOrderIds: current);
  }

  /// Updates an entire order in state and Hive DB.
  Future<void> updateOrder(OrderModel updatedOrder) async {
    final updated = state.allOrders.map((o) {
      if (o.id == updatedOrder.id) {
        return updatedOrder;
      }
      return o;
    }).toList();
    state = state.copyWith(allOrders: updated);
    await _ordersRepo?.save(updatedOrder);
  }

  /// Updates an order's status and updates Hive DB.
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final updated = state.allOrders.map((o) {
      if (o.id == orderId) {
        return o.copyWith(status: newStatus);
      }
      return o;
    }).toList();
    state = state.copyWith(allOrders: updated);
    await _ordersRepo?.updateStatus(orderId, newStatus);
  }
}

