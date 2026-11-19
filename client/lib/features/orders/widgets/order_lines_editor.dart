import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/database/models/order_model.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/l10n.dart';

// ── Status helpers ───────────────────────────────────────────────────────────

/// Localized label for a stored (English) order status.
String orderStatusLabel(AppLocalizations l10n, String status) => switch (status.toLowerCase().trim()) {
      'placed' => l10n.statusPlaced,
      'preparing' => l10n.statusPreparing,
      'ready' => l10n.statusReady,
      'delivering' => l10n.statusDelivering,
      'delivered' => l10n.statusDelivered,
      'completed' => l10n.statusCompleted,
      'cancelled' => l10n.statusCancelled,
      'returned' => l10n.statusReturned,
      _ => status,
    };

Color orderStatusColor(ColorScheme cs, String status) => switch (status.toLowerCase().trim()) {
      'placed' => Colors.blue,
      'preparing' => Colors.orange,
      'ready' => Colors.purple,
      'delivering' => Colors.cyan,
      'delivered' => Colors.green,
      'completed' => Colors.teal,
      'cancelled' => cs.error,
      'returned' => Colors.deepOrange,
      _ => cs.secondary,
    };

/// Readable day label: "Today", "Tomorrow" (Material localizations) or a date.
String formatDeliveryDay(BuildContext context, DateTime day) {
  final ml = MaterialLocalizations.of(context);
  return ml.formatMediumDate(day);
}

/// Status pill. With [onChanged] it is a button (elevated) opening a menu of
/// statuses; without, a plain badge.
class DeliveryStatusChip extends StatelessWidget {
  const DeliveryStatusChip({super.key, required this.status, this.onChanged, this.dense = false});

  final String status;
  final ValueChanged<String>? onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final color = orderStatusColor(cs, status);
    final pill = Material(
      elevation: onChanged == null ? 0 : 1.5,
      shadowColor: Colors.black26,
      color: Color.alphaBlend(color.withValues(alpha: 0.15), cs.surface),
      shape: StadiumBorder(side: BorderSide(color: color.withValues(alpha: 0.5))),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 2 : 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              orderStatusLabel(l10n, status),
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: dense ? 11 : 12),
            ),
            if (onChanged != null) Icon(Icons.arrow_drop_down, size: 16, color: color),
          ],
        ),
      ),
    );
    if (onChanged == null) return pill;
    return PopupMenuButton<String>(
      tooltip: l10n.orderDeliveryStatus,
      initialValue: status,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final s in OrderStatus.all)
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: orderStatusColor(cs, s)),
                const SizedBox(width: 10),
                Text(orderStatusLabel(l10n, s)),
              ],
            ),
          ),
      ],
      child: pill,
    );
  }
}

/// Dialog to type an exact quantity; returns null when cancelled.
Future<double?> showQuantityDialog(
  BuildContext context, {
  required String title,
  required String unit,
  required double initial,
}) async {
  final l10n = context.l10n;
  final ctrl = TextEditingController(text: initial > 0 ? formatNumber(initial) : '');
  final result = await showDialog<double>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('${l10n.orderSetQuantity}: $title'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        decoration: InputDecoration(labelText: l10n.orderQuantity, suffixText: normalizedUnit(unit)),
        onSubmitted: (v) => Navigator.pop(ctx, double.tryParse(v)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.actionCancel)),
        FilledButton(
          style: FilledButton.styleFrom(elevation: 2),
          onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text)),
          child: Text(l10n.actionSave),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return result;
}

Future<DateTime?> pickDeliveryDay(BuildContext context, DateTime initial) async {
  final now = DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 2),
  );
  return picked == null ? null : dayOf(picked);
}

// ── Editor ───────────────────────────────────────────────────────────────────

