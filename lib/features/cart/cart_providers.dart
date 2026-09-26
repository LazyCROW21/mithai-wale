import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cart_state.dart';
import 'cart_viewmodel.dart';

/// App-wide global cart provider.
///
/// Use `ref.watch(cartProvider)` to observe cart state.
/// Use `ref.read(cartProvider.notifier)` to mutate cart state.
final cartProvider =
    NotifierProvider<CartViewModel, CartState>(CartViewModel.new);
