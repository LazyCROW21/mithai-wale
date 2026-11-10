import 'package:flutter/foundation.dart';

/// Type of payment entry in the ledger.
enum PaymentType {
  /// Money received from customer (advance payment, full settlement, partial payment).
  credit,

  /// Money refunded or returned to customer (order return, cancellation refund, excess change).
  debit;

  static PaymentType fromString(String? val) {
    if (val == null) return PaymentType.credit;
    final clean = val.toLowerCase().trim();
    if (clean == 'debit' || clean == 'refund') return PaymentType.debit;
    return PaymentType.credit;
  }
}

/// A payment ledger record associated with an order or transaction.
@immutable
class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.paymentMode = 'Cash',
    this.note = '',
    this.customerName = '',
    this.referenceNumber,
  });

  /// Unique payment identifier, e.g. "PAY-1729381234"
  final String id;

  /// Associated Order ID, e.g. "#ORD-98765"
  final String orderId;

  /// Absolute monetary amount in rupees (always positive)
  final double amount;

  /// Credit (received) or Debit (refunded)
  final PaymentType type;

  /// Mode of payment: 'Cash', 'UPI', 'Card', 'Net Banking', 'Cheque', 'Other'
  final String paymentMode;

  /// Reason or note describing this transaction
  final String note;

  /// Optional customer name for quick identification
  final String customerName;

  /// Optional transaction ID, UPI reference or receipt number
  final String? referenceNumber;

  /// Date and time when the transaction took place
  final DateTime createdAt;

  bool get isCredit => type == PaymentType.credit;
  bool get isDebit => type == PaymentType.debit;

  String get typeDisplayName => isCredit ? 'Payment Received' : 'Refund Given';

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderId': orderId,
        'amount': amount,
        'type': type.name,
        'paymentMode': paymentMode,
        'note': note,
        'customerName': customerName,
        'referenceNumber': referenceNumber,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PaymentModel.fromMap(Map<dynamic, dynamic> map) {
    final rawType = map['type'] as String?;
    final amount = (map['amount'] as num?)?.toDouble() ?? 0.0;

    return PaymentModel(
      id: map['id'] as String? ?? '',
      orderId: map['orderId'] as String? ?? '',
      amount: amount < 0 ? amount.abs() : amount,
      type: PaymentType.fromString(rawType),
      paymentMode: map['paymentMode'] as String? ?? 'Cash',
      note: map['note'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      referenceNumber: map['referenceNumber'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  PaymentModel copyWith({
    String? id,
    String? orderId,
    double? amount,
    PaymentType? type,
    String? paymentMode,
    String? note,
    String? customerName,
    String? referenceNumber,
    DateTime? createdAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      paymentMode: paymentMode ?? this.paymentMode,
      note: note ?? this.note,
      customerName: customerName ?? this.customerName,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          orderId == other.orderId &&
          amount == other.amount &&
          type == other.type &&
          paymentMode == other.paymentMode &&
          note == other.note &&
          customerName == other.customerName &&
          referenceNumber == other.referenceNumber &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      orderId.hashCode ^
      amount.hashCode ^
      type.hashCode ^
      paymentMode.hashCode ^
      note.hashCode ^
      customerName.hashCode ^
      referenceNumber.hashCode ^
      createdAt.hashCode;
}
