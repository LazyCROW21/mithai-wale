/// Formats date titles for orders single dates and ranges according to specifications:
/// - Single date: 'Yesterday', 'Today', 'Tomorrow', or 'DD-MM-YYYY'
/// - Range: 'DD - DD, MM, YYYY' (same month/year) or 'DD-MM to DD-MM, YYYY' (same year) or 'DD-MM-YYYY to DD-MM-YYYY' (different year)
String formatOrderDateTitle(DateTime start, [DateTime? end]) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final tomorrow = today.add(const Duration(days: 1));

  final s = DateTime(start.year, start.month, start.day);
  final e = end != null ? DateTime(end.year, end.month, end.day) : null;

  // Single date or start equals end
  if (e == null || (s.year == e.year && s.month == e.month && s.day == e.day)) {
    if (s.year == today.year && s.month == today.month && s.day == today.day) {
      return 'Today';
    }
    if (s.year == yesterday.year && s.month == yesterday.month && s.day == yesterday.day) {
      return 'Yesterday';
    }
    if (s.year == tomorrow.year && s.month == tomorrow.month && s.day == tomorrow.day) {
      return 'Tomorrow';
    }
    final dd = s.day.toString().padLeft(2, '0');
    final mm = s.month.toString().padLeft(2, '0');
    return '$dd-$mm-${s.year}';
  }

  // Range
  final startDate = s.isBefore(e) ? s : e;
  final endDate = s.isBefore(e) ? e : s;

  final d1 = startDate.day.toString().padLeft(2, '0');
  final d2 = endDate.day.toString().padLeft(2, '0');
  final m1 = startDate.month.toString().padLeft(2, '0');
  final m2 = endDate.month.toString().padLeft(2, '0');
  final y1 = startDate.year;
  final y2 = endDate.year;

  // Case 1: Same month and same year: "DD - DD, MM, YYYY"
  if (y1 == y2 && m1 == m2) {
    return '$d1 - $d2, $m1, $y1';
  }

  // Case 2: Different month, same year: "DD-MM to DD-MM, YYYY"
  if (y1 == y2) {
    return '$d1-$m1 to $d2-$m2, $y1';
  }

  // Case 3: Different year: "DD-MM-YYYY to DD-MM-YYYY"
  return '$d1-$m1-$y1 to $d2-$m2-$y2';
}
