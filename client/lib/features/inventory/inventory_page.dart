import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/database/repositories/inventory_repository.dart';
import '../../core/di/service_locator.dart';
import '../../core/state/shop_filter.dart';
import '../../core/widgets/admin_scaffold.dart';
import '../../l10n/l10n.dart';

/// Local, offline-first inventory list (updates live as sync writes to Hive),
/// narrowed by the global shop filter. Store-scoped users only ever have their
/// own shop's stock on the device (the server sends nothing else).
final inventoryProvider = StreamProvider.autoDispose<List<InventoryItem>>((
  ref,
) {
  final shopId = ref.watch(shopFilterProvider);
  return sl<InventoryRepository>().watch(shopId: shopId);
});

String _fmt(num n) =>
    n == n.roundToDouble() ? n.toInt().toString() : n.toString();

class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final session = ref.read(sessionProvider);
    final name = TextEditingController();
    final unit = TextEditingController(text: 'kg');
    final qty = TextEditingController(text: '0');
    final low = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    // Store-scoped: own shop. Franchise admin: the filtered shop, else must pick.
    String? shopId = ref.read(defaultShopIdProvider);
    if (session.isStoreScoped && shopId == null) return;

    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? l10n.authFieldRequired : null;
    String? number(String? v) {
      final n = num.tryParse(v ?? '');
      return n == null || n < 0 ? l10n.authFieldRequired : null;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.inventoryAdd),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Only the franchise admin chooses a shop.
                  if (session.isFranchiseAdmin)
                    DropdownButtonFormField<String>(
                      initialValue: shopId,
                      decoration: InputDecoration(
                        labelText: l10n.inventoryShop,
                      ),
                      items: [
                        for (final s in session.shops)
                          DropdownMenuItem(value: s.id, child: Text(s.name)),
                      ],
                      validator: (v) =>
                          v == null ? l10n.orderShopRequired : null,
                      onChanged: (v) => setState(() => shopId = v ?? shopId),
                    ),
                  TextFormField(
                    controller: name,
                    decoration: InputDecoration(
                      labelText: l10n.inventoryItemName,
                    ),
                    validator: required,
                  ),
                  TextFormField(
                    controller: unit,
                    decoration: InputDecoration(labelText: l10n.inventoryUnit),
                    validator: required,
                  ),
                  TextFormField(
                    controller: qty,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.inventoryQuantity,
                    ),
                    validator: number,
                  ),
                  TextFormField(
                    controller: low,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.inventoryLowStock,
                    ),
                    validator: number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;

    await sl<InventoryRepository>().add(
      shopId: shopId!,
      name: name.text.trim(),
      unit: unit.text.trim(),
      quantity: num.parse(qty.text),
      lowStockThreshold: num.parse(low.text),
    );
  }

  Future<void> _adjust(BuildContext context, InventoryItem item) async {
    final l10n = context.l10n;
    final delta = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n.inventoryAdjust}: ${item.name}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: delta,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: InputDecoration(
              labelText: l10n.inventoryAdjustBy,
              helperText:
                  '${l10n.inventoryQuantity}: ${_fmt(item.quantity)} ${item.unit}',
            ),
            validator: (v) {
              final n = num.tryParse(v ?? '');
              if (n == null) return l10n.authFieldRequired;
              return item.quantity + n < 0 ? l10n.inventoryLow : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await sl<InventoryRepository>().adjust(item.id, num.parse(delta.text));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(sessionProvider);
    final items = ref.watch(inventoryProvider);
    final shopNames = {for (final s in session.shops) s.id: s.name};
    // Employees can view stock but not change it (server: owner/manager write).
    final canEdit = session.role != AppRole.employee;

    return AdminScaffold(
      title: l10n.navInventory,
      addLabel: l10n.inventoryAdd,
      onAdd: canEdit ? () => _add(context, ref) : null,
      actions: const [ShopFilterButton(), SizedBox(width: 8)],
      body: Column(
        children: [
          Expanded(
            child: items.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorRetry(
                error: e,
                onRetry: () => ref.invalidate(inventoryProvider),
              ),
              data: (list) => list.isEmpty
                  ? Center(child: Text(l10n.inventoryEmpty))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final it = list[i];
                        final cs = Theme.of(context).colorScheme;
                        return Card(
                          elevation: 1,
                          child: ListTile(
                            leading: Icon(
                              it.isLow
                                  ? Icons.warning_amber_rounded
                                  : Icons.inventory_2_outlined,
                              color: it.isLow ? cs.error : null,
                            ),
                            title: Text(it.name),
                            // Shop name is only shown to the franchise admin.
                            subtitle: session.isFranchiseAdmin
                                ? Text(shopNames[it.shopId] ?? '')
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (it.isLow)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      l10n.inventoryLow,
                                      style: TextStyle(color: cs.error),
                                    ),
                                  ),
                                Text(
                                  '${_fmt(it.quantity)} ${it.unit}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                if (canEdit)
                                  IconButton(
                                    tooltip: l10n.inventoryAdjust,
                                    icon: const Icon(Icons.tune),
                                    onPressed: () => _adjust(context, it),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
