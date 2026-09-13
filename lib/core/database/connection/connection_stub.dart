/// Stub connection factory used during compilation when no platform target is
/// selected. The real implementations are in connection_native.dart and
/// connection_web.dart, selected via conditional imports in [AppDatabase].
library;

import 'package:drift/drift.dart';

/// Returns a [QueryExecutor] appropriate for the current platform.
///
/// Throws [UnsupportedError] at runtime — this stub is only used at
/// analysis time; the conditional import system selects the correct
/// platform implementation during compilation.
QueryExecutor openConnection() {
  throw UnsupportedError(
    'openConnection() stub called. '
    'This usually means the conditional import was not resolved correctly. '
    'Ensure you are targeting a supported platform (Android, iOS, Windows, Web).',
  );
}
