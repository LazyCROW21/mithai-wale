import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/models/payment_model.dart';
import 'ledger_state.dart';
import 'ledger_viewmodel.dart';

/// Provider for the payment ledger state.
final ledgerViewModelProvider =
    NotifierProvider<LedgerViewModel, LedgerState>(LedgerViewModel.new);

/// Family provider that provides all payments associated with a specific [orderId],
/// automatically updated whenever the ledger changes.
final orderPaymentsProvider =
    Provider.family<List<PaymentModel>, String>((ref, orderId) {
  final all = ref.watch(ledgerViewModelProvider.select((s) => s.payments));
  final filtered = all
      .where((p) => p.orderId.toLowerCase() == orderId.toLowerCase())
      .toList();
  // Sort chronological descending (newest first)
  filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return filtered;
});
