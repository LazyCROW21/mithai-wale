import 'package:flutter/material.dart';

import '../../core/widgets/admin_scaffold.dart';
import '../../l10n/l10n.dart';

/// Placeholder for the franchise-wide change log (planned as online-only).
class AuditPage extends StatelessWidget {
  const AuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return AdminScaffold(
      title: l10n.navAudit,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_outlined, size: 64, color: cs.outline),
              const SizedBox(height: 16),
              Text(l10n.auditComingSoonTitle, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                l10n.auditComingSoonBody,
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
