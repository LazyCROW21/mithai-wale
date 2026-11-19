import 'package:flutter/foundation.dart';

import '../../core/database/models/order_model.dart';

/// Aggregated quantity and order count for a specific menu item scheduled for a delivery date.
@immutable
class MenuItemBuildSummary {
  const MenuItemBuildSummary({
    required this.name,
    required this.totalQuantity,
    required this.unit,
    required this.orderCount,
    required this.deliveryDate,
  });

  final String name;
  final double totalQuantity;
  final String unit;
  final int orderCount;
  final DateTime deliveryDate;

  /// Formatted quantity: integer if whole number (e.g. 12), else 1 decimal (e.g. 12.5).
  String get formattedQuantity {
    if (totalQuantity == totalQuantity.roundToDouble()) {
      return totalQuantity.toInt().toString();
    }
    return totalQuantity.toStringAsFixed(1);
  }

  /// String formatted as: "Ladoo = 12 kg (total 5 orders)"
  String get displayLine {
    final orderSuffix = orderCount == 1 ? 'order' : 'orders';
    return '$name = $formattedQuantity $unit (total $orderCount $orderSuffix)';
  }

  /// Friendly representation of the delivery date (e.g. "Today (21 Oct)", "Tomorrow (22 Oct)", or "25 Oct 2026")
  String get formattedDeliveryDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${deliveryDate.day} ${months[deliveryDate.month - 1]}';

    if (deliveryDate.year == today.year && deliveryDate.month == today.month && deliveryDate.day == today.day) {
      return 'Today ($dateStr)';
    } else if (deliveryDate.year == tomorrow.year && deliveryDate.month == tomorrow.month && deliveryDate.day == tomorrow.day) {
      return 'Tomorrow ($dateStr)';
    }
    return '$dateStr ${deliveryDate.year}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItemBuildSummary &&
          name == other.name &&
          totalQuantity == other.totalQuantity &&
          unit == other.unit &&
          orderCount == other.orderCount &&
          deliveryDate.year == other.deliveryDate.year &&
          deliveryDate.month == other.deliveryDate.month &&
          deliveryDate.day == other.deliveryDate.day;

  @override
  int get hashCode => Object.hash(
        name,
        totalQuantity,
        unit,
        orderCount,
        deliveryDate.year,
        deliveryDate.month,
        deliveryDate.day,
      );
}

@immutable
class HomeState {
  const HomeState({
    this.todayMoneyToCollect = 0.0,
    this.todayMoneyCollection = 0.0,
    this.totalMoneyCollection = 0.0,
    this.todayCreditTotal = 0.0,
    this.todayDebitTotal = 0.0,
    this.todayOrdersCount = 0,
    this.totalOrdersCount = 0,
    this.todayOrders = const [],
    this.allOrders = const [],
    this.orderBalances = const {},
    this.menuItemsToBuild = const [],
    this.isLoading = false,
  });

  /// Total money to collect from today's deliveries (taking into account proportional discounts for multi-date orders and payments received)
  final double todayMoneyToCollect;

  /// Total collection value (net bill after proportional discount) for items scheduled for delivery today from active orders
  final double todayMoneyCollection;

  /// Total money from all orders (excluding cancelled)
  final double totalMoneyCollection;

  /// Total credits (payments received) for today's active orders
  final double todayCreditTotal;

  /// Total debits (refunds given) for today's active orders
  final double todayDebitTotal;

  /// Count of active orders placed or having items delivering today
  final int todayOrdersCount;

  /// Total orders count across the database
  final int totalOrdersCount;

  /// Pending orders placed or delivering today (used in Today's Order Highlight)
  final List<OrderModel> todayOrders;

  /// All orders stored in Hive DB
  final List<OrderModel> allOrders;

  /// Balance left (finalBill - netReceived) keyed by orderId
  final Map<String, double> orderBalances;

  /// Aggregated items to build for kitchen production (excluding cancelled, refunded, and delivered)
  final List<MenuItemBuildSummary> menuItemsToBuild;

