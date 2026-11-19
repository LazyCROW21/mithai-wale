import 'dart:convert';

import 'package:flutter/foundation.dart';

const Object _undefined = Object();

/// Paper sizes offered in print setup (dimensions in millimetres).
enum PrintPageSize {
  a4('A4', 210, 297),
  a5('A5', 148, 210),
  letter('Letter', 215.9, 279.4),
  custom('', 210, 297);

  const PrintPageSize(this.label, this.widthMm, this.heightMm);

  /// Standard paper name; empty for [custom] (the UI supplies a localized label).
  final String label;
  final double widthMm;
  final double heightMm;

  static PrintPageSize parse(String? v) =>
      PrintPageSize.values.firstWhere((s) => s.name == v, orElse: () => PrintPageSize.a4);
}

/// Page setup and letterhead for full-page documents.
///
/// The margins define the **printing area**: document content never prints
/// outside it. The letterhead images are drawn in the top and bottom margins,
/// so the layout is identical whether the letterhead is included (sharing a
/// PDF) or excluded (printing on pre-printed paper).
@immutable
class PrintProfile {
  const PrintProfile({
    this.pageSize = PrintPageSize.a4,
    this.pageWidthMm = 210,
    this.pageHeightMm = 297,
    this.marginTopMm = 15,
    this.marginBottomMm = 15,
    this.marginLeftMm = 15,
    this.marginRightMm = 15,
    this.headerImage,
    this.footerImage,
  });

  /// Built-in fallback: A4 with 15 mm margins and no letterhead.
  static const standard = PrintProfile();

  final PrintPageSize pageSize;
  final double pageWidthMm;
  final double pageHeightMm;
  final double marginTopMm;
  final double marginBottomMm;
  final double marginLeftMm;
  final double marginRightMm;

  /// Drawn in the top margin when the letterhead is included.
  final Uint8List? headerImage;

  /// Drawn in the bottom margin when the letterhead is included.
  final Uint8List? footerImage;

  bool get hasLetterhead => headerImage != null || footerImage != null;

  factory PrintProfile.fromJson(Map<String, dynamic> j) {
    double n(String key, double fallback) => (j[key] as num?)?.toDouble() ?? fallback;
    Uint8List? image(String key) {
      final v = j[key];
      if (v is! String || v.isEmpty) return null;
      try {
        return base64Decode(v);
      } catch (_) {
        return null;
      }
    }

    return PrintProfile(
      pageSize: PrintPageSize.parse(j['pageSize'] as String?),
      pageWidthMm: n('pageWidthMm', 210),
      pageHeightMm: n('pageHeightMm', 297),
      marginTopMm: n('marginTopMm', 15),
      marginBottomMm: n('marginBottomMm', 15),
      marginLeftMm: n('marginLeftMm', 15),
      marginRightMm: n('marginRightMm', 15),
      headerImage: image('headerImage'),
      footerImage: image('footerImage'),
    );
  }

  Map<String, dynamic> toJson() => {
        'pageSize': pageSize.name,
        'pageWidthMm': pageWidthMm,
        'pageHeightMm': pageHeightMm,
        'marginTopMm': marginTopMm,
        'marginBottomMm': marginBottomMm,
        'marginLeftMm': marginLeftMm,
        'marginRightMm': marginRightMm,
        'headerImage': headerImage == null ? null : base64Encode(headerImage!),
        'footerImage': footerImage == null ? null : base64Encode(footerImage!),
      };

  PrintProfile copyWith({
    PrintPageSize? pageSize,
    double? pageWidthMm,
    double? pageHeightMm,
    double? marginTopMm,
    double? marginBottomMm,
    double? marginLeftMm,
    double? marginRightMm,
    Object? headerImage = _undefined,
    Object? footerImage = _undefined,
  }) {
    return PrintProfile(
      pageSize: pageSize ?? this.pageSize,
      pageWidthMm: pageWidthMm ?? this.pageWidthMm,
      pageHeightMm: pageHeightMm ?? this.pageHeightMm,
      marginTopMm: marginTopMm ?? this.marginTopMm,
      marginBottomMm: marginBottomMm ?? this.marginBottomMm,
      marginLeftMm: marginLeftMm ?? this.marginLeftMm,
      marginRightMm: marginRightMm ?? this.marginRightMm,
      headerImage: headerImage == _undefined ? this.headerImage : headerImage as Uint8List?,
      footerImage: footerImage == _undefined ? this.footerImage : footerImage as Uint8List?,
    );
  }
}

/// The franchise default plus each shop's own setup.
@immutable
class PrintProfileSet {
  const PrintProfileSet({this.franchise, this.shops = const {}});

  final PrintProfile? franchise;

  /// Shop id → that shop's own setup (shops without one are absent).
  final Map<String, PrintProfile> shops;

  /// Shop's own setup → franchise default → built-in A4.
  PrintProfile resolve(String? shopId) =>
      (shopId == null ? null : shops[shopId]) ?? franchise ?? PrintProfile.standard;

  factory PrintProfileSet.fromJson(Map<String, dynamic> j) => PrintProfileSet(
        franchise: j['franchise'] is Map
            ? PrintProfile.fromJson((j['franchise'] as Map).cast<String, dynamic>())
            : null,
        shops: {
          for (final e in ((j['shops'] as Map?) ?? const {}).entries)
            if (e.value is Map)
              e.key as String: PrintProfile.fromJson((e.value as Map).cast<String, dynamic>()),
        },
      );
}
