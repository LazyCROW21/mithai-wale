import 'package:flutter/foundation.dart';

/// Single item line breakdown within an order.
@immutable
class OrderItemDetail {
  const OrderItemDetail({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
  });

  final String name;
  final double quantity;
  final String unit;
  final double unitPrice;

  double get totalPrice => quantity * unitPrice;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItemDetail &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          quantity == other.quantity &&
          unit == other.unit &&
          unitPrice == other.unitPrice;

  @override
  int get hashCode =>
      name.hashCode ^ quantity.hashCode ^ unit.hashCode ^ unitPrice.hashCode;
}

/// Order model containing customer info, delivery date, items, and status.
@immutable
class OrderModel {
  const OrderModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.deliveryDate,
    required this.orderDate,
    required this.totalBill,
    required this.status,
  });

  final String id;
  final String customerName;
  final String customerPhone;
  final List<OrderItemDetail> items;
  final DateTime deliveryDate;
  final DateTime orderDate;
  final double totalBill;
  final String status; // 'Pending', 'Preparing', 'Ready', 'Delivered', 'Cancelled'

  /// Comma-separated list of item names without quantity, e.g. "Motichoor Ladoo, Kaju Barfi"
  String get itemsSummary => items.map((i) => i.name).join(', ');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          customerName == other.customerName &&
          customerPhone == other.customerPhone &&
          listEquals(items, other.items) &&
          deliveryDate == other.deliveryDate &&
          orderDate == other.orderDate &&
          totalBill == other.totalBill &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      customerName.hashCode ^
      customerPhone.hashCode ^
      items.hashCode ^
      deliveryDate.hashCode ^
      orderDate.hashCode ^
      totalBill.hashCode ^
      status.hashCode;
}

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
