import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/di/service_locator.dart';
import '../../core/printing/print_profile.dart';
import '../../core/printing/print_profile_repository.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/widgets/admin_scaffold.dart';
import '../../core/widgets/refresh_button.dart';
import '../../l10n/l10n.dart';
import 'print_setup_page.dart';

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

/// Print setups (franchise default + per shop), always read fresh from the
/// server because they are edited here.
final printProfilesProvider = FutureProvider.autoDispose<PrintProfileSet>(
  (ref) => sl<IPrintProfileRepository>().load(requireFresh: true),
);

/// Franchise admin: manage shops and every print setup.
/// Store owner: the print setup of their own shop only.
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
      // Keep the session's shop list (and the billing shop) current.
      await appAuth.refreshSession();
      final shops = appAuth.current.session?.shops ?? const [];
      if (syncEngine.store.activeShopId == null && shops.isNotEmpty) {
        await syncEngine.store.setMeta('activeShopId', shops.first.id);
      }
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

  /// Opens print setup for [shop], or for the franchise default when null.
  Future<void> _printSetup(BuildContext context, WidgetRef ref, [Shop? shop]) async {
    final PrintProfileSet profiles;
    try {
      profiles = await ref.read(printProfilesProvider.future);
    } catch (e) {
      if (context.mounted) showApiError(context, e);
      return;
    }
    if (!context.mounted) return;
    final saved = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PrintSetupPage(
          shopId: shop?.id,
          shopName: shop?.name,
          own: shop == null ? profiles.franchise : profiles.shops[shop.id],
          inherited: profiles.franchise ?? PrintProfile.standard,
        ),
      ),
    );
    if (saved == true) ref.invalidate(printProfilesProvider);
  }

  Widget _printSetupButton(BuildContext context, VoidCallback onPressed) => IconButton.filledTonal(
        onPressed: onPressed,
        tooltip: context.l10n.printSetup,
        style: raisedIconButtonStyle(context),
        icon: const Icon(Icons.print_outlined, size: 20),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final shops = ref.watch(shopsProvider);
    final profiles = ref.watch(printProfilesProvider).valueOrNull;
    // Only the franchise admin manages shops; store owners get print setup only.
    final isAdmin = ref.watch(sessionProvider).isFranchiseAdmin;

    return AdminScaffold(
      title: l10n.navShops,
      addLabel: l10n.shopAdd,
      onAdd: isAdmin ? () => _edit(context, ref) : null,
      actions: [
        RefreshButton(
          busy: shops.isLoading,
          onPressed: () {
            ref.invalidate(shopsProvider);
            ref.invalidate(printProfilesProvider);
          },
        ),
        const SizedBox(width: 8),
      ],
      body: shops.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(shopsProvider)),
        data: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            if (isAdmin)
              Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l10n.printSetupFranchise),
                  subtitle: Text(l10n.printSetupFranchiseDesc),
                  trailing: _printSetupButton(context, () => _printSetup(context, ref)),
                ),
              ),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Center(child: Text(l10n.shopsEmpty)),
              ),
            for (final s in list)
              Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: Text(s.name),
                  subtitle: Text([
                    if (s.address != null) s.address!,
                    if (s.phone != null) s.phone!,
                    s.active ? l10n.statusActive : l10n.statusDisabled,
                    if (profiles != null)
                      profiles.shops.containsKey(s.id)
                          ? l10n.printUsesOwnSetup
                          : l10n.printUsesFranchiseDefault,
                  ].join(' · ')),
                  onTap: isAdmin ? () => _edit(context, ref, s) : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _printSetupButton(context, () => _printSetup(context, ref, s)),
                      if (isAdmin) ...[
                        const SizedBox(width: 8),
                        Switch(value: s.active, onChanged: (_) => _toggle(context, ref, s)),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
