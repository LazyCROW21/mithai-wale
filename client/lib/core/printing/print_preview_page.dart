import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../l10n/l10n.dart';
import '../database/repositories/settings_repository.dart';
import '../di/service_locator.dart';
import 'document_output.dart';
import 'pdf_renderer.dart';
import 'print_document.dart';

/// Opens the preview for [job]: view the PDF, then print, share or download it.
Future<void> showPrintPreview(BuildContext context, PrintJob job) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => PrintPreviewPage(job: job)),
  );
}

/// Shared preview for every [PrintDocument].
///
/// The user picks the layout (page or thermal roll) and whether to include the
/// letterhead; both choices are remembered on this device.
class PrintPreviewPage extends StatefulWidget {
  const PrintPreviewPage({super.key, required this.job});

  final PrintJob job;

  @override
  State<PrintPreviewPage> createState() => _PrintPreviewPageState();
}

class _PrintPreviewPageState extends State<PrintPreviewPage> {
  static const _formatKey = 'print_format';
  static const _letterheadKey = 'print_include_letterhead';

  final _settings = sl<ISettingsRepository>();
  final _renderer = sl<PdfRenderer>();
  final _output = sl<IDocumentOutput>();

  PrintFormat _format = PrintFormat.page;
  bool _letterhead = true;
  bool _ready = false;
  Future<Uint8List>? _bytes;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final format = await _settings.get(_formatKey);
    final letterhead = await _settings.get(_letterheadKey);
    if (!mounted) return;
    setState(() {
      _format = PrintFormat.parse(format);
      _letterhead = letterhead != 'false';
      _ready = true;
      _render();
    });
  }

  void _render() {
    _bytes = _renderer.render(widget.job, format: _format, includeLetterhead: _letterhead);
  }

  void _setFormat(PrintFormat f) {
    setState(() {
      _format = f;
      _render();
    });
    _settings.set(_formatKey, f.name);
  }

  void _setLetterhead(bool v) {
    setState(() {
      _letterhead = v;
      _render();
    });
    _settings.set(_letterheadKey, '$v');
  }

  Future<void> _run(Future<void> Function(Uint8List bytes) action) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action(await _bytes!);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.printFailed)));
    }
  }

  Future<void> _print() => _run(
        (bytes) => _output.print(
          bytes,
          name: widget.job.document.title,
          format: _format.isThermal
              ? PdfRenderer.rollFormatOf(_format)
              : PdfRenderer.pageFormatOf(widget.job.profile),
        ),
      );

  Future<void> _share() =>
      _run((bytes) => _output.share(bytes, fileName: widget.job.document.fileName));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.printPreviewTitle)),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Material(
                  color: cs.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SegmentedButton<PrintFormat>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(value: PrintFormat.page, label: Text(l10n.printFormatPage)),
                            ButtonSegment(
                              value: PrintFormat.thermal80,
                              label: Text(l10n.printFormatThermal80),
                            ),
                            ButtonSegment(
                              value: PrintFormat.thermal58,
                              label: Text(l10n.printFormatThermal58),
                            ),
                          ],
                          selected: {_format},
                          onSelectionChanged: (s) => _setFormat(s.first),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.printLetterhead),
                            const SizedBox(width: 8),
                            Switch(
                              value: _letterhead && !_format.isThermal,
                              // Rolls never carry the letterhead image.
                              onChanged: _format.isThermal ? null : _setLetterhead,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: PdfPreview(
                    key: ValueKey('${_format.name}-$_letterhead'),
                    build: (_) => _bytes!,
                    useActions: false,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    maxPageWidth: _format.isThermal ? 360 : 800,
                    pdfFileName: widget.job.document.fileName,
                    onError: (context, _) => Center(child: Text(l10n.printFailed)),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _share,
                            icon: const Icon(Icons.download_outlined),
                            label: Text(l10n.printShareDownload),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _print,
                            icon: const Icon(Icons.print_outlined),
                            label: Text(l10n.actionPrint),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
