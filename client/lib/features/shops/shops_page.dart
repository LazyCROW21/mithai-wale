import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/widgets/admin_scaffold.dart';
import '../../l10n/l10n.dart';

class Shop {
  const Shop({
    required this.id,
    required this.name,
    required this.active,
    this.address,
    this.phone,
  });

  final String id;
  final String name;
  final bool active;
  final String? address;
  final String? phone;

  factory Shop.fromJson(Map<String, dynamic> j) => Shop(
        id: j['_id'] as String,
        name: j['name'] as String,
        active: j['active'] as bool? ?? true,
        address: j['address'] as String?,
        phone: j['phone'] as String?,
      );
}

final shopsProvider = FutureProvider.autoDispose<List<Shop>>((ref) async {
  final j = await ref.watch(apiClientProvider).get('/shops') as List;
  return [for (final s in j.cast<Map<String, dynamic>>()) Shop.fromJson(s)];
});

/// Franchise admin: manage shops.
class ShopsPage extends ConsumerWidget {
  const ShopsPage({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [Shop? shop]) async {
    final l10n = context.l10n;
    final name = TextEditingController(text: shop?.name);
    final address = TextEditingController(text: shop?.address);
    final phone = TextEditingController(text: shop?.phone);
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(shop == null ? l10n.shopAdd : l10n.shopEdit),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: InputDecoration(labelText: l10n.shopName),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.authFieldRequired : null,
                ),
                TextFormField(
                  controller: address,
                  decoration: InputDecoration(labelText: l10n.shopAddress),
                ),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: l10n.shopPhone),
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
    );
    if (ok != true || !context.mounted) return;

    final body = {
      'name': name.text.trim(),
      if (address.text.trim().isNotEmpty) 'address': address.text.trim(),
      if (phone.text.trim().isNotEmpty) 'phone': phone.text.trim(),
    };
    final api = ref.read(apiClientProvider);
    try {
      if (shop == null) {
        await api.post('/shops', body: body);
      } else {
        await api.patch('/shops/${shop.id}', body: body);
      }
      ref.invalidate(shopsProvider);
    } catch (e) {
      if (context.mounted) showApiError(context, e);
    }
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, Shop shop) async {
    try {
      await ref.read(apiClientProvider).patch('/shops/${shop.id}', body: {'active': !shop.active});
      ref.invalidate(shopsProvider);
    } catch (e) {
      if (context.mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final shops = ref.watch(shopsProvider);

    return AdminScaffold(
      title: l10n.navShops,
      addLabel: l10n.shopAdd,
      onAdd: () => _edit(context, ref),
      body: shops.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(shopsProvider)),
        data: (list) => list.isEmpty
            ? Center(child: Text(l10n.shopsEmpty))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final s = list[i];
                  return Card(
                    elevation: 1,
                    child: ListTile(
                      leading: const Icon(Icons.storefront_outlined),
                      title: Text(s.name),
                      subtitle: Text([
                        if (s.address != null) s.address!,
                        if (s.phone != null) s.phone!,
                        s.active ? l10n.statusActive : l10n.statusDisabled,
                      ].join(' · ')),
                      onTap: () => _edit(context, ref, s),
                      trailing: Switch(
                        value: s.active,
                        onChanged: (_) => _toggle(context, ref, s),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
