import 'package:flutter/widgets.dart';
import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// Extension on [BuildContext] for easy, typed access to [AppLocalizations].
///
/// Usage:
/// ```dart
/// import 'package:mithai_wale/l10n/l10n.dart';
///
/// Text(context.l10n.appName)
/// ```
extension AppLocalizationsX on BuildContext {
  /// Localized messages for the current context.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
