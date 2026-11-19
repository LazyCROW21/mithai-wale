import 'package:flutter/foundation.dart';

import '../../../core/database/models/order_model.dart';
import '../../../core/database/models/payment_model.dart';

/// One printed line of a bill.
@immutable
class BillLine {
  const BillLine({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.amount,
    required this.deliveryDate,
  });

  final String name;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double amount;
  final DateTime deliveryDate;
}

/// Tax breakdown for a GST invoice. Not produced yet: when a bill carries one
/// it prints as a tax invoice.
@immutable
class BillTax {
  const BillTax({required this.lines, required this.total});

  /// Label → amount, e.g. "CGST 2.5%" → 12.50.
  final Map<String, double> lines;
  final double total;
}

/// Everything a bill prints, with all money already worked out. Templates
/// never read orders, payments or repositories.
@immutable
class BillData {
  const BillData({
    required this.billNumber,
    required this.orderDate,
    required this.customerName,
    required this.customerPhone,
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paid,
    this.token,
    this.discountPercent,
    this.invoiceNumber,
    this.tax,
  });

  final String billNumber;
  final String? token;
  final DateTime orderDate;
  final String customerName;
  final String customerPhone;
  final List<BillLine> lines;
  final double subtotal;
  final double discount;

  /// Set when the discount was given as a percentage.
  final double? discountPercent;
  final double total;
  final double paid;

  /// Reserved for GST: a sequential invoice number and the tax breakdown.
  final String? invoiceNumber;
  final BillTax? tax;

  double get balance => total - paid;
  bool get isTaxInvoice => tax != null;

  /// Builds the bill of [order]; [payments] are the ledger entries of that order.
  factory BillData.fromOrder(OrderModel order, List<PaymentModel> payments) {
    final paid = payments.fold<double>(0, (sum, p) => sum + (p.isCredit ? p.amount : -p.amount));
    return BillData(
      billNumber: order.id,
      token: order.token,
      orderDate: order.orderDate,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      lines: [
        for (final i in OrderModel.sortLines(order.items))
          BillLine(
            name: i.name,
            quantity: i.quantity,
            unit: i.unit,
            unitPrice: i.unitPrice,
            amount: i.totalPrice,
            deliveryDate: i.deliveryDate,
          ),
      ],
      subtotal: order.subtotal,
      discount: order.calculatedDiscount,
      discountPercent:
          order.discountType == DiscountType.percentage ? order.discountAmount : null,
      total: order.finalBill,
      paid: paid,
    );
  }
}
