import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'orders_state.dart';

/// ViewModel managing state, search, filter, and expandable cards for Orders.
class OrdersViewModel extends Notifier<OrdersState> {
  @override
  OrdersState build() {
    return OrdersState(
      allOrders: _generateInitialOrders(),
    );
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

  void updateOrderStatus(String orderId, String newStatus) {
    final updated = state.allOrders.map((o) {
      if (o.id == orderId) {
        return OrderModel(
          id: o.id,
          customerName: o.customerName,
          customerPhone: o.customerPhone,
          items: o.items,
          deliveryDate: o.deliveryDate,
          orderDate: o.orderDate,
          totalBill: o.totalBill,
          status: newStatus,
        );
      }
      return o;
    }).toList();
    state = state.copyWith(allOrders: updated);
  }

  List<OrderModel> _generateInitialOrders() {
    return const [];
  }
}
