import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../auth/auth_models.dart';
import '../auth/auth_notifier.dart';
import '../routing/router_key.dart';
import '../routing/routes.dart';

/// Who is signed in, the management screens their role allows
/// (shops / staff / inventory) and sign out.
///
/// Entries are driven by the session permissions the server returned, so a store
/// owner never sees staff or shop management.
class AccountMenuButton extends ConsumerWidget {
  const AccountMenuButton({super.key});

  static const _signOut = '__sign_out__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).session;
    if (session == null) return const SizedBox.shrink();
    final l10n = context.l10n;

    final entries = <(Permission, IconData, String, String)>[
      (Permission.shops, Icons.storefront_outlined, l10n.navShops, AppRoutes.shops),
      (Permission.staff, Icons.badge_outlined, l10n.navStaff, AppRoutes.staff),
      (Permission.inventory, Icons.inventory_2_outlined, l10n.navInventory, AppRoutes.inventory),
    ].where((e) => session.can(e.$1)).toList();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.account_circle_outlined),
      tooltip: l10n.navManage,
      onSelected: (route) {
        if (route == _signOut) {
          AppNav.push(AppRoutes.confirmLogout);
        } else {
          AppNav.go(route);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              // Store-scoped users see their role only; the franchise name/shop
              // list is not repeated for them.
              Text(session.role.label(l10n)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        for (final e in entries)
          PopupMenuItem<String>(
            value: e.$4,
            child: ListTile(leading: Icon(e.$2), title: Text(e.$3), dense: true),
          ),
        if (entries.isNotEmpty) const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: _signOut,
          child: ListTile(
            leading: const Icon(Icons.logout_outlined),
            title: Text(l10n.actionSignOut),
            dense: true,
          ),
        ),
      ],
    );
  }
}
