import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'orders_state.dart';
import 'orders_viewmodel.dart';

/// Riverpod provider for [OrdersViewModel].
final ordersViewModelProvider =
    NotifierProvider<OrdersViewModel, OrdersState>(OrdersViewModel.new);
