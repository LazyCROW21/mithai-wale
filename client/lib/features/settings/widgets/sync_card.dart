import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/sync/sync_engine.dart';
import '../../../l10n/l10n.dart';

/// Sync status plus "Sync now" and the full "Re-sync from cloud" action.
class SyncCard extends ConsumerWidget {
  const SyncCard({super.key});

  Future<void> _resync(BuildContext context, SyncStatus status) async {
    final l10n = context.l10n;
    final pending = status.pending;

    // 1. Confirm, and decide what happens to changes not uploaded yet.
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.syncResyncConfirmTitle),
        content: Text(
          pending == 0
              ? l10n.syncResyncConfirmBody
              : '${l10n.syncResyncConfirmBody}\n\n${l10n.syncResyncPendingBody(pending)}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.actionCancel)),
          if (pending > 0)
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, 'discard'),
              child: Text(l10n.syncDiscardAndResync),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'upload'),
            child: Text(pending > 0 ? l10n.syncUploadThenResync : l10n.syncResync),
          ),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;

    if (choice == 'discard') {
      final sure = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(l10n.syncDiscardConfirm),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.actionCancel)),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.syncDiscardAndResync),
            ),
          ],
        ),
      );
      if (sure != true || !context.mounted) return;
    }

    // 2. Run with a blocking progress dialog.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ResyncProgressDialog(),
    );
    var ok = true;
    try {
      await syncEngine.fullResync(discardPending: choice == 'discard');
    } catch (_) {
      ok = false;
    }
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(ok ? l10n.syncResyncDone : l10n.syncResyncFailed)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final s = ref.watch(syncStatusProvider);

    final (icon, color, label) = switch (s.phase) {
      SyncPhase.syncing || SyncPhase.resyncing => (Icons.sync, cs.primary, l10n.syncStatusSyncing),
      SyncPhase.offline => (Icons.cloud_off_outlined, cs.outline, l10n.syncStatusOffline),
      SyncPhase.error => (Icons.error_outline, cs.error, l10n.syncStatusError(s.message ?? '')),
      SyncPhase.idle => s.pending > 0
          ? (Icons.cloud_upload_outlined, cs.tertiary, l10n.syncPending(s.pending))
          : (Icons.cloud_done_outlined, cs.primary, l10n.syncStatusSynced),
    };
    final last = s.lastSyncAt == null
        ? l10n.syncNever
        : l10n.syncLastSynced(DateFormat.yMMMd(Localizations.localeOf(context).toString())
            .add_jm()
            .format(s.lastSyncAt!));

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.syncTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(label, style: TextStyle(color: color)),
                      Text(last, style: TextStyle(fontSize: 12, color: cs.outline)),
                      if (s.pending > 0 && s.phase != SyncPhase.idle)
                        Text(l10n.syncPending(s.pending), style: TextStyle(fontSize: 12, color: cs.outline)),
                    ],
                  ),
                ),
              ],
            ),
            if (s.failed > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: cs.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.syncFailed(s.failed), style: TextStyle(color: cs.error))),
                  TextButton(onPressed: syncEngine.clearFailed, child: Text(l10n.syncClearFailed)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: s.isBusy ? null : syncEngine.syncNow,
                  icon: const Icon(Icons.sync),
                  label: Text(l10n.syncNow),
                ),
                OutlinedButton.icon(
                  onPressed: s.isBusy ? null : () => _resync(context, s),
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: Text(l10n.syncResync),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(l10n.syncResyncDesc, style: TextStyle(fontSize: 12, color: cs.outline)),
          ],
        ),
      ),
    );
  }
}

class _ResyncProgressDialog extends ConsumerWidget {
  const _ResyncProgressDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(syncStatusProvider.select((s) => s.downloaded));
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(context.l10n.syncResyncProgress(count))),
          ],
        ),
      ),
    );
  }
}
