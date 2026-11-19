import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// Raised icon-button look shared by toolbar actions, so every screen's
/// refresh (and similar) button reads as a button.
ButtonStyle raisedIconButtonStyle(BuildContext context) => IconButton.styleFrom(
      elevation: 2,
      shadowColor: Theme.of(context).brightness == Brightness.dark ? Colors.black87 : Colors.black45,
    );

/// The one refresh button used across the app.
///
/// Shows a spinner instead of the icon while [busy].
class RefreshButton extends StatelessWidget {
  const RefreshButton({super.key, required this.onPressed, this.tooltip, this.busy = false});

  final VoidCallback? onPressed;

  /// Defaults to the localized "Refresh".
  final String? tooltip;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton.filledTonal(
        onPressed: busy ? null : onPressed,
        tooltip: tooltip ?? context.l10n.actionRefresh,
        style: raisedIconButtonStyle(context),
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh, size: 20),
      ),
    );
  }
}