/// Order rows grouped by delivery day (sorted by day, then item name).
///
/// * The same item may be listed more than once. Rows for the same item on the
///   same day sit next to each other and get a "Duplicate" marker on the left
///   with a button to merge them into one row.
/// * Every row has its actions inline: change date, quantity stepper, remove.
/// * With [showStatus], each day's header has a status button (one status per
///   delivery day).
///
/// [lines] must be sorted with [OrderModel.sortLines]; [onChanged] receives the
/// new rows, re-sorted.
class OrderLinesEditor extends StatelessWidget {
  const OrderLinesEditor({
    super.key,
    required this.lines,
    required this.onChanged,
    this.showStatus = false,
  });

  final List<OrderItemDetail> lines;
  final ValueChanged<List<OrderItemDetail>> onChanged;
  final bool showStatus;

  void _emit(List<OrderItemDetail> next) => onChanged(OrderModel.sortLines(next));

  void _setQty(int index, double q) {
    if (q <= 0) return _remove(index);
    _emit([for (final (i, l) in lines.indexed) i == index ? l.copyWith(quantity: q) : l]);
  }

  void _remove(int index) => _emit([for (final (i, l) in lines.indexed) if (i != index) l]);

  void _moveTo(int index, DateTime day) {
    final line = lines[index];
    if (line.isSameDeliveryDay(day)) return;
    final rest = [for (final (i, l) in lines.indexed) if (i != index) l];
    // addLine adopts the target day's status (a new day starts as Placed).
    _emit(OrderModel.addLine(rest, line.copyWith(deliveryDate: day, status: OrderStatus.placed)));
  }

  void _merge(String lineKey) => _emit(OrderModel.mergeDuplicates(lines, lineKey));

  void _setDayStatus(DateTime day, String status) {
    _emit([for (final l in lines) l.isSameDeliveryDay(day) ? l.copyWith(status: status) : l]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (lines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Text(l10n.orderNoLinesYet, textAlign: TextAlign.center, style: TextStyle(color: cs.outline)),
      );
    }

    // day → runs of rows sharing a lineKey (a run longer than 1 = duplicates).
    final days = <DateTime, List<List<int>>>{};
    for (final (i, line) in lines.indexed) {
      final runs = days.putIfAbsent(dayOf(line.deliveryDate), () => []);
      if (runs.isNotEmpty && lines[runs.last.last].lineKey == line.lineKey) {
        runs.last.add(i);
      } else {
        runs.add([i]);
      }
    }
    final dayList = days.keys.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Narrow: each row wraps onto two lines instead of hiding actions.
        final compact = constraints.maxWidth < 520;

        Widget row(int i) => _LineRow(
              line: lines[i],
              compact: compact,
              onQty: (q) => _setQty(i, q),
              onMove: (d) => _moveTo(i, d),
              onRemove: () => _remove(i),
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final day in dayList)
              Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 10),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: deliveryDateColor(day, cs, dayList).withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DayHeader(
                      day: day,
                      accent: deliveryDateColor(day, cs, dayList),
                      count: days[day]!.fold(0, (n, r) => n + r.length),
                      status: showStatus ? lines[days[day]!.first.first].status : null,
                      onStatus: (s) => _setDayStatus(day, s),
                    ),
                    for (final (r, run) in days[day]!.indexed) ...[
                      if (r > 0) const Divider(height: 1),
                      if (run.length == 1)
                        row(run.first)
                      else
                        _DuplicateRun(
                          onMerge: () => _merge(lines[run.first].lineKey),
                          children: [for (final i in run) row(i)],
                        ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.day,
    required this.accent,
    required this.count,
    required this.status,
    required this.onStatus,
  });

  final DateTime day;
  final Color accent;
  final int count;

  /// Null hides the status button (new orders always start as Placed).
  final String? status;
  final ValueChanged<String> onStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      color: accent.withValues(alpha: 0.1),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Icon(Icons.event_outlined, size: 16, color: accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n.orderDeliveryOn(formatDeliveryDay(context, day)),
              style: TextStyle(fontWeight: FontWeight.bold, color: accent),
            ),
          ),
          Text(
            l10n.orderLineCount(count),
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (status != null) ...[
            const SizedBox(width: 8),
            DeliveryStatusChip(status: status!, onChanged: onStatus),
          ],
        ],
      ),
    );
  }
}

