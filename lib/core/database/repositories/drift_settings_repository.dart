/// Drift-backed implementation of [ISettingsRepository].
///
/// All reads/writes are performed against the [SettingsTable] in the
/// shared [AppDatabase]. The `watch` stream is powered by drift's reactive
/// query engine — it emits automatically whenever the underlying row changes.
library;

import 'package:drift/drift.dart';

import '../app_database.dart';
import 'settings_repository.dart';

/// Concrete [ISettingsRepository] using drift / SQLite as the backing store.
class DriftSettingsRepository implements ISettingsRepository {
  const DriftSettingsRepository(this._db);

  final AppDatabase _db;

  // ── Queries ─────────────────────────────────────────────────────────────────

  @override
  Future<String?> get(String key) async {
    final row = await (_db.select(_db.settingsTable)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> set(String key, String value) {
    return _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion(
            key: Value(key),
            value: Value(value),
          ),
        );
  }

  @override
  Future<void> remove(String key) async {
    await (_db.delete(_db.settingsTable)..where((t) => t.key.equals(key))).go();
  }

  @override
  Future<List<SettingEntry>> getAll() async {
    final rows = await _db.select(_db.settingsTable).get();
    return rows.map((r) => SettingEntry(key: r.key, value: r.value)).toList();
  }

  @override
  Stream<String?> watch(String key) {
    return (_db.select(_db.settingsTable)..where((t) => t.key.equals(key))).watchSingleOrNull().map((r) => r?.value);
  }

  @override
  Future<void> clear() => _db.delete(_db.settingsTable).go();
}
