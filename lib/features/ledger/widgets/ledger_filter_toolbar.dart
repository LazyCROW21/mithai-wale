import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/models/payment_model.dart';
import '../ledger_providers.dart';
import 'record_payment_dialog.dart';

class LedgerFilterToolbar extends ConsumerStatefulWidget {
  const LedgerFilterToolbar({super.key});

  @override
  ConsumerState<LedgerFilterToolbar> createState() => _LedgerFilterToolbarState();
}

class _LedgerFilterToolbarState extends ConsumerState<LedgerFilterToolbar> {
  final _searchController = TextEditingController();

  static const _modes = ['All', 'Cash', 'UPI', 'Card', 'Net Banking', 'Cheque', 'Other'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateRange(DateTimeRange range) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final s = range.start;
    final e = range.end;
    return '${s.day} ${months[s.month - 1]} - ${e.day} ${months[e.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(ledgerViewModelProvider);
    final vm = ref.read(ledgerViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search & Record Payment Row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by Order ID, customer, reference, note...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            vm.setSearchQuery('');
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onChanged: (val) => vm.setSearchQuery(val),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                elevation: 2,
                shadowColor: Colors.black38,
              ),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Record Entry'),
              onPressed: () => showRecordPaymentDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Filters Row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Type Chips
            ChoiceChip(
              label: const Text('All'),
              selected: state.typeFilter == null,
              onSelected: (_) => vm.setTypeFilter(null),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.arrow_downward, size: 14, color: Colors.green),
              label: Text('Payments (${state.creditCount})'),
              selected: state.typeFilter == PaymentType.credit,
              onSelected: (_) => vm.setTypeFilter(PaymentType.credit),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.arrow_upward, size: 14, color: Colors.deepOrange),
              label: Text('Refunds (${state.debitCount})'),
              selected: state.typeFilter == PaymentType.debit,
              onSelected: (_) => vm.setTypeFilter(PaymentType.debit),
            ),

            // Payment Mode Dropdown styled as a chip
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: state.paymentModeFilter != null
                    ? cs.secondaryContainer.withValues(alpha: 0.7)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: state.paymentModeFilter != null
                      ? cs.secondary
                      : cs.outlineVariant.withValues(alpha: 0.8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: state.paymentModeFilter ?? 'All',
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  borderRadius: BorderRadius.circular(12),
                  items: _modes
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.payment,
                                  size: 14,
                                  color: state.paymentModeFilter == m && m != 'All'
                                      ? cs.secondary
                                      : cs.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  m == 'All' ? 'Mode: All' : 'Mode: $m',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: state.paymentModeFilter == m
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    vm.setPaymentModeFilter(val == 'All' ? null : val);
                  },
                ),
              ),
            ),

            // Date Range Picker Button
            ActionChip(
              avatar: Icon(Icons.calendar_today_outlined, size: 14, color: cs.primary),
              label: Text(
                state.dateRange == null
                    ? 'All Dates'
                    : _formatDateRange(state.dateRange!),
              ),
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2025),
                  lastDate: DateTime(2030),
                  initialDateRange: state.dateRange,
                );
                if (picked != null) {
                  vm.setDateRange(picked);
                }
              },
            ),

            // Clear Filters Button if any filter active
            if (state.typeFilter != null ||
                state.paymentModeFilter != null ||
                state.dateRange != null ||
                state.searchQuery.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  vm.clearFilters();
                },
                icon: const Icon(Icons.filter_alt_off, size: 16),
                label: const Text('Reset', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ],
    );
  }
}
