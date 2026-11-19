import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/models/payment_model.dart';
import '../../core/database/repositories/payments_repository.dart';
import '../../core/di/service_locator.dart';
import '../../core/state/shop_filter.dart';
import '../../core/sync/sync_engine.dart';
import 'ledger_state.dart';

class LedgerViewModel extends Notifier<LedgerState> {
  IPaymentsRepository? get _repo =>
      sl.isRegistered<IPaymentsRepository>() ? sl<IPaymentsRepository>() : null;

  @override
  LedgerState build() {
    // Reload when sync brings in changes from other devices (keeps filters).
    ref.listen(syncStatusProvider.select((s) => s.dataRevision), (_, _) => loadPayments());
    // Franchise admin switched shops: reload (keeps filters).
    ref.listen(shopFilterProvider, (_, _) => loadPayments());
    final repo = _repo;
    if (repo != null) {
      try {
        final list = repo.getAllSync();
        return LedgerState(payments: _scoped(list));
      } catch (_) {
        return const LedgerState();
      }
    }
    return const LedgerState();
  }

  /// Reloads all payments from repository.
  Future<void> loadPayments() async {
    state = state.copyWith(isLoading: true);
    final repo = _repo;
    if (repo != null) {
      try {
        final list = await repo.getAll();
        state = state.copyWith(payments: _scoped(list), isLoading: false);
      } catch (_) {
        state = state.copyWith(isLoading: false);
      }
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Only the entries of the shop selected in the global shop filter (all when none).
  List<PaymentModel> _scoped(List<PaymentModel> list) {
    final filter = ref.read(shopFilterProvider.notifier);
    return list.where((p) => filter.matches(p.shopId)).toList();
  }

  /// Adds a new payment entry and persists it; the stored record carries the
  /// resolved shop (order's shop first), so reload to pick it up.
  Future<void> addPayment(PaymentModel payment) async {
    await _repo?.save(payment);
    await loadPayments();
  }

  /// Deletes a payment entry by ID.
  Future<void> deletePayment(String paymentId) async {
    final current = List<PaymentModel>.from(state.payments);
    current.removeWhere((p) => p.id == paymentId);

    state = state.copyWith(payments: current);
    await _repo?.delete(paymentId);
  }

  /// Sets text search query.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Sets type filter (Credit, Debit, or null for all).
  void setTypeFilter(PaymentType? type) {
    state = state.copyWith(typeFilter: () => type);
  }

  /// Sets payment mode filter ('Cash', 'UPI', etc., or null for all).
  void setPaymentModeFilter(String? mode) {
    state = state.copyWith(paymentModeFilter: () => mode);
  }

  /// Sets date range filter.
  void setDateRange(DateTimeRange? range) {
    state = state.copyWith(dateRange: () => range);
  }

  /// Clears all active filters.
  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      typeFilter: () => null,
      paymentModeFilter: () => null,
      dateRange: () => null,
    );
  }
}
