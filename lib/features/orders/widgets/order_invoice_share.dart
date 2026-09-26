import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/models/order_model.dart';

/// Formats the order into a clean, printable text receipt invoice.
String generateOrderInvoiceText(OrderModel order) {
  final buffer = StringBuffer();
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  String formatDate(DateTime d) => '${d.day} ${months[d.month - 1]} ${d.year}';
  String formatDateTime(DateTime d) =>
      '${d.day} ${months[d.month - 1]} ${d.year}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  buffer.writeln('====================================');
  buffer.writeln('       मिठाई वाले (MITHAI WALE)');
  buffer.writeln('        TAX INVOICE / BILL');
  buffer.writeln('====================================');
  buffer.writeln('Order ID:      ${order.id}');
  buffer.writeln('Status:        ${order.status}');
  buffer.writeln('Date & Time:   ${formatDateTime(order.orderDate)}');
  buffer.writeln('Delivery Date: ${formatDate(order.deliveryDate)}');
  buffer.writeln('------------------------------------');
  buffer.writeln('CUSTOMER:');
  buffer.writeln('Name:          ${order.customerName}');
  buffer.writeln('Phone:         ${order.customerPhone}');
  buffer.writeln('------------------------------------');
  buffer.writeln('ITEMS:');
  for (int i = 0; i < order.items.length; i++) {
    final item = order.items[i];
    final qtyStr = item.quantity % 1 == 0
        ? item.quantity.toInt().toString()
        : item.quantity.toString();
    buffer.writeln('${i + 1}. ${item.name}');
    buffer.writeln('   $qtyStr ${item.unit} x ₹${item.unitPrice.toStringAsFixed(2)} = ₹${item.totalPrice.toStringAsFixed(2)}');
  }
  buffer.writeln('------------------------------------');
  buffer.writeln('Subtotal:       ₹${order.subtotal.toStringAsFixed(2)}');
  if (order.discountType != null && order.calculatedDiscount > 0) {
    final label = order.discountType == DiscountType.percentage
        ? 'Discount (${order.discountAmount % 1 == 0 ? order.discountAmount.toInt() : order.discountAmount}%):'
        : 'Discount (Flat):';
    buffer.writeln('$label  -₹${order.calculatedDiscount.toStringAsFixed(2)}');
  }
  buffer.writeln('------------------------------------');
  buffer.writeln('TOTAL BILL:     ₹${order.finalBill.toStringAsFixed(2)}');
  buffer.writeln('====================================');
  buffer.writeln('    Thank you! Visit again.');
  buffer.writeln('====================================');

  return buffer.toString();
}

/// Directly shares the order text bill invoice using share_plus.
Future<void> shareOrderInvoice(BuildContext context, OrderModel order) async {
  final invoice = generateOrderInvoiceText(order);
  try {
    await SharePlus.instance.share(
      ShareParams(
        text: invoice,
        subject: 'Bill Invoice - ${order.id} - Mithai Wale',
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share invoice: $e')),
      );
    }
  }
}
