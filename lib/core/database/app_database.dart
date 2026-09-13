/// Drift database schema for mithai_wale.
///
/// Uses conditional imports to select the correct [QueryExecutor] for the
/// current target platform:
/// - Web     → [connection_web.dart]   (WASM / OPFS)
/// - Native  → [connection_native.dart] (SQLite via sqlite3_flutter_libs)
library;

import 'package:drift/drift.dart';

// Conditional import — resolves to the correct platform connection factory.
import 'connection/connection_stub.dart'
    if (dart.library.html) 'connection/connection_web.dart'
    if (dart.library.io) 'connection/connection_native.dart';

part 'app_database.g.dart';

// ── Tables ────────────────────────────────────────────────────────────────────

/// Stores arbitrary key-value application settings.
///
/// Example rows:
/// | key             | value       |
/// |-----------------|-------------|
/// | theme_mode      | dark        |
/// | currency        | INR         |
/// | items_per_page  | 20          |
class SettingsTable extends Table {
  /// Unique setting identifier (e.g. `theme_mode`, `locale`).
  TextColumn get key => text().withLength(min: 1, max: 128)();

  /// String-encoded setting value. Consumers are responsible for
  /// parsing to the correct type (int, bool, enum, etc.).
  TextColumn get value => text().withLength(max: 1024)();

  @override
  Set<Column> get primaryKey => {key};
}

// ── Database ──────────────────────────────────────────────────────────────────

/// The root drift database class.
///
/// Add new [Table] subclasses to [tables] to extend the schema.
/// After every schema change, regenerate with:
/// ```bash
/// dart run build_runner build --delete-conflicting-outputs
/// ```
@DriftDatabase(tables: [SettingsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openExecutor());

  /// Called by drift to migrate the database when [schemaVersion] changes.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Add upgrade steps here as schemaVersion increases.
        },
      );
}

/// Synchronous-looking wrapper that lets us pass an async executor to the
/// super constructor without an async constructor.
QueryExecutor _openExecutor() {
  // ignore: invalid_use_of_visible_for_testing_member
  return LazyDatabase(() => openConnection());
}
