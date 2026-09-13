/// Web SQLite connection factory using drift's WASM (WebAssembly) backend.
///
/// Data is persisted in the browser's **Origin Private File System (OPFS)**
/// via `sqlite3.wasm`. Falls back to an in-memory database if OPFS is
/// unavailable (e.g., in non-secure contexts).
library;

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens (or creates) a SQLite database in the browser's OPFS storage and
/// returns a [QueryExecutor] for drift to use.
///
/// ### Web setup required
/// Copy the `sqlite3.wasm` file from the `sqlite3` package to your `web/`
/// folder. Add this to `web/index.html` **before** your Flutter bootstrap:
/// ```html
/// <script src="sqlite3.wasm" type="module"></script>
/// ```
/// Run `dart run drift_dev make-migrations` after schema changes.
Future<QueryExecutor> openConnection() async {
  final db = await WasmDatabase.open(
    databaseName: 'mithai_wale',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
  );

  if (db.missingFeatures.isNotEmpty) {
    // Log degraded storage mode in debug builds.
    assert(
      () {
        // ignore: avoid_print
        print(
          '[DB] Missing web storage features: ${db.missingFeatures}. '
          'Falling back to in-memory storage.',
        );
        return true;
      }(),
    );
  }

  return db.resolvedExecutor;
}
