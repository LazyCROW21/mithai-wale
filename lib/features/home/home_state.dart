import 'package:flutter/foundation.dart';

import '../../core/database/models/order_model.dart';

/// Aggregated quantity and order count for a specific menu item across orders.
@immutable
class MenuItemBuildSummary {
  const MenuItemBuildSummary({
    required this.name,
    required this.totalQuantity,
    required this.unit,
    required this.orderCount,
  });

  final String name;
  final double totalQuantity;
  final String unit;
  final int orderCount;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItemBuildSummary &&
          name == other.name &&
          totalQuantity == other.totalQuantity &&
          unit == other.unit &&
          orderCount == other.orderCount;

  @override
  int get hashCode => Object.hash(name, totalQuantity, unit, orderCount);
}

@immutable
class HomeState {
  const HomeState({
    this.todayMoneyCollection = 0.0,
    this.totalMoneyCollection = 0.0,
    this.todayOrdersCount = 0,
    this.totalOrdersCount = 0,
    this.todayOrders = const [],
    this.allOrders = const [],
    this.menuItemsToBuild = const [],
    this.isLoading = false,
  });

  /// Total money to collect from today's orders (excluding cancelled)
  final double todayMoneyCollection;

  /// Total money from all orders (excluding cancelled)
  final double totalMoneyCollection;

  /// Count of orders placed or scheduled for today
  final int todayOrdersCount;

  /// Total orders count across the database
  final int totalOrdersCount;

  /// Orders placed or delivering today
  final List<OrderModel> todayOrders;

  /// All orders stored in Hive DB
  final List<OrderModel> allOrders;

  /// Aggregated items to build for kitchen production across all orders
  final List<MenuItemBuildSummary> menuItemsToBuild;

  /// Loading state indicator
  final bool isLoading;

  /// Backward-compatible alias for today's collection
  double get totalMoneyToCollect => todayMoneyCollection;

  /// Backward-compatible sum of distinct item types to build
  int get totalItemsSum => menuItemsToBuild.length;

  HomeState copyWith({
    double? todayMoneyCollection,
    double? totalMoneyCollection,
    int? todayOrdersCount,
    int? totalOrdersCount,
    List<OrderModel>? todayOrders,
    List<OrderModel>? allOrders,
    List<MenuItemBuildSummary>? menuItemsToBuild,
    bool? isLoading,
  }) {
    return HomeState(
      todayMoneyCollection: todayMoneyCollection ?? this.todayMoneyCollection,
      totalMoneyCollection: totalMoneyCollection ?? this.totalMoneyCollection,
      todayOrdersCount: todayOrdersCount ?? this.todayOrdersCount,
      totalOrdersCount: totalOrdersCount ?? this.totalOrdersCount,
      todayOrders: todayOrders ?? this.todayOrders,
      allOrders: allOrders ?? this.allOrders,
      menuItemsToBuild: menuItemsToBuild ?? this.menuItemsToBuild,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeState &&
          todayMoneyCollection == other.todayMoneyCollection &&
          totalMoneyCollection == other.totalMoneyCollection &&
          todayOrdersCount == other.todayOrdersCount &&
          totalOrdersCount == other.totalOrdersCount &&
          listEquals(todayOrders, other.todayOrders) &&
          listEquals(allOrders, other.allOrders) &&
          listEquals(menuItemsToBuild, other.menuItemsToBuild) &&
          isLoading == other.isLoading;

  @override
  int get hashCode => Object.hash(
        todayMoneyCollection,
        totalMoneyCollection,
        todayOrdersCount,
        totalOrdersCount,
        todayOrders,
        allOrders,
        menuItemsToBuild,
        isLoading,
      );
}
