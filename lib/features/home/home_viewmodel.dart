import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/models/order_model.dart';
import '../../core/database/models/payment_model.dart';
import '../ledger/ledger_providers.dart';
import '../orders/orders_providers.dart';
import 'home_state.dart';

class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() {
    final ordersState = ref.watch(ordersViewModelProvider);
    final ledgerState = ref.watch(ledgerViewModelProvider);
    return _computeState(ordersState.allOrders, ledgerState.payments);
  }

  Future<void> refreshDashboard() async {
    state = state.copyWith(isLoading: true);
    await Future.wait([
      ref.read(ordersViewModelProvider.notifier).loadOrders(),
      ref.read(ledgerViewModelProvider.notifier).loadPayments(),
    ]);
    state = state.copyWith(isLoading: false);
  }

  static bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  static HomeState _computeState(
    List<OrderModel> allOrders,
    List<PaymentModel> allPayments,
  ) {
    // Group payments by orderId (normalized lowercased without leading #)
    final paymentsMap = <String, List<PaymentModel>>{};
    for (final p in allPayments) {
      final key = p.orderId.toLowerCase().replaceAll('#', '').trim();
      if (key.isNotEmpty) {
        paymentsMap.putIfAbsent(key, () => []).add(p);
      }
    }

    // 1. Filter orders strictly for today (created today or scheduled for delivery today)
    final todayAllOrders = allOrders.where((o) {
      return _isToday(o.orderDate) || _isToday(o.deliveryDate);
    }).toList();

    // 2. Filter today's active orders (excluding cancelled or refunded/returned)
    final todayActiveOrders = todayAllOrders.where((o) {
      final s = o.status.toLowerCase().trim();
      return s != 'cancelled' && s != 'returned' && s != 'refunded';
    }).toList();

    // Calculate balances and totals for today's active orders
    final orderBalances = <String, double>{};
    double todayCreditTotal = 0.0;
    double todayDebitTotal = 0.0;
    double todayTotalBill = 0.0;
    double todayMoneyToCollect = 0.0;

    for (final order in todayActiveOrders) {
      final normId = order.id.toLowerCase().replaceAll('#', '').trim();
      final orderPayments = paymentsMap[normId] ?? const [];

      final credit = orderPayments
          .where((p) => p.isCredit)
          .fold<double>(0.0, (sum, p) => sum + p.amount);
      final debit = orderPayments
          .where((p) => !p.isCredit)
          .fold<double>(0.0, (sum, p) => sum + p.amount);
      final netReceived = credit - debit;
      final balance = order.finalBill - netReceived;

      orderBalances[order.id] = balance;
      todayCreditTotal += credit;
      todayDebitTotal += debit;
      todayTotalBill += order.finalBill;

      if (balance > 0.009) {
        todayMoneyToCollect += balance;
      }
    }

    // Today's pending orders to highlight:
    // From today's active orders (non-cancelled, non-refunded), include those
    // that are still pending fulfillment (not delivered/completed) OR have pending payment collection/refund.
    final todayPendingOrders = todayActiveOrders.where((o) {
      final s = o.status.toLowerCase().trim();
      final isFulfilled = (s == 'delivered' || s == 'completed');
      final balance = orderBalances[o.id] ?? o.finalBill;
      final isPaymentSettled = balance.abs() <= 0.009;
      return !(isFulfilled && isPaymentSettled);
    }).toList();

    // Total money collection across all active orders in DB
    final totalMoneyCollection = allOrders
        .where((o) {
          final s = o.status.toLowerCase().trim();
          return s != 'cancelled' && s != 'returned' && s != 'refunded';
        })
        .fold<double>(0.0, (sum, o) => sum + o.finalBill);

    // 3. Menu items to build: filter out items from orders that are cancelled, refunded or delivered
    final menuItemsToBuild = _calculateItemsToBuild(allOrders);

    return HomeState(
      todayMoneyToCollect: todayMoneyToCollect,
      todayMoneyCollection: todayTotalBill,
      totalMoneyCollection: totalMoneyCollection,
      todayCreditTotal: todayCreditTotal,
      todayDebitTotal: todayDebitTotal,
      todayOrdersCount: todayActiveOrders.length,
      totalOrdersCount: allOrders.length,
      todayOrders: todayPendingOrders,
      allOrders: allOrders,
      orderBalances: orderBalances,
      menuItemsToBuild: menuItemsToBuild,
      isLoading: false,
    );
  }

  static List<MenuItemBuildSummary> _calculateItemsToBuild(
    List<OrderModel> orders,
  ) {
    // Filter out items from orders that are cancelled, refunded (or returned), or delivered (or completed)
    final activeOrders = orders.where((o) {
      final s = o.status.toLowerCase().trim();
      return s != 'cancelled' &&
          s != 'returned' &&
          s != 'refunded' &&
          s != 'delivered' &&
          s != 'completed';
    }).toList();

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
