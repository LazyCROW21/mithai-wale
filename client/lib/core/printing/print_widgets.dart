/// Building blocks shared by every printed document.
library;

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'print_document.dart';
import 'print_strings.dart';

final _money = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 2);
final _date = DateFormat('dd MMM yyyy');
final _dateTime = DateFormat('dd MMM yyyy, hh:mm a');

String printMoney(num value) => _money.format(value);
String printDate(DateTime d) => _date.format(d);
String printDateTime(DateTime d) => _dateTime.format(d);

/// 2.0 → "2", 2.5 → "2.5".
String printQty(num value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');

const printMuted = PdfColors.grey700;
const printRule = PdfColors.grey500;

/// Plain-text business header: thermal rolls, and pages without a header image.
pw.Widget businessHeader(BusinessInfo b, PrintStrings s, {bool compact = false}) {
  final small = pw.TextStyle(fontSize: compact ? 7.5 : 9.5, color: printMuted);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Text(
        b.name,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: compact ? 12 : 20, fontWeight: pw.FontWeight.bold),
      ),
      if ((b.address ?? '').isNotEmpty) pw.Text(b.address!, textAlign: pw.TextAlign.center, style: small),
      if ((b.phone ?? '').isNotEmpty) pw.Text('${s.phone}: ${b.phone}', style: small),
      if ((b.gstin ?? '').isNotEmpty) pw.Text('${s.gstin}: ${b.gstin}', style: small),
      pw.SizedBox(height: compact ? 4 : 10),
      pw.Divider(height: 1, thickness: 0.6, color: printRule),
      pw.SizedBox(height: compact ? 4 : 12),
    ],
  );
}

/// "Label ........ value" on one line.
pw.Widget printKeyValue(String label, String value, {bool bold = false, double? fontSize}) {
  final style = pw.TextStyle(
    fontSize: fontSize,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
  );
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: pw.Text(label, style: style)),
        pw.SizedBox(width: 8),
        pw.Text(value, style: style),
      ],
    ),
  );
}

pw.Widget printDivider({double space = 4}) => pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: space),
      child: pw.Divider(height: 1, thickness: 0.6, color: printRule),
    );
