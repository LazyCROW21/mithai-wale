import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../auth/auth_notifier.dart';
import '../routing/router_key.dart';
import '../routing/routes.dart';
import '../sync/sync_engine.dart';

/// Who is signed in, sync status and sign out.
///
/// Screen navigation lives in the app shell (desktop side bar / mobile "More");
/// the shop each record belongs to is picked where the record is created.
class AccountMenuButton extends ConsumerWidget {
  const AccountMenuButton({super.key});

  static const _signOut = '__sign_out__';
  static const _syncNow = '__sync_now__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).session;
    if (session == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final sync = ref.watch(syncStatusProvider);

    final syncIcon = switch (sync.phase) {
      SyncPhase.syncing || SyncPhase.resyncing => Icons.sync,
      SyncPhase.offline => Icons.cloud_off_outlined,
      SyncPhase.error => Icons.error_outline,
      SyncPhase.idle =>
        sync.pending > 0
            ? Icons.cloud_upload_outlined
            : Icons.cloud_done_outlined,
    };
    final syncLabel = switch (sync.phase) {
      SyncPhase.syncing || SyncPhase.resyncing => l10n.syncStatusSyncing,
      SyncPhase.offline => l10n.syncStatusOffline,
      SyncPhase.error => l10n.syncStatusError(sync.message ?? ''),
      SyncPhase.idle =>
        sync.pending > 0
            ? l10n.syncPending(sync.pending)
            : l10n.syncStatusSynced,
    };

    return PopupMenuButton<String>(
      tooltip: l10n.navManage,
      icon: Badge(
        isLabelVisible: sync.pending > 0 || sync.failed > 0,
        backgroundColor: sync.failed > 0 ? cs.error : cs.tertiary,
        label: Text('${sync.pending + sync.failed}'),
        child: const Icon(Icons.account_circle_outlined),
      ),
      onSelected: (value) async {
        if (value == _signOut) {
          AppNav.push(AppRoutes.confirmLogout);
        } else if (value == _syncNow) {
          syncEngine.syncNow();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(session.role.label(l10n)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: _syncNow,
          child: ListTile(
            leading: Icon(syncIcon),
            title: Text(syncLabel),
            dense: true,
          ),
        ),
        const PopupMenuDivider(),
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
