import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/database/models/payment_model.dart';

@immutable
class LedgerState {
  const LedgerState({
    this.payments = const [],
    this.searchQuery = '',
    this.typeFilter,
    this.paymentModeFilter,
    this.dateRange,
    this.isLoading = false,
  });

  final List<PaymentModel> payments;
  final String searchQuery;
  final PaymentType? typeFilter;
  final String? paymentModeFilter;
  final DateTimeRange? dateRange;
  final bool isLoading;

  /// Returns the filtered payments according to current filter criteria.
  List<PaymentModel> get filteredPayments {
    return payments.where((p) {
      // 1. Type filter
      if (typeFilter != null && p.type != typeFilter) {
        return false;
      }

      // 2. Payment mode filter
      if (paymentModeFilter != null &&
          paymentModeFilter!.isNotEmpty &&
          paymentModeFilter != 'All' &&
          p.paymentMode.toLowerCase() != paymentModeFilter!.toLowerCase()) {
        return false;
      }

      // 3. Date range filter
      if (dateRange != null) {
        final start = DateTime(dateRange!.start.year, dateRange!.start.month, dateRange!.start.day);
        final end = DateTime(dateRange!.end.year, dateRange!.end.month, dateRange!.end.day, 23, 59, 59);
        if (p.createdAt.isBefore(start) || p.createdAt.isAfter(end)) {
          return false;
        }
      }

      // 4. Search query
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final matchesId = p.id.toLowerCase().contains(q);
        final matchesOrder = p.orderId.toLowerCase().contains(q);
        final matchesCustomer = p.customerName.toLowerCase().contains(q);
        final matchesNote = p.note.toLowerCase().contains(q);
        final matchesRef = p.referenceNumber?.toLowerCase().contains(q) ?? false;
        if (!matchesId && !matchesOrder && !matchesCustomer && !matchesNote && !matchesRef) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Total money received (Credits) across filtered records.
  double get totalCredit => filteredPayments
      .where((p) => p.isCredit)
      .fold(0.0, (sum, p) => sum + p.amount);

  /// Total money refunded/returned (Debits) across filtered records.
  double get totalDebit => filteredPayments
      .where((p) => p.isDebit)
      .fold(0.0, (sum, p) => sum + p.amount);

  /// Net balance collected: totalCredit - totalDebit.
  double get netBalance => totalCredit - totalDebit;

  /// Count of credits.
  int get creditCount => filteredPayments.where((p) => p.isCredit).length;

  /// Count of debits.
  int get debitCount => filteredPayments.where((p) => p.isDebit).length;

  LedgerState copyWith({
    List<PaymentModel>? payments,
    String? searchQuery,
    PaymentType? Function()? typeFilter,
    String? Function()? paymentModeFilter,
    DateTimeRange? Function()? dateRange,
    bool? isLoading,
  }) {
    return LedgerState(
      payments: payments ?? this.payments,
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: typeFilter != null ? typeFilter() : this.typeFilter,
      paymentModeFilter: paymentModeFilter != null ? paymentModeFilter() : this.paymentModeFilter,
      dateRange: dateRange != null ? dateRange() : this.dateRange,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerState &&
          runtimeType == other.runtimeType &&
          listEquals(payments, other.payments) &&
          searchQuery == other.searchQuery &&
          typeFilter == other.typeFilter &&
          paymentModeFilter == other.paymentModeFilter &&
          dateRange == other.dateRange &&
          isLoading == other.isLoading;

  @override
  int get hashCode =>
      payments.hashCode ^
      searchQuery.hashCode ^
      typeFilter.hashCode ^
      paymentModeFilter.hashCode ^
      dateRange.hashCode ^
      isLoading.hashCode;
}
