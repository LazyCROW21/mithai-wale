import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/models/order_model.dart';
import '../orders/orders_providers.dart';
import 'home_state.dart';

class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() {
    final ordersState = ref.watch(ordersViewModelProvider);
    final allOrders = ordersState.allOrders;
    return _computeState(allOrders);
  }

  Future<void> refreshDashboard() async {
    state = state.copyWith(isLoading: true);
    await ref.read(ordersViewModelProvider.notifier).loadOrders();
    state = state.copyWith(isLoading: false);
  }

  static bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  static HomeState _computeState(List<OrderModel> allOrders) {
    // 1. Filter orders strictly for today (created today or scheduled for delivery today)
    final todayOrders = allOrders.where((o) {
      return _isToday(o.orderDate) || _isToday(o.deliveryDate);
    }).toList();

    // 2. Today's money collection (sum of finalBill of non-cancelled orders today)
    final todayMoneyCollection = todayOrders
        .where((o) => o.status.toLowerCase() != 'cancelled')
        .fold<double>(0.0, (sum, o) => sum + o.finalBill);

    // Total money collection across all orders
    final totalMoneyCollection = allOrders
        .where((o) => o.status.toLowerCase() != 'cancelled')
        .fold<double>(0.0, (sum, o) => sum + o.finalBill);

    // 3. Menu items to build from ALL active/non-cancelled orders
    final menuItemsToBuild = _calculateItemsToBuild(allOrders);

    return HomeState(
      todayMoneyCollection: todayMoneyCollection,
      totalMoneyCollection: totalMoneyCollection,
      todayOrdersCount: todayOrders.length,
      totalOrdersCount: allOrders.length,
      todayOrders: todayOrders,
      allOrders: allOrders,
      menuItemsToBuild: menuItemsToBuild,
      isLoading: false,
    );
  }

  static List<MenuItemBuildSummary> _calculateItemsToBuild(
    List<OrderModel> orders,
  ) {
    // Exclude cancelled orders
    final activeOrders =
        orders.where((o) => o.status.toLowerCase() != 'cancelled').toList();

    // Key: lowercase item name -> helper aggregator
    final map = <String, _ItemAggregator>{};

    for (final order in activeOrders) {
      final seenKeysInThisOrder = <String>{};

      for (final item in order.items) {
        final name = item.name.trim();
        if (name.isEmpty) continue;
        final key = name.toLowerCase();

        final agg = map.putIfAbsent(
          key,
          () => _ItemAggregator(
            displayName: name,
            unit: item.unit.isNotEmpty ? item.unit : 'kg',
          ),
        );

        agg.totalQuantity += item.quantity;
        if (!seenKeysInThisOrder.contains(key)) {
          agg.orderCount += 1;
          seenKeysInThisOrder.add(key);
        }
      }
    }

    final list = map.values
        .map(
          (a) => MenuItemBuildSummary(
            name: a.displayName,
            totalQuantity: a.totalQuantity,
            unit: a.unit,
            orderCount: a.orderCount,
          ),
        )
        .toList();

    // Sort by highest quantity descending
    list.sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));
    return list;
  }
}

class _ItemAggregator {
  _ItemAggregator({
    required this.displayName,
    required this.unit,
  });

  final String displayName;
  final String unit;
  double totalQuantity = 0.0;
  int orderCount = 0;
}
