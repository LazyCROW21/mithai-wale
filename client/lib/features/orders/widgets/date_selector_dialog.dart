import 'package:flutter/material.dart';
import '../utils/order_date_formatter.dart';

/// Shows a responsive date selector dialog with option to pick a single date or a date range.
Future<void> showOrderDateSelectorDialog({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? initialEndDate,
  required void Function(DateTime start, DateTime? end) onDateSelected,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => _DateSelectorDialog(
      initialDate: initialDate,
      initialEndDate: initialEndDate,
      onDateSelected: onDateSelected,
    ),
  );
}

class _DateSelectorDialog extends StatefulWidget {
  const _DateSelectorDialog({
    required this.initialDate,
    this.initialEndDate,
    required this.onDateSelected,
  });

  final DateTime initialDate;
  final DateTime? initialEndDate;
  final void Function(DateTime start, DateTime? end) onDateSelected;

  @override
  State<_DateSelectorDialog> createState() => _DateSelectorDialogState();
}

class _DateSelectorDialogState extends State<_DateSelectorDialog> {
  late bool _isRange;
  late DateTime _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day);
    if (widget.initialEndDate != null) {
      _endDate = DateTime(widget.initialEndDate!.year, widget.initialEndDate!.month, widget.initialEndDate!.day);
      _isRange = _startDate != _endDate;
    } else {
      _endDate = null;
      _isRange = false;
    }
  }

  void _applyToday() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = null;
      _isRange = false;
    });
  }

  void _applyYesterday() {
    final now = DateTime.now();
    final y = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    setState(() {
      _startDate = y;
      _endDate = null;
      _isRange = false;
    });
  }

  void _applyTomorrow() {
    final now = DateTime.now();
    final t = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    setState(() {
      _startDate = t;
      _endDate = null;
      _isRange = false;
    });
  }

  void _applyThisWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = today.weekday; // 1 = Monday
    final start = today.subtract(Duration(days: weekday - 1));
    final end = start.add(const Duration(days: 6));
    setState(() {
      _startDate = start;
      _endDate = end;
      _isRange = true;
    });
  }

  void _applyLast7Days() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));
    setState(() {
      _startDate = start;
      _endDate = today;
      _isRange = true;
    });
  }

  void _applyThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final nextMonth = now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
    final end = nextMonth.subtract(const Duration(days: 1));
    setState(() {
      _startDate = start;
      _endDate = end;
      _isRange = true;
    });
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate ?? _startDate.add(const Duration(days: 6)),
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _isRange = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentTitle = formatOrderDateTitle(_startDate, _isRange ? _endDate : null);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Date Filter',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Mode toggle: Single Date vs Date Range
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Single Date'),
                    icon: Icon(Icons.today_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Date Range'),
                    icon: Icon(Icons.date_range_outlined, size: 18),
                  ),
                ],
                selected: {_isRange},
                onSelectionChanged: (val) {
                  setState(() {
                    _isRange = val.first;
                    if (!_isRange) {
                      _endDate = null;
                    } else {
                      _endDate ??= _startDate.add(const Duration(days: 6));
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Selected Preview
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, size: 20, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        currentTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (!_isRange) ...[
                // Quick chips for single date
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Yesterday'),
                      onPressed: _applyYesterday,
                    ),
                    ActionChip(
                      label: const Text('Today'),
                      onPressed: _applyToday,
                    ),
                    ActionChip(
                      label: const Text('Tomorrow'),
                      onPressed: _applyTomorrow,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Calendar date picker
                SizedBox(
                  height: 280,
                  child: CalendarDatePicker(
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                    onDateChanged: (val) {
                      setState(() {
                        _startDate = DateTime(val.year, val.month, val.day);
                        _endDate = null;
                      });
                    },
                  ),
                ),
              ] else ...[
                // Quick chips for range
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Last 7 Days'),
                      onPressed: _applyLast7Days,
                    ),
                    ActionChip(
                      label: const Text('This Week'),
                      onPressed: _applyThisWeek,
                    ),
                    ActionChip(
                      label: const Text('This Month'),
                      onPressed: _applyThisMonth,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Custom Range Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _pickCustomRange,
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Pick Custom Date Range on Calendar'),
                ),
                const SizedBox(height: 16),
              ],

              const Divider(),
              const SizedBox(height: 8),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      widget.onDateSelected(_startDate, _isRange ? _endDate : null);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Apply Filter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
