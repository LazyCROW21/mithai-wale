import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/di/service_locator.dart';
import '../../core/printing/print_preview_page.dart';
import '../../core/printing/print_profile.dart';
import '../../core/printing/print_profile_repository.dart';
import '../../core/utils/image_utils.dart';
import '../../core/widgets/admin_scaffold.dart';
import '../../l10n/l10n.dart';
import '../orders/printing/order_print_service.dart';

/// Edits a print setup: page size, printing area and letterhead images.
///
/// With [shopId] it edits that shop's own setup, otherwise the franchise
/// default. Pops `true` when something was saved.
class PrintSetupPage extends StatefulWidget {
  const PrintSetupPage({
    super.key,
    this.shopId,
    this.shopName,
    required this.own,
    required this.inherited,
  });

  final String? shopId;
  final String? shopName;

  /// The setup currently saved for this shop/franchise, if any.
  final PrintProfile? own;

  /// What applies while there is no own setup (shown as the starting point).
  final PrintProfile inherited;

  @override
  State<PrintSetupPage> createState() => _PrintSetupPageState();
}

class _PrintSetupPageState extends State<PrintSetupPage> {
  /// Server limit is ~500 KB per image.
  static const _maxImageBytes = 500 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _repo = sl<IPrintProfileRepository>();

  late PrintPageSize _size;
  late final TextEditingController _width, _height, _top, _bottom, _left, _right;
  Uint8List? _header;
  Uint8List? _footer;
  bool _busy = false;

  bool get _isShop => widget.shopId != null;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  void initState() {
    super.initState();
    final p = widget.own ?? widget.inherited;
    _size = p.pageSize;
    _width = TextEditingController(text: _fmt(p.pageWidthMm));
    _height = TextEditingController(text: _fmt(p.pageHeightMm));
    _top = TextEditingController(text: _fmt(p.marginTopMm));
    _bottom = TextEditingController(text: _fmt(p.marginBottomMm));
    _left = TextEditingController(text: _fmt(p.marginLeftMm));
    _right = TextEditingController(text: _fmt(p.marginRightMm));
    _header = p.headerImage;
    _footer = p.footerImage;
  }

  @override
  void dispose() {
    for (final c in [_width, _height, _top, _bottom, _left, _right]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  double get _pageWidth => _size == PrintPageSize.custom ? _num(_width) : _size.widthMm;
  double get _pageHeight => _size == PrintPageSize.custom ? _num(_height) : _size.heightMm;

  PrintProfile get _profile => PrintProfile(
        pageSize: _size,
        pageWidthMm: _pageWidth,
        pageHeightMm: _pageHeight,
        marginTopMm: _num(_top),
        marginBottomMm: _num(_bottom),
        marginLeftMm: _num(_left),
        marginRightMm: _num(_right),
        headerImage: _header,
        footerImage: _footer,
      );

  /// Checks the numbers, including that the margins leave room to print.
  bool _validate() {
    if (!_formKey.currentState!.validate()) return false;
    final p = _profile;
    final fits = p.marginTopMm + p.marginBottomMm < p.pageHeightMm - 20 &&
        p.marginLeftMm + p.marginRightMm < p.pageWidthMm - 20;
    if (!fits) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.printAreaTooSmall)));
    }
    return fits;
  }

  Future<void> _pickImage({required bool header}) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final bytes = await ImageUtils.pickAndCompressImage(
      maxDimension: 1800,
      quality: 82,
      whiteBackground: true,
    );
    if (bytes == null || !mounted) return;
    if (bytes.length > _maxImageBytes) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.printImageTooLarge)));
      return;
    }

    // The image is drawn across the full page width inside the margin, so
    // grow that margin until the whole image fits.
    final image = await decodeImageFromList(bytes);
    final neededMm = (_pageWidth * image.height / image.width).ceilToDouble();
    image.dispose();
    if (!mounted) return;
    setState(() {
      final margin = header ? _top : _bottom;
      if (_num(margin) < neededMm) margin.text = _fmt(neededMm);
      if (header) {
        _header = bytes;
      } else {
        _footer = bytes;
      }
    });
  }

  Future<void> _save(PrintProfile? profile) async {
    setState(() => _busy = true);
    try {
      if (_isShop) {
        await _repo.saveShop(widget.shopId!, profile);
      } else {
        await _repo.saveFranchise(profile);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.printSetupSaved)));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  void _preview() {
    if (!_validate()) return;
    showPrintPreview(
      context,
      sl<OrderPrintService>().sampleBill(_profile, shopId: widget.shopId),
    );
  }

  Widget _mmField(TextEditingController c, String label, {double min = 0}) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'mm',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: (v) {
        final n = double.tryParse((v ?? '').trim());
        return n == null || n < min || n > 2000 ? context.l10n.printInvalidNumber : null;
      },
    );
  }

  Widget _pair(Widget a, Widget b) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
        ),
      );

  Widget _imageCard(String title, Uint8List? bytes, {required bool header}) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Container(
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bytes == null ? cs.surfaceContainerHighest : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: bytes == null
                  ? Icon(Icons.image_outlined, color: cs.outline, size: 32)
                  : Image.memory(bytes, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : () => _pickImage(header: header),
                  icon: const Icon(Icons.upload_outlined, size: 18),
                  label: Text(l10n.printImageChoose),
                ),
                if (bytes != null)
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => setState(() => header ? _header = null : _footer = null),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(l10n.printImageRemove),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline);
    final custom = _size == PrintPageSize.custom;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.printSetup),
            Text(
              _isShop ? (widget.shopName ?? '') : l10n.printSetupFranchise,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (_isShop && widget.own == null) ...[
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: theme.colorScheme.outline),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l10n.printUsesFranchiseDefault, style: muted)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Page size ──────────────────────────────────────────
                Text(l10n.printPageSize, style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                DropdownButtonFormField<PrintPageSize>(
                  initialValue: _size,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  items: [
                    for (final s in PrintPageSize.values)
                      DropdownMenuItem(
                        value: s,
                        child: Text(
                          s == PrintPageSize.custom
                              ? l10n.printPageCustom
                              : '${s.label} (${_fmt(s.widthMm)} × ${_fmt(s.heightMm)} mm)',
                        ),
                      ),
                  ],
                  onChanged: (s) => setState(() => _size = s ?? _size),
                ),
                if (custom)
                  _pair(
                    _mmField(_width, l10n.printPageWidth, min: 40),
                    _mmField(_height, l10n.printPageHeight, min: 40),
                  ),

                // ── Printing area ──────────────────────────────────────
                const SizedBox(height: 24),
                Text(l10n.printArea, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(l10n.printAreaHint, style: muted),
                _pair(_mmField(_top, l10n.printMarginTop), _mmField(_bottom, l10n.printMarginBottom)),
                _pair(_mmField(_left, l10n.printMarginLeft), _mmField(_right, l10n.printMarginRight)),

                // ── Letterhead ─────────────────────────────────────────
                const SizedBox(height: 24),
                Text(l10n.printLetterhead, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(l10n.printLetterheadHint, style: muted),
                _imageCard(l10n.printHeaderImage, _header, header: true),
                _imageCard(l10n.printFooterImage, _footer, header: false),

                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  children: [
                    if (_isShop && widget.own != null)
                      OutlinedButton.icon(
                        onPressed: _busy ? null : () => _save(null),
                        icon: const Icon(Icons.restore, size: 18),
                        label: Text(l10n.printUseFranchiseDefault),
                      ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _preview,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: Text(l10n.printPreviewSample),
                    ),
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () {
                              if (_validate()) _save(_profile);
                            },
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: Text(l10n.actionSave),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
