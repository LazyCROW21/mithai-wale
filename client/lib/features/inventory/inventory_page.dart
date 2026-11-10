import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/widgets/admin_scaffold.dart';
import '../../l10n/l10n.dart';

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.shopId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.lowStockThreshold,
  });

  final String id;
  final String shopId;
  final String name;
  final String unit;
  final num quantity;
  final num lowStockThreshold;

  bool get isLow => quantity <= lowStockThreshold;

  factory InventoryItem.fromJson(Map<String, dynamic> j) => InventoryItem(
        id: j['_id'] as String,
        shopId: j['shopId'] as String,
        name: j['name'] as String,
        unit: j['unit'] as String,
        quantity: j['quantity'] as num,
        lowStockThreshold: j['lowStockThreshold'] as num? ?? 0,
      );
}

/// Selected shop filter. Only meaningful for the franchise admin; store-scoped
/// users never set it (the server pins them to their own shop).
final inventoryShopFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

final inventoryProvider = FutureProvider.autoDispose<List<InventoryItem>>((ref) async {
  final shopId = ref.watch(inventoryShopFilterProvider);
  final j = await ref.watch(apiClientProvider).get(
        '/inventory',
        query: shopId == null ? null : {'shopId': shopId},
      ) as List;
  return [for (final i in j.cast<Map<String, dynamic>>()) InventoryItem.fromJson(i)];
});

String _fmt(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});

  /// Shop to write to: the store-scoped user's own shop, or the admin's filter / first shop.
  String? _targetShop(WidgetRef ref) {
    final session = ref.read(sessionProvider);
    return session.ownShop?.id ??
        ref.read(inventoryShopFilterProvider) ??
        (session.shops.isEmpty ? null : session.shops.first.id);
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final session = ref.read(sessionProvider);
    final name = TextEditingController();
    final unit = TextEditingController(text: 'kg');
    final qty = TextEditingController(text: '0');
    final low = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    var shopId = _targetShop(ref);
    if (shopId == null) return;

    String? required(String? v) => (v == null || v.trim().isEmpty) ? l10n.authFieldRequired : null;
    String? number(String? v) => num.tryParse(v ?? '') == null ? l10n.authFieldRequired : null;

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
                  if (session.isFranchiseAdmin) ...[
                    DropdownButtonFormField<String>(
                      initialValue: shopId,
                      decoration: InputDecoration(labelText: l10n.inventoryShop),
                      items: [
                        for (final s in session.shops)
                          DropdownMenuItem(value: s.id, child: Text(s.name)),
                      ],
                      onChanged: (v) => setState(() => shopId = v ?? shopId),
                    ),
                  ],
                  TextFormField(
                    controller: name,
                    decoration: InputDecoration(labelText: l10n.inventoryItemName),
                    validator: required,
                  ),
                  TextFormField(
                    controller: unit,
                    decoration: InputDecoration(labelText: l10n.inventoryUnit),
                    validator: required,
                  ),
                  TextFormField(
                    controller: qty,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.inventoryQuantity),
                    validator: number,
                  ),
                  TextFormField(
                    controller: low,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.inventoryLowStock),
                    validator: number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.actionCancel)),
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
    if (ok != true || !context.mounted) return;

    try {
      await ref.read(apiClientProvider).post('/shops/$shopId/inventory', body: {
        'name': name.text.trim(),
        'unit': unit.text.trim(),
        'quantity': num.parse(qty.text),
        'lowStockThreshold': num.parse(low.text),
      });
      ref.invalidate(inventoryProvider);
    } catch (e) {
      if (context.mounted) showApiError(context, e);
    }
  }

  Future<void> _adjust(BuildContext context, WidgetRef ref, InventoryItem item) async {
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: InputDecoration(
              labelText: l10n.inventoryAdjustBy,
              helperText: '${l10n.inventoryQuantity}: ${_fmt(item.quantity)} ${item.unit}',
            ),
            validator: (v) => num.tryParse(v ?? '') == null ? l10n.authFieldRequired : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.actionCancel)),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(apiClientProvider).post(
        '/shops/${item.shopId}/inventory/${item.id}/adjust',
        body: {'delta': num.parse(delta.text)},
      );
      ref.invalidate(inventoryProvider);
    } catch (e) {
      if (context.mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(sessionProvider);
    final items = ref.watch(inventoryProvider);
    final shopNames = {for (final s in session.shops) s.id: s.name};

    return AdminScaffold(
      title: l10n.navInventory,
      addLabel: l10n.inventoryAdd,
      onAdd: () => _add(context, ref),
      body: Column(
        children: [
          // Shop filter exists only for the franchise admin; store-scoped users are
          // pinned to their shop by the server, so nothing is shown here.
          if (session.isFranchiseAdmin)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: DropdownButtonFormField<String?>(
                initialValue: ref.watch(inventoryShopFilterProvider),
                decoration: InputDecoration(
                  labelText: l10n.inventoryShop,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.inventoryAllShops)),
                  for (final s in session.shops) DropdownMenuItem(value: s.id, child: Text(s.name)),
                ],
                onChanged: (v) => ref.read(inventoryShopFilterProvider.notifier).state = v,
              ),
            ),
          Expanded(
            child: items.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  ErrorRetry(error: e, onRetry: () => ref.invalidate(inventoryProvider)),
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
                              it.isLow ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
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
                                    child: Text(l10n.inventoryLow, style: TextStyle(color: cs.error)),
                                  ),
                                Text(
                                  '${_fmt(it.quantity)} ${it.unit}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                IconButton(
                                  tooltip: l10n.inventoryAdjust,
                                  icon: const Icon(Icons.tune),
                                  onPressed: () => _adjust(context, ref, it),
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
