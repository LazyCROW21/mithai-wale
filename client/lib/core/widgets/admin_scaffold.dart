import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../network/api_client.dart';
import '../routing/router_key.dart';
import '../routing/routes.dart';

/// Shared frame for management screens (shops, staff, inventory):
/// app bar with back-to-home, centred width-constrained body, optional FAB.
class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onAdd,
    this.addLabel,
    this.actions = const [],
  });

  final String title;
  final Widget body;
  final VoidCallback? onAdd;
  final String? addLabel;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppNav.go(AppRoutes.home),
        ),
        title: Text(title),
        actions: actions,
      ),
      floatingActionButton: onAdd == null
          ? null
          : FloatingActionButton.extended(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(addLabel ?? context.l10n.actionAdd),
            ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: body,
        ),
      ),
    );
  }
}

/// Error state with a retry button.
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final msg = error is ApiException && (error as ApiException).isNetwork
        ? l10n.authNetworkError
        : l10n.errorGeneric;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(msg),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(l10n.actionRetry)),
        ],
      ),
    );
  }
}

/// Shows an error as a snackbar (network → localized message, server → its message).
void showApiError(BuildContext context, Object error) {
  final l10n = context.l10n;
  final msg = error is ApiException
      ? (error.isNetwork ? l10n.authNetworkError : error.message)
      : l10n.errorGeneric;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
