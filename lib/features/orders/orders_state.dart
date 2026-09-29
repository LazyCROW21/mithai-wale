import 'package:flutter/foundation.dart';
import '../../core/database/models/order_model.dart';
import 'utils/order_date_formatter.dart';

export '../../core/database/models/order_model.dart';

/// Immutable state for Orders feature.
@immutable
class OrdersState {
  OrdersState({
    this.allOrders = const [],
    this.searchQuery = '',
    this.selectedStatuses = const {'Preparing', 'Placed', 'Delivering'},
    DateTime? selectedDate,
    this.selectedEndDate,
    this.expandedOrderIds = const {},
    this.isLoading = false,
  }) : selectedDate = selectedDate ?? _today();

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  final List<OrderModel> allOrders;
  final String searchQuery;

  /// Multi-selectable statuses. Default: "Preparing", "Placed", "Delivering".
  final Set<String> selectedStatuses;

  /// Selected start/single date for filter. Defaults to Today.
  final DateTime selectedDate;

  /// If non-null, filter is a date range [selectedDate, selectedEndDate].
  final DateTime? selectedEndDate;

  final Set<String> expandedOrderIds;
  final bool isLoading;

  /// Formatted title of current date or date range.
  String get dateTitle => formatOrderDateTitle(selectedDate, selectedEndDate);

  /// Whether current date filter is a range.
  bool get isRange => selectedEndDate != null && !isSameDay(selectedDate, selectedEndDate!);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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

      // 2. Status filter: multi-select matching
      if (selectedStatuses.isEmpty) {
        return false;
      }
      final matchesStatus = selectedStatuses.any(
        (s) => s.toLowerCase() == order.status.toLowerCase(),
      );
      if (!matchesStatus) {
        return false;
      }

      // 3. Date filter: filter by delivery date (or order date if delivery date not set)
      final d = DateTime(order.deliveryDate.year, order.deliveryDate.month, order.deliveryDate.day);
      final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

      if (selectedEndDate == null) {
        if (!isSameDay(d, start)) {
          return false;
        }
      } else {
        final end = DateTime(selectedEndDate!.year, selectedEndDate!.month, selectedEndDate!.day);
        final minD = start.isBefore(end) ? start : end;
        final maxD = start.isBefore(end) ? end : start;
        if (d.isBefore(minD) || d.isAfter(maxD)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  OrdersState copyWith({
    List<OrderModel>? allOrders,
    String? searchQuery,
    Set<String>? selectedStatuses,
    DateTime? selectedDate,
    DateTime? Function()? selectedEndDate,
    Set<String>? expandedOrderIds,
    bool? isLoading,
  }) {
    return OrdersState(
      allOrders: allOrders ?? this.allOrders,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedEndDate: selectedEndDate != null ? selectedEndDate() : this.selectedEndDate,
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
          setEquals(selectedStatuses, other.selectedStatuses) &&
          selectedDate == other.selectedDate &&
          selectedEndDate == other.selectedEndDate &&
          setEquals(expandedOrderIds, other.expandedOrderIds) &&
          isLoading == other.isLoading;

  @override
  int get hashCode =>
      allOrders.hashCode ^
      searchQuery.hashCode ^
      selectedStatuses.hashCode ^
      selectedDate.hashCode ^
      selectedEndDate.hashCode ^
      expandedOrderIds.hashCode ^
      isLoading.hashCode;
}
