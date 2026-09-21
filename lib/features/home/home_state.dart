import 'package:flutter/foundation.dart';

@immutable
class CustomerCollectionEntry {
  const CustomerCollectionEntry({
    required this.customerName,
    required this.phone,
    required this.amountDue,
    required this.orderCount,
    required this.status,
  });

  final String customerName;
  final String phone;
  final double amountDue;
  final int orderCount;
  final String status; // 'Pending', 'Partial', 'Paid'
}

@immutable
class ItemQuantitySummary {
  const ItemQuantitySummary({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.emoji,
  });

  final String name;
  final int quantity;
  final String unit;
  final String emoji;
}

@immutable
class OrderSummary {
  const OrderSummary({
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.time,
    required this.itemsSummary,
    required this.totalAmount,
    required this.status,
  });

  final String orderId;
  final String customerName;
  final String customerPhone;
  final String time;
  final String itemsSummary;
  final double totalAmount;
  final String status; // 'Preparing', 'Ready', 'Delivered'
}

@immutable
class HomeState {
  const HomeState({
    this.selectedNavIndex = 0,
    this.selectedCategory = 'All',
    this.totalMoneyToCollect = 0.0,
    this.customerCollections = const [],
    this.totalItemsSum = 0,
    this.itemSummaries = const [],
    this.totalOrdersCount = 0,
    this.recentOrders = const [],
    this.isLoading = false,
  });

  final int selectedNavIndex;
  final String selectedCategory;
  final double totalMoneyToCollect;
  final List<CustomerCollectionEntry> customerCollections;
  final int totalItemsSum;
  final List<ItemQuantitySummary> itemSummaries;
  final int totalOrdersCount;
  final List<OrderSummary> recentOrders;
  final bool isLoading;

  HomeState copyWith({
    int? selectedNavIndex,
    String? selectedCategory,
    double? totalMoneyToCollect,
    List<CustomerCollectionEntry>? customerCollections,
    int? totalItemsSum,
    List<ItemQuantitySummary>? itemSummaries,
    int? totalOrdersCount,
    List<OrderSummary>? recentOrders,
    bool? isLoading,
  }) {
    return HomeState(
      selectedNavIndex: selectedNavIndex ?? this.selectedNavIndex,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      totalMoneyToCollect: totalMoneyToCollect ?? this.totalMoneyToCollect,
      customerCollections: customerCollections ?? this.customerCollections,
      totalItemsSum: totalItemsSum ?? this.totalItemsSum,
      itemSummaries: itemSummaries ?? this.itemSummaries,
      totalOrdersCount: totalOrdersCount ?? this.totalOrdersCount,
      recentOrders: recentOrders ?? this.recentOrders,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeState &&
          selectedNavIndex == other.selectedNavIndex &&
          selectedCategory == other.selectedCategory &&
          totalMoneyToCollect == other.totalMoneyToCollect &&
          listEquals(customerCollections, other.customerCollections) &&
          totalItemsSum == other.totalItemsSum &&
          listEquals(itemSummaries, other.itemSummaries) &&
          totalOrdersCount == other.totalOrdersCount &&
          listEquals(recentOrders, other.recentOrders) &&
          isLoading == other.isLoading;

  @override
  int get hashCode => Object.hash(
        selectedNavIndex,
        selectedCategory,
        totalMoneyToCollect,
        customerCollections,
        totalItemsSum,
        itemSummaries,
        totalOrdersCount,
        recentOrders,
        isLoading,
      );
}
