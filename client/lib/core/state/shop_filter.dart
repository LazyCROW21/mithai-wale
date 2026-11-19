import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../auth/auth_models.dart';
import '../auth/auth_notifier.dart';

/// App-wide shop filter shared by Dashboard, Orders, Ledger and Inventory.
///
/// * Franchise admin: `null` = all shops, otherwise the selected shop id.
/// * Store-scoped users: always `null` — the device only ever holds their own
///   shop's data, so there is nothing to filter and no picker is shown.
///
/// Resets whenever a different user signs in.
class ShopFilterNotifier extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(authProvider.select((a) => a.session?.ownerKey));
    return null;
  }

  AuthSession? get _session => ref.read(authProvider).session;

  /// Selects [shopId] (`null` = all shops). Ignored for store-scoped users.
  void select(String? shopId) {
    final s = _session;
    if (s == null || !s.isFranchiseAdmin) return;
    state = shopId;
  }

  /// Whether a record from [recordShopId] passes the current filter.
  bool matches(String? recordShopId) => state == null || recordShopId == state;
}

final shopFilterProvider = NotifierProvider<ShopFilterNotifier, String?>(ShopFilterNotifier.new);

/// The shop new records (orders, payments, stock) should default to:
/// store-scoped users → their own shop; franchise admin → the filtered shop,
/// or `null` when "All shops" is selected (the user must then pick one).
final defaultShopIdProvider = Provider<String?>((ref) {
  final session = ref.watch(authProvider).session;
  if (session == null) return null;
  if (session.isStoreScoped) return session.ownShop?.id;
  return ref.watch(shopFilterProvider);
});

/// Shop picker for the franchise admin; renders nothing for store-scoped users.
class ShopFilterButton extends ConsumerWidget {
  const ShopFilterButton({super.key});

  static const _all = '__all__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).session;
    if (session == null || !session.isFranchiseAdmin || session.shops.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final selected = ref.watch(shopFilterProvider);
    final label = selected == null
        ? l10n.shopFilterAll
        : session.shops.where((s) => s.id == selected).firstOrNull?.name ?? l10n.shopFilterAll;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: PopupMenuButton<String>(
        tooltip: l10n.shopFilterTooltip,
        onSelected: (v) => ref.read(shopFilterProvider.notifier).select(v == _all ? null : v),
        itemBuilder: (_) => [
          CheckedPopupMenuItem(value: _all, checked: selected == null, child: Text(l10n.shopFilterAll)),
          const PopupMenuDivider(),
          for (final s in session.shops)
            CheckedPopupMenuItem(value: s.id, checked: selected == s.id, child: Text(s.name)),
        ],
        child: Material(
          elevation: 2,
          shadowColor: Colors.black26,
          color: selected == null ? cs.surfaceContainerHigh : cs.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront_outlined, size: 18, color: cs.onSecondaryContainer),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSecondaryContainer)),
                ),
                Icon(Icons.arrow_drop_down, size: 18, color: cs.onSecondaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dropdown for picking the shop a new record belongs to. Shown only to the
/// franchise admin; store-scoped users' records always go to their own shop.
class ShopPickerField extends ConsumerWidget {
  const ShopPickerField({super.key, required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).session;
    if (session == null || !session.isFranchiseAdmin) return const SizedBox.shrink();
    final l10n = context.l10n;
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: l10n.orderShopLabel,
        prefixIcon: const Icon(Icons.storefront_outlined),
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final s in session.shops) DropdownMenuItem(value: s.id, child: Text(s.name)),
      ],
      validator: (v) => v == null ? l10n.orderShopRequired : null,
      onChanged: onChanged,
    );
  }
}
