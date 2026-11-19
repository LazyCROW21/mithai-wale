import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;

import 'print_profile.dart';
import 'print_strings.dart';

/// Output layouts every document supports.
enum PrintFormat {
  /// Full page, sized by the shop's [PrintProfile].
  page,

  /// 80 mm receipt roll.
  thermal80,

  /// 58 mm receipt roll.
  thermal58;

  bool get isThermal => this != PrintFormat.page;

  /// Roll width in millimetres (thermal formats only).
  double get rollWidthMm => this == PrintFormat.thermal58 ? 58 : 80;

  static PrintFormat parse(String? v) =>
      PrintFormat.values.firstWhere((f) => f.name == v, orElse: () => PrintFormat.page);
}

/// Who is issuing the document (printed on thermal rolls, and on pages that
/// have no letterhead image).
@immutable
class BusinessInfo {
  const BusinessInfo({required this.name, this.address, this.phone, this.gstin});

  final String name;
  final String? address;
  final String? phone;

  /// Reserved for GST invoices.
  final String? gstin;
}

/// A printable document. Add a new document by adding a subclass; the renderer
/// and preview never need to change.
abstract class PrintDocument {
  const PrintDocument({this.strings = const PrintStrings()});

  /// Wording used on paper (English for now).
  final PrintStrings strings;

  /// Shown in the preview and stored as the PDF title.
  String get title;

  /// Suggested file name, including `.pdf`.
  String get fileName;

  /// Content for a full page; may span several pages.
  List<pw.Widget> buildPage();

  /// Content for a narrow receipt roll, top to bottom.
  List<pw.Widget> buildThermal();
}

/// Everything needed to render one document.
@immutable
class PrintJob {
  const PrintJob({required this.document, required this.business, required this.profile});

  final PrintDocument document;
  final BusinessInfo business;
  final PrintProfile profile;
}
