import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/layout_extensions.dart';
import '../orders_providers.dart';
import 'date_selector_dialog.dart';

class OrdersFilterToolbar extends ConsumerWidget {
  const OrdersFilterToolbar({super.key});

  static const _statusOptions = [
    'Placed',
    'Preparing',
    'Ready',
    'Delivering',
    'Delivered',
    'Completed',
    'Cancelled',
    'Returned',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ordersViewModelProvider);
    final vm = ref.read(ordersViewModelProvider.notifier);
    final isMobile = context.isMobile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Row 1: Date Filter (Left) + Search (Right) ──────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: 10,
          ),
          child: isMobile
              ? Column(
                  children: [
                    // Date Navigator on Mobile
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DateNavigator(state: state, vm: vm),
                        // Reset button if not default
                        if (!setEquals(state.selectedStatuses, const {'Preparing', 'Placed', 'Delivering'}))
                          TextButton(
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                            onPressed: vm.resetDefaultStatuses,
                            child: const Text('Reset Statuses', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Search Bar on Mobile
                    SearchBar(
                      hintText: 'Search order item, customer…',
                      leading: const Icon(Icons.search, size: 20),
                      onChanged: vm.setSearchQuery,
                      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Date Navigator: "<" "<calendar icon> Today" ">"
                    _DateNavigator(state: state, vm: vm),
                    const Spacer(),
                    // Search on the right
                    SizedBox(
                      width: 320,
                      child: SearchBar(
                        hintText: 'Search order item, customer…',
                        leading: const Icon(Icons.search, size: 20),
                        onChanged: vm.setSearchQuery,
                        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
                      ),
                    ),
                  ],
                ),
        ),

        // ── Row 2: Status Selection (Multi-Selectable, NO 'All') ─────────────────
        Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._statusOptions.map((status) {
                final count = state.allOrders
                    .where((o) => o.status.toLowerCase() == status.toLowerCase())
                    .length;
                final isSelected = state.selectedStatuses.any(
                  (s) => s.toLowerCase() == status.toLowerCase(),
                );

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Center(
                    child: FilterChip(
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      label: Text('$status ($count)'),
                      selected: isSelected,
                      onSelected: (_) => vm.toggleStatusFilter(status),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        const Divider(height: 1),
      ],
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.state,
    required this.vm,
  });

  final dynamic state;
  final dynamic vm;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Left arrow "<"
        IconButton.outlined(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Icon(Icons.chevron_left, size: 20),
          tooltip: state.isRange ? 'Previous Range' : 'Previous Day',
          onPressed: () => vm.navigateDatePrevious(),
        ),
        const SizedBox(width: 6),

        // Center button: "<calendar icon> Today" / formatted date
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => showOrderDateSelectorDialog(
            context: context,
            initialDate: state.selectedDate,
            initialEndDate: state.selectedEndDate,
            onDateSelected: (start, end) => vm.setDateFilter(start, end),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: cs.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  state.dateTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Right arrow ">"
        IconButton.outlined(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Icon(Icons.chevron_right, size: 20),
          tooltip: state.isRange ? 'Next Range' : 'Next Day',
          onPressed: () => vm.navigateDateNext(),
        ),
      ],
    );
  }
}
