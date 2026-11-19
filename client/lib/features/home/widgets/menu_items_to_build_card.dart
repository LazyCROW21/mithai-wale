import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home_providers.dart';

/// Card showing the total menu items to build across all active orders,
/// combined if getting delivered on the same date, sorted and grouped by delivery date.
///
/// Displays:
/// - Group Header by delivery date (Today, Tomorrow, or specific Date)
/// - Aggregated quantity lines: e.g. `Ladoo = 12 kg (total 5 orders)`
class MenuItemsToBuildCard extends ConsumerWidget {
  const MenuItemsToBuildCard({super.key});

  static String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final dayName = weekdays[date.weekday - 1];
    final dateStr = '${date.day} ${months[date.month - 1]} ${date.year}';

    if (date == today) {
      return 'Today • $dayName, $dateStr';
    } else if (date == tomorrow) {
      return 'Tomorrow • $dayName, $dateStr';
    }
    return '$dayName, $dateStr';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(homeViewModelProvider);
    final groupedItems = state.groupedItemsToBuild;
    final totalItems = state.menuItemsToBuild.length;
    final todayCount = state.todayItemsToBuild.length;
    final upcomingCount = state.upcomingItemsToBuild.length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header with KPI indicators
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.soup_kitchen_outlined,
                        size: 20,
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menu Items to Build',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Grouped by delivery date for kitchen prep',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.outline,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Indicator badges: Today & Total
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (todayCount > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$todayCount today',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                    if (upcomingCount > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.tertiaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$upcomingCount upcoming',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: cs.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$totalItems to make',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content: Empty State or Grouped Items by Delivery Date
            if (groupedItems.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 40,
                      color: cs.outline,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No items to build currently',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'When orders are placed, items will aggregate here grouped by delivery date.',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...groupedItems.entries.toList().asMap().entries.map((groupEntry) {
                final groupIndex = groupEntry.key;
                final group = groupEntry.value;
                final date = group.key;
                final items = group.value;
                final isEven = groupIndex % 2 == 0;
                final isDark = theme.brightness == Brightness.dark;

                final groupAccentColor = isEven ? cs.primary : cs.secondary;
                final groupCardBg = isEven
                    ? (isDark ? cs.surfaceContainer : cs.surface)
                    : (isDark ? cs.surfaceContainerHigh : cs.surfaceContainerHighest.withValues(alpha: 0.35));
                final groupHeaderBg = isEven
                    ? (isDark ? cs.primary.withValues(alpha: 0.18) : cs.primary.withValues(alpha: 0.08))
                    : (isDark ? cs.secondary.withValues(alpha: 0.20) : cs.secondary.withValues(alpha: 0.12));
                final groupBorderColor = isEven
                    ? cs.primary.withValues(alpha: isDark ? 0.35 : 0.25)
                    : cs.secondary.withValues(alpha: isDark ? 0.35 : 0.25);
                final groupBadgeBg = isEven ? cs.primaryContainer : cs.secondaryContainer;
                final groupBadgeText = isEven ? cs.onPrimaryContainer : cs.onSecondaryContainer;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: groupCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: groupBorderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Delivery Date Section Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: groupHeaderBg,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_note_outlined, size: 16, color: groupAccentColor),
                            const SizedBox(width: 8),
                            Text(
                              _formatDateHeader(date),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: groupAccentColor,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: groupBadgeBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: groupBadgeText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Items in this delivery date
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, indent: 14, endIndent: 14),
                        itemBuilder: (context, i) {
                          final item = items[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 15,
                                  backgroundColor: cs.primary.withValues(alpha: 0.15),
                                  child: Icon(
                                    Icons.cookie_outlined,
                                    size: 15,
                                    color: cs.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.displayLine,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Needed across ${item.orderCount} ${item.orderCount == 1 ? 'order' : 'orders'}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: cs.outline,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${item.formattedQuantity} ${item.unit}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: cs.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
