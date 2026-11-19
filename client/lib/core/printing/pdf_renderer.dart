import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'print_document.dart';
import 'print_profile.dart';
import 'print_widgets.dart';

/// Turns a [PrintJob] into PDF bytes.
///
/// Owns everything that is the same for every document: fonts, page geometry,
/// the letterhead and the plain-text business header. Documents only supply
/// their content.
class PdfRenderer {
  PdfRenderer({Future<ByteData> Function(String asset)? loadAsset})
      : _loadAsset = loadAsset ?? rootBundle.load;

  final Future<ByteData> Function(String asset) _loadAsset;
  pw.ThemeData? _theme;

  /// Bundled so the rupee sign renders and printing works offline.
  Future<pw.ThemeData> _loadTheme() async => _theme ??= pw.ThemeData.withFont(
        base: pw.Font.ttf(await _loadAsset('assets/fonts/NotoSans-Regular.ttf')),
        bold: pw.Font.ttf(await _loadAsset('assets/fonts/NotoSans-Bold.ttf')),
      );

  /// Page geometry of [profile]: paper size with the printing area as margins.
  static PdfPageFormat pageFormatOf(PrintProfile profile) => PdfPageFormat(
        profile.pageWidthMm * PdfPageFormat.mm,
        profile.pageHeightMm * PdfPageFormat.mm,
        marginTop: profile.marginTopMm * PdfPageFormat.mm,
        marginBottom: profile.marginBottomMm * PdfPageFormat.mm,
        marginLeft: profile.marginLeftMm * PdfPageFormat.mm,
        marginRight: profile.marginRightMm * PdfPageFormat.mm,
      );

  static PdfPageFormat rollFormatOf(PrintFormat format) => PdfPageFormat(
        format.rollWidthMm * PdfPageFormat.mm,
        double.infinity,
        marginAll: 4 * PdfPageFormat.mm,
      );

  /// Renders [job] in [format].
  ///
  /// [includeLetterhead] only affects full pages: when false the top and
  /// bottom margins stay blank for pre-printed paper. Thermal rolls always
  /// start with the plain-text business header.
  Future<Uint8List> render(
    PrintJob job, {
    required PrintFormat format,
    required bool includeLetterhead,
  }) async {
    final theme = await _loadTheme();
    final pdf = pw.Document(title: job.document.title, theme: theme);

    if (format.isThermal) {
      pdf.addPage(
        pw.Page(
          pageFormat: rollFormatOf(format),
          build: (_) => pw.DefaultTextStyle(
            style: const pw.TextStyle(fontSize: 8),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                businessHeader(job.business, job.document.strings, compact: true),
                ...job.document.buildThermal(),
              ],
            ),
          ),
        ),
      );
      return pdf.save();
    }

    final profile = job.profile;
    final header = includeLetterhead && profile.headerImage != null
        ? pw.MemoryImage(profile.headerImage!)
        : null;
    final footer = includeLetterhead && profile.footerImage != null
        ? pw.MemoryImage(profile.footerImage!)
        : null;
    final pageFormat = pageFormatOf(profile);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: pageFormat,
          theme: theme,
          // The letterhead lives in the margins, outside the printing area.
          buildBackground: header == null && footer == null
              ? null
              : (_) => pw.FullPage(
                    ignoreMargins: true,
                    child: pw.Stack(
                      children: [
                        if (header != null)
                          pw.Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: pw.SizedBox(
                              height: pageFormat.marginTop,
                              child: pw.Image(
                                header,
                                fit: pw.BoxFit.contain,
                                alignment: pw.Alignment.topCenter,
                              ),
                            ),
                          ),
                        if (footer != null)
                          pw.Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: pw.SizedBox(
                              height: pageFormat.marginBottom,
                              child: pw.Image(
                                footer,
                                fit: pw.BoxFit.contain,
                                alignment: pw.Alignment.bottomCenter,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
        ),
        build: (_) => [
          // No header image uploaded: fall back to a plain-text header.
          if (includeLetterhead && header == null)
            businessHeader(job.business, job.document.strings),
          ...job.document.buildPage(),
        ],
      ),
    );
    return pdf.save();
  }
}
