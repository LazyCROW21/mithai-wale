import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/routing/app_destinations.dart';
import '../../core/routing/router_key.dart';
import '../../core/routing/routes.dart';
import '../../l10n/l10n.dart';

/// Mobile/tablet hub (5th bottom-bar tab): every screen that is not on the
/// bottom bar, filtered by the signed-in user's permissions.
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  static const _accountRoutes = {AppRoutes.profile, AppRoutes.settings};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final allowed = appDestinations
        .where((d) => d.allowed(session) && !bottomBarRoutes.contains(d.route))
        .toList();
    final manage = allowed.where((d) => !_accountRoutes.contains(d.route)).toList();
    final account = allowed.where((d) => _accountRoutes.contains(d.route)).toList();
    final shopLine = session.isStoreScoped ? session.ownShop?.name : session.tenantName;

    Widget section(String title, List<AppDestination> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Text(title, style: theme.textTheme.titleSmall?.copyWith(color: cs.primary)),
            ),
            Card(
              elevation: 1,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (i, d) in items.indexed) ...[
                    if (i > 0) const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Icon(d.icon),
                      title: Text(d.label(l10n)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => AppNav.go(d.route),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMore)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Card(
            elevation: 1,
            color: cs.primaryContainer,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                child: Text(session.name.isEmpty ? '?' : session.name[0].toUpperCase()),
              ),
              title: Text(session.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text([session.role.label(l10n), ?shopLine].join(' · ')),
            ),
          ),
          if (manage.isNotEmpty) section(l10n.moreManageSection, manage),
          if (account.isNotEmpty) section(l10n.moreAccountSection, account),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.logout_outlined, color: cs.error),
              title: Text(l10n.actionSignOut, style: TextStyle(color: cs.error)),
              onTap: () => AppNav.push(AppRoutes.confirmLogout),
            ),
          ),
        ],
      ),
    );
  }
}
