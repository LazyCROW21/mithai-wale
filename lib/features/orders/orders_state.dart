import 'package:flutter/foundation.dart';
import '../../core/database/models/order_model.dart';

export '../../core/database/models/order_model.dart';

/// Immutable state for Orders feature.
@immutable
class OrdersState {
  const OrdersState({
    this.allOrders = const [],
    this.searchQuery = '',
    this.statusFilter = 'All',
    this.selectedDate,
    this.expandedOrderIds = const {},
    this.isLoading = false,
  });

  final List<OrderModel> allOrders;
  final String searchQuery;
  final String statusFilter;
  final DateTime? selectedDate;
  final Set<String> expandedOrderIds;
  final bool isLoading;

  List<OrderModel> get filteredOrders {
    return allOrders.where((order) {
      // 1. Search filter: search by customer name OR order item name OR order id
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final matchesCustomer = order.customerName.toLowerCase().contains(query);
        final matchesId = order.id.toLowerCase().contains(query);
        final matchesItem = order.items.any((item) => item.name.toLowerCase().contains(query));
        if (!matchesCustomer && !matchesId && !matchesItem) {
          return false;
        }
      }

      // 2. Status filter
      if (statusFilter != 'All' && order.status.toLowerCase() != statusFilter.toLowerCase()) {
        return false;
      }

      // 3. Date filter (filter by delivery date)
      if (selectedDate != null) {
        final d = order.deliveryDate;
        final s = selectedDate!;
        if (d.year != s.year || d.month != s.month || d.day != s.day) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  OrdersState copyWith({
    List<OrderModel>? allOrders,
    String? searchQuery,
    String? statusFilter,
    DateTime? Function()? selectedDate,
    Set<String>? expandedOrderIds,
    bool? isLoading,
  }) {
    return OrdersState(
      allOrders: allOrders ?? this.allOrders,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      selectedDate: selectedDate != null ? selectedDate() : this.selectedDate,
      expandedOrderIds: expandedOrderIds ?? this.expandedOrderIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrdersState &&
          runtimeType == other.runtimeType &&
          listEquals(allOrders, other.allOrders) &&
          searchQuery == other.searchQuery &&
          statusFilter == other.statusFilter &&
          selectedDate == other.selectedDate &&
          setEquals(expandedOrderIds, other.expandedOrderIds) &&
          isLoading == other.isLoading;

  @override
  int get hashCode =>
      allOrders.hashCode ^
      searchQuery.hashCode ^
      statusFilter.hashCode ^
      selectedDate.hashCode ^
      expandedOrderIds.hashCode ^
      isLoading.hashCode;
}
