import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home_providers.dart';

/// Card showing the total menu items to build across all orders.
///
/// Each item displays:
/// e.g. `Ladoo = 12 kg (total 5 orders)`
class MenuItemsToBuildCard extends ConsumerWidget {
  const MenuItemsToBuildCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(homeViewModelProvider);
    final itemsToBuild = state.menuItemsToBuild;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withAlpha(120)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Menu Items to Build',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'From all orders in database',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.outline,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withAlpha(150),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${itemsToBuild.length} to make',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content: Empty State or Items List
            if (itemsToBuild.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant.withAlpha(60)),
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
                      'When orders are placed, items will aggregate here for kitchen production.',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: itemsToBuild.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final item = itemsToBuild[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.outlineVariant.withAlpha(90)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: cs.primary.withAlpha(30),
                          child: Icon(
                            Icons.cookie_outlined,
                            size: 16,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Prominent representation: e.g. Ladoo = 12 kg (total 5 orders)
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
      ),
    );
  }
}
