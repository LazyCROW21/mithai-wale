import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/repositories/orders_repository.dart';
import '../../core/di/service_locator.dart';
import '../../core/state/shop_filter.dart';
import '../../core/sync/sync_engine.dart';
import 'orders_state.dart';

/// ViewModel managing state, search, filter, date navigation, and expandable cards for Orders.
class OrdersViewModel extends Notifier<OrdersState> {
  IOrdersRepository? get _ordersRepo =>
      sl.isRegistered<IOrdersRepository>() ? sl<IOrdersRepository>() : null;

  @override
  OrdersState build() {
    // Reload when sync brings in changes from other devices (keeps filters).
    ref.listen(syncStatusProvider.select((s) => s.dataRevision), (_, _) => loadOrders());
    // Franchise admin switched shops: reload (keeps filters).
    ref.listen(shopFilterProvider, (_, _) => loadOrders());
    final repo = _ordersRepo;
    if (repo != null) {
      try {
        final list = repo.getAllSync();
        return OrdersState(allOrders: _scoped(list));
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
        state = state.copyWith(allOrders: _scoped(list), isLoading: false);
      } catch (_) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Only the orders of the shop selected in the global shop filter (all when none).
  List<OrderModel> _scoped(List<OrderModel> list) {
    final filter = ref.read(shopFilterProvider.notifier);
    return list.where((o) => filter.matches(o.shopId)).toList();
  }

  /// Adds a new order (e.g. placed from the new-order dialog) and persists to Hive.
  Future<void> addOrder(OrderModel order) async {
    final updated = _scoped([order, ...state.allOrders.where((o) => o.id != order.id)]);
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

  /// Sets every delivery date of an order to [newStatus].
  Future<void> updateOrderStatus(String orderId, String newStatus) =>
      _replace(orderId, (o) => o.withAllStatus(newStatus));

  /// Sets the status of one delivery date (all items delivered on [day]);
  /// the order's overall status is re-derived.
  Future<void> updateDateStatus(String orderId, DateTime day, String newStatus) =>
      _replace(orderId, (o) => o.withDateStatus(day, newStatus));

  Future<void> _replace(String orderId, OrderModel Function(OrderModel) change) async {
    final current = state.allOrders.where((o) => o.id == orderId).firstOrNull;
    if (current == null) return;
    final next = change(current);
    state = state.copyWith(allOrders: [for (final o in state.allOrders) o.id == orderId ? next : o]);
    await _ordersRepo?.save(next);
  }
}
