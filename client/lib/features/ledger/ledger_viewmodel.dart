import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/models/payment_model.dart';
import '../../core/database/repositories/payments_repository.dart';
import '../../core/di/service_locator.dart';
import 'ledger_state.dart';

class LedgerViewModel extends Notifier<LedgerState> {
  IPaymentsRepository? get _repo =>
      sl.isRegistered<IPaymentsRepository>() ? sl<IPaymentsRepository>() : null;

  @override
  LedgerState build() {
    final repo = _repo;
    if (repo != null) {
      try {
        final list = repo.getAllSync();
        return LedgerState(payments: list);
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
        state = state.copyWith(payments: list, isLoading: false);
      } catch (_) {
        state = state.copyWith(isLoading: false);
      }
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Adds a new payment entry to memory and persists to Hive DB.
  Future<void> addPayment(PaymentModel payment) async {
    final current = List<PaymentModel>.from(state.payments);
    current.removeWhere((p) => p.id == payment.id);
    current.insert(0, payment); // Newest first

    state = state.copyWith(payments: current);
    await _repo?.save(payment);
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
