import 'package:flutter/material.dart';

/// Formats numbers cleanly (e.g. 2.0 -> '2', 2.4 -> '2.4', 50.0 -> '50').
String formatNumber(num value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  // Limit to 2 decimal places and strip trailing zeros
  return value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
}

/// Normalized unit representation (e.g. 'kg', 'pc', 'gm', 'litre').
String normalizedUnit(String unit) {
  final lower = unit.trim().toLowerCase();
  if (lower == 'per piece' || lower == 'piece' || lower == 'pcs') {
    return 'pc';
  }
  return lower;
}

/// Quantity step for a unit: half steps for weight/volume, whole for pieces.
double quantityStepFor(String unit) {
  final u = normalizedUnit(unit);
  return (u == 'kg' || u == 'litre') ? 0.5 : 1.0;
}

/// Returns a curated, harmonious shade of the primary color for a given [date].
/// Items sharing the same delivery date receive the exact same color shade.
Color deliveryDateColor(
  DateTime date,
  ColorScheme cs, [
  List<DateTime>? sortedUniqueDates,
]) {
  final baseHsl = HSLColor.fromColor(cs.primary);

  int index = 0;
  if (sortedUniqueDates != null && sortedUniqueDates.isNotEmpty) {
    final normalized = DateTime(date.year, date.month, date.day);
    index = sortedUniqueDates.indexWhere(
      (d) => d.year == normalized.year && d.month == normalized.month && d.day == normalized.day,
    );
    if (index < 0) index = 0;
  } else {
    index = (date.year * 372 + date.month * 31 + date.day) % 5;
  }

  // Curated shades rooted in primary warm saffron:
  switch (index % 5) {
    case 0:
      return cs.primary;
    case 1:
      return baseHsl
          .withHue((baseHsl.hue - 12.0 + 360.0) % 360.0)
          .withLightness((baseHsl.lightness * 0.88).clamp(0.25, 0.75))
          .toColor();
    case 2:
      return baseHsl
          .withHue((baseHsl.hue + 14.0) % 360.0)
          .withLightness((baseHsl.lightness * 1.08).clamp(0.25, 0.75))
          .toColor();
    case 3:
      return baseHsl
          .withHue((baseHsl.hue - 24.0 + 360.0) % 360.0)
          .withSaturation((baseHsl.saturation * 0.95).clamp(0.3, 1.0))
          .toColor();
    case 4:
    default:
      return baseHsl
          .withHue((baseHsl.hue + 26.0) % 360.0)
          .withSaturation((baseHsl.saturation * 0.9).clamp(0.3, 1.0))
          .toColor();
  }
}
