import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/repositories/orders_repository.dart';
import '../../core/di/service_locator.dart';
import 'orders_state.dart';

/// ViewModel managing state, search, filter, date navigation, and expandable cards for Orders.
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
        return OrdersState();
      }
    }
    return OrdersState();
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

  /// Toggles a status in the multi-select status filter.
  void toggleStatusFilter(String status) {
    final current = Set<String>.from(state.selectedStatuses);
    final match = current.firstWhere(
      (s) => s.toLowerCase() == status.toLowerCase(),
      orElse: () => '',
    );
    if (match.isNotEmpty) {
      current.remove(match);
    } else {
      current.add(status);
    }
    state = state.copyWith(selectedStatuses: current);
  }

  /// Resets statuses to default: "Preparing", "Placed", "Delivering".
  void resetDefaultStatuses() {
    state = state.copyWith(selectedStatuses: const {'Preparing', 'Placed', 'Delivering'});
  }

  /// Sets single date or date range.
  void setDateFilter(DateTime start, [DateTime? end]) {
    final s = DateTime(start.year, start.month, start.day);
    final e = end != null ? DateTime(end.year, end.month, end.day) : null;
    state = state.copyWith(
      selectedDate: s,
      selectedEndDate: () => (e != null && !OrdersState.isSameDay(s, e)) ? e : null,
    );
  }

  /// Navigates date backwards:
  /// - If single date: previous day
  /// - If range: shifts range back by the span duration
  void navigateDatePrevious() {
    if (state.selectedEndDate == null) {
      final prev = state.selectedDate.subtract(const Duration(days: 1));
      state = state.copyWith(selectedDate: prev);
    } else {
      final spanDays = state.selectedEndDate!.difference(state.selectedDate).inDays.abs() + 1;
      final newStart = state.selectedDate.subtract(Duration(days: spanDays));
      final newEnd = state.selectedEndDate!.subtract(Duration(days: spanDays));
      state = state.copyWith(
        selectedDate: newStart,
        selectedEndDate: () => newEnd,
      );
    }
  }

  /// Navigates date forwards:
  /// - If single date: next day
  /// - If range: shifts range forward by the span duration
  void navigateDateNext() {
    if (state.selectedEndDate == null) {
      final next = state.selectedDate.add(const Duration(days: 1));
      state = state.copyWith(selectedDate: next);
    } else {
      final spanDays = state.selectedEndDate!.difference(state.selectedDate).inDays.abs() + 1;
      final newStart = state.selectedDate.add(Duration(days: spanDays));
      final newEnd = state.selectedEndDate!.add(Duration(days: spanDays));
      state = state.copyWith(
        selectedDate: newStart,
        selectedEndDate: () => newEnd,
      );
    }
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
