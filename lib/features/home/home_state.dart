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
    this.totalMoneyToCollect = 14850.0,
    this.customerCollections = const [
      CustomerCollectionEntry(customerName: 'Rajesh Sharma', phone: '+91 98765 43210', amountDue: 3400.0, orderCount: 2, status: 'Pending'),
      CustomerCollectionEntry(customerName: 'Priya Verma', phone: '+91 98123 45678', amountDue: 2150.0, orderCount: 1, status: 'Partial'),
      CustomerCollectionEntry(customerName: 'Amit Patel', phone: '+91 99887 76655', amountDue: 4800.0, orderCount: 3, status: 'Pending'),
      CustomerCollectionEntry(customerName: 'Sunita Gupta', phone: '+91 97654 32109', amountDue: 4500.0, orderCount: 2, status: 'Pending'),
    ],
    this.totalItemsSum = 10, // Sum = 10 (e.g. 2 + 5 + 3 cakes/items)
    this.itemSummaries = const [
      ItemQuantitySummary(name: 'Special Eggless Cake', quantity: 10, unit: 'pcs', emoji: '🎂'),
      ItemQuantitySummary(name: 'Motichoor Ladoo', quantity: 25, unit: 'kg', emoji: '🟡'),
      ItemQuantitySummary(name: 'Kaju Barfi', quantity: 18, unit: 'kg', emoji: '🍬'),
      ItemQuantitySummary(name: 'Bengali Rasgulla', quantity: 30, unit: 'pcs', emoji: '⚪'),
    ],
    this.totalOrdersCount = 12,
    this.recentOrders = const [
      OrderSummary(orderId: '#ORD-1089', customerName: 'Rajesh Sharma', customerPhone: '+91 98765 43210', time: '10:45 AM', itemsSummary: '3x Cake, 2kg Ladoo', totalAmount: 3400.0, status: 'Ready'),
      OrderSummary(orderId: '#ORD-1088', customerName: 'Priya Verma', customerPhone: '+91 98123 45678', time: '10:30 AM', itemsSummary: '2x Cake, 1kg Barfi', totalAmount: 2150.0, status: 'Preparing'),
      OrderSummary(orderId: '#ORD-1087', customerName: 'Amit Patel', customerPhone: '+91 99887 76655', time: '09:50 AM', itemsSummary: '5x Cake, 5kg Halwa', totalAmount: 4800.0, status: 'Preparing'),
      OrderSummary(orderId: '#ORD-1086', customerName: 'Sunita Gupta', customerPhone: '+91 97654 32109', time: '09:15 AM', itemsSummary: '3x Rasgulla Box, 2kg Peda', totalAmount: 4500.0, status: 'Delivered'),
    ],
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