  /// Loading state indicator
  final bool isLoading;

  /// Net received for today's orders (credit - debit)
  double get todayNetReceived => todayCreditTotal - todayDebitTotal;

  /// Backward-compatible alias for today's collection/to collect
  double get totalMoneyToCollect => todayMoneyToCollect;

  /// Backward-compatible sum of distinct item types to build
  int get totalItemsSum => menuItemsToBuild.length;

  /// Items to build specifically for TODAY's deliveries
  List<MenuItemBuildSummary> get todayItemsToBuild {
    final now = DateTime.now();
    return menuItemsToBuild.where((item) {
      final d = item.deliveryDate;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }

  /// Items to build for FUTURE / UPCOMING dates
  List<MenuItemBuildSummary> get upcomingItemsToBuild {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return menuItemsToBuild.where((item) {
      final d = DateTime(item.deliveryDate.year, item.deliveryDate.month, item.deliveryDate.day);
      return d.isAfter(today);
    }).toList();
  }

  /// Items to build grouped by delivery date, sorted ascending
  Map<DateTime, List<MenuItemBuildSummary>> get groupedItemsToBuild {
    final groups = <DateTime, List<MenuItemBuildSummary>>{};
    for (final item in menuItemsToBuild) {
      final dateKey = DateTime(item.deliveryDate.year, item.deliveryDate.month, item.deliveryDate.day);
      groups.putIfAbsent(dateKey, () => []).add(item);
    }
    return groups;
  }

  HomeState copyWith({
    double? todayMoneyToCollect,
    double? todayMoneyCollection,
    double? totalMoneyCollection,
    double? todayCreditTotal,
    double? todayDebitTotal,
    int? todayOrdersCount,
    int? totalOrdersCount,
    List<OrderModel>? todayOrders,
    List<OrderModel>? allOrders,
    Map<String, double>? orderBalances,
    List<MenuItemBuildSummary>? menuItemsToBuild,
    bool? isLoading,
  }) {
    return HomeState(
      todayMoneyToCollect: todayMoneyToCollect ?? this.todayMoneyToCollect,
      todayMoneyCollection: todayMoneyCollection ?? this.todayMoneyCollection,
      totalMoneyCollection: totalMoneyCollection ?? this.totalMoneyCollection,
      todayCreditTotal: todayCreditTotal ?? this.todayCreditTotal,
      todayDebitTotal: todayDebitTotal ?? this.todayDebitTotal,
      todayOrdersCount: todayOrdersCount ?? this.todayOrdersCount,
      totalOrdersCount: totalOrdersCount ?? this.totalOrdersCount,
      todayOrders: todayOrders ?? this.todayOrders,
      allOrders: allOrders ?? this.allOrders,
      orderBalances: orderBalances ?? this.orderBalances,
      menuItemsToBuild: menuItemsToBuild ?? this.menuItemsToBuild,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeState &&
          todayMoneyToCollect == other.todayMoneyToCollect &&
          todayMoneyCollection == other.todayMoneyCollection &&
          totalMoneyCollection == other.totalMoneyCollection &&
          todayCreditTotal == other.todayCreditTotal &&
          todayDebitTotal == other.todayDebitTotal &&
          todayOrdersCount == other.todayOrdersCount &&
          totalOrdersCount == other.totalOrdersCount &&
          listEquals(todayOrders, other.todayOrders) &&
          listEquals(allOrders, other.allOrders) &&
          mapEquals(orderBalances, other.orderBalances) &&
          listEquals(menuItemsToBuild, other.menuItemsToBuild) &&
          isLoading == other.isLoading;

  @override
  int get hashCode => Object.hash(
        todayMoneyToCollect,
        todayMoneyCollection,
        totalMoneyCollection,
        todayCreditTotal,
        todayDebitTotal,
        todayOrdersCount,
        totalOrdersCount,
        todayOrders,
        allOrders,
        orderBalances,
        menuItemsToBuild,
        isLoading,
      );
}
