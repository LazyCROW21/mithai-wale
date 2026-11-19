import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/printing/print_document.dart';
import '../../../core/printing/print_widgets.dart';
import 'bill_data.dart';

/// Customer-facing bill. Prints as a tax invoice once [BillData.tax] is set.
class BillDocument extends PrintDocument {
  const BillDocument(this.data, {super.strings});

  final BillData data;

  String get _heading => data.isTaxInvoice ? strings.taxInvoice : strings.bill;
  String get _numberLabel => data.isTaxInvoice ? strings.invoiceNo : strings.billNo;
  String get _number => data.invoiceNumber ?? data.billNumber;

  @override
  String get title => '$_heading $_number';

  @override
  String get fileName {
    final safe = _number.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '');
    return 'bill-${safe.isEmpty ? 'order' : safe}.pdf';
  }

  String get _discountLabel => data.discountPercent == null
      ? strings.discount
      : '${strings.discount} (${printQty(data.discountPercent!)}%)';

  /// Subtotal → total → balance, shared by both layouts.
  List<pw.Widget> _totals({double? fontSize}) => [
        printKeyValue(strings.subtotal, printMoney(data.subtotal), fontSize: fontSize),
        if (data.discount > 0)
          printKeyValue(_discountLabel, '- ${printMoney(data.discount)}', fontSize: fontSize),
        if (data.tax != null)
          for (final t in data.tax!.lines.entries)
            printKeyValue(t.key, printMoney(t.value), fontSize: fontSize),
        printDivider(space: 3),
        printKeyValue(
          strings.total,
          printMoney(data.total),
          bold: true,
          fontSize: fontSize == null ? 12 : fontSize + 2,
        ),
        printKeyValue(strings.paid, printMoney(data.paid), fontSize: fontSize),
        printKeyValue(strings.balanceDue, printMoney(data.balance), bold: true, fontSize: fontSize),
      ];

  @override
  List<pw.Widget> buildPage() {
    final label = pw.TextStyle(fontSize: 9, color: printMuted);
    final bold = pw.TextStyle(fontWeight: pw.FontWeight.bold);

    return [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(_heading, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text(strings.billTo, style: label),
                pw.Text(data.customerName, style: bold),
                if (data.customerPhone.isNotEmpty) pw.Text(data.customerPhone),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('$_numberLabel: $_number', style: bold),
              if ((data.token ?? '').isNotEmpty) pw.Text('${strings.token}: ${data.token}'),
              pw.Text('${strings.date}: ${printDate(data.orderDate)}'),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 16),
      pw.TableHelper.fromTextArray(
        headers: ['#', strings.item, strings.delivery, strings.qty, strings.rate, strings.amount],
        data: [
          for (final (i, l) in data.lines.indexed)
            [
              '${i + 1}',
              l.name,
              printDate(l.deliveryDate),
              '${printQty(l.quantity)} ${l.unit}',
              printMoney(l.unitPrice),
              printMoney(l.amount),
            ],
        ],
        headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellStyle: const pw.TextStyle(fontSize: 10),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        border: pw.TableBorder.all(color: printRule, width: 0.5),
        columnWidths: const {
          0: pw.FixedColumnWidth(24),
          1: pw.FlexColumnWidth(3.2),
          2: pw.FlexColumnWidth(1.6),
          3: pw.FlexColumnWidth(1.2),
          4: pw.FlexColumnWidth(1.5),
          5: pw.FlexColumnWidth(1.7),
        },
        cellAlignments: const {
          0: pw.Alignment.centerRight,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.centerLeft,
          3: pw.Alignment.centerRight,
          4: pw.Alignment.centerRight,
          5: pw.Alignment.centerRight,
        },
      ),
      pw.SizedBox(height: 12),
      pw.Row(
        children: [
          pw.Spacer(flex: 3),
          pw.Expanded(flex: 2, child: pw.Column(children: _totals(fontSize: 10.5))),
        ],
      ),
      pw.SizedBox(height: 24),
      pw.Center(child: pw.Text(strings.thankYou, style: label)),
    ];
  }

  @override
  List<pw.Widget> buildThermal() {
    final bold = pw.TextStyle(fontWeight: pw.FontWeight.bold);
    final muted = pw.TextStyle(fontSize: 7, color: printMuted);

    return [
      pw.Center(child: pw.Text(_heading, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 4),
      printKeyValue(_numberLabel, _number),
      if ((data.token ?? '').isNotEmpty) printKeyValue(strings.token, data.token!),
      printKeyValue(strings.date, printDate(data.orderDate)),
      printKeyValue(strings.customer, data.customerName),
      if (data.customerPhone.isNotEmpty) printKeyValue(strings.phone, data.customerPhone),
      printDivider(),
      for (final l in data.lines) ...[
        pw.Text(l.name, style: bold),
        printKeyValue(
          '${printQty(l.quantity)} ${l.unit} x ${printMoney(l.unitPrice)}',
          printMoney(l.amount),
        ),
        pw.Text('${strings.delivery}: ${printDate(l.deliveryDate)}', style: muted),
        pw.SizedBox(height: 3),
      ],
      printDivider(),
      ..._totals(),
      printDivider(),
      pw.Center(child: pw.Text(strings.thankYou, style: muted)),
    ];
  }
}
