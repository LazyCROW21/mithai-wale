import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Where a rendered PDF can go. Kept behind an interface so another channel
/// (e.g. a direct ESC/POS thermal printer) can be added without touching the
/// documents or the preview.
abstract interface class IDocumentOutput {
  /// Opens the system print dialog.
  Future<void> print(Uint8List bytes, {required String name, required PdfPageFormat format});

  /// Shares the PDF (share sheet on mobile, download/save elsewhere).
  Future<void> share(Uint8List bytes, {required String fileName});
}

/// Uses the platform print and share services.
class PrintingDocumentOutput implements IDocumentOutput {
  const PrintingDocumentOutput();

  @override
  Future<void> print(Uint8List bytes, {required String name, required PdfPageFormat format}) =>
      Printing.layoutPdf(onLayout: (_) async => bytes, name: name, format: format);

  @override
  Future<void> share(Uint8List bytes, {required String fileName}) =>
      Printing.sharePdf(bytes: bytes, filename: fileName);
}