/// Rows for the same item on the same day: a "Duplicate" marker on the left
/// with a merge button, the rows on the right.
class _DuplicateRun extends StatelessWidget {
  const _DuplicateRun({required this.onMerge, required this.children});

  final VoidCallback onMerge;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final warn = cs.tertiary;
    return Container(
      color: warn.withValues(alpha: 0.08),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 72,
              decoration: BoxDecoration(
                color: warn.withValues(alpha: 0.14),
                border: Border(right: BorderSide(color: warn.withValues(alpha: 0.5), width: 2)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.copy_all_outlined, size: 18, color: warn),
                  const SizedBox(height: 2),
                  Text(
                    l10n.orderDuplicate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: warn),
                  ),
                  const SizedBox(height: 4),
                  IconButton.filledTonal(
                    tooltip: l10n.orderMergeDuplicates,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(elevation: 2, shadowColor: Colors.black38),
                    icon: const Icon(Icons.call_merge, size: 20),
                    onPressed: onMerge,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final (i, c) in children.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    c,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One order row with inline actions (no overflow menu):
/// name + price · [date] · [− qty +] · [remove].
class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.line,
    required this.compact,
    required this.onQty,
    required this.onMove,
    required this.onRemove,
  });

  final OrderItemDetail line;
  final bool compact;
  final ValueChanged<double> onQty;
  final ValueChanged<DateTime> onMove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final unit = normalizedUnit(line.unit);
    final step = quantityStepFor(line.unit);

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(line.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(
          '₹${formatNumber(line.unitPrice)}/$unit · ₹${formatNumber(line.totalPrice)}',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
    );

    final date = Tooltip(
      message: l10n.orderChangeDate,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          elevation: 1,
          shadowColor: Colors.black26,
          backgroundColor: cs.surface,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: () async {
          final d = await pickDeliveryDay(context, line.deliveryDate);
          if (d != null) onMove(d);
        },
        icon: const Icon(Icons.edit_calendar_outlined, size: 16),
        label: Text(MaterialLocalizations.of(context).formatShortMonthDay(line.deliveryDate)),
      ),
    );

    final stepper = QuantityStepper(
      quantity: line.quantity,
      unit: unit,
      // The remove button deletes a row; the stepper stops at one step.
      onMinus: line.quantity > step ? () => onQty(line.quantity - step) : null,
      onPlus: () => onQty(line.quantity + step),
      onEdit: () async {
        final q = await showQuantityDialog(context, title: line.name, unit: line.unit, initial: line.quantity);
        if (q != null) onQty(q);
      },
    );

    final remove = IconButton.filledTonal(
      tooltip: l10n.orderRemoveItem,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        elevation: 1,
        shadowColor: Colors.black26,
        backgroundColor: cs.errorContainer,
        foregroundColor: cs.onErrorContainer,
      ),
      icon: const Icon(Icons.delete_outline, size: 20),
      onPressed: onRemove,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [Expanded(child: info), remove]),
                const SizedBox(height: 6),
                Row(children: [date, const Spacer(), stepper]),
              ],
            )
          : Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: 8),
                date,
                const SizedBox(width: 8),
                stepper,
                const SizedBox(width: 8),
                remove,
              ],
            ),
    );
  }
}

/// "− 2 kg +" control; tapping the quantity opens [onEdit]. A null [onMinus]
/// disables the minus button.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.unit,
    required this.onMinus,
    required this.onPlus,
    required this.onEdit,
  });

  final double quantity;
  final String unit;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      elevation: 1,
      color: cs.primaryContainer,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove, size: 18),
            color: cs.onPrimaryContainer,
            onPressed: onMinus,
          ),
          InkWell(
            onTap: onEdit,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                child: Text(
                  '${formatNumber(quantity)} $unit',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
                ),
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, size: 18),
            color: cs.onPrimaryContainer,
            onPressed: onPlus,
          ),
        ],
      ),
    );
  }
}
