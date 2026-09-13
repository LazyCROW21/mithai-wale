/// Singleton database provider for the mithai_wale app.
///
/// Initialises [AppDatabase] once and exposes all repositories through a
/// single access point. Inject [DatabaseProvider.instance] at the app root
/// (e.g., via a Provider or InheritedWidget) so that all features share the
/// same database connection.
///
/// ### Example
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   final db = await DatabaseProvider.init();
///   runApp(MyApp(dbProvider: db));
/// }
/// ```
library;

import 'package:flutter/foundation.dart';

import 'app_database.dart';
import 'repositories/drift_settings_repository.dart';
import 'repositories/settings_repository.dart';

/// Central access point for all database repositories.
///
/// Call [DatabaseProvider.init] once at app startup, then use
/// [DatabaseProvider.instance] everywhere else.
class DatabaseProvider {
  DatabaseProvider._({required AppDatabase database})
      : _database = database,
        settings = DriftSettingsRepository(database);

  /// The underlying drift database. Prefer accessing repositories over
  /// using this directly.
  final AppDatabase _database;

  // ── Repositories ────────────────────────────────────────────────────────────

  /// Key-value settings repository — platform-agnostic.
  final ISettingsRepository settings;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  static DatabaseProvider? _instance;

  /// Returns the initialised [DatabaseProvider].
  ///
  /// Throws if [init] has not been called yet.
  static DatabaseProvider get instance {
    assert(_instance != null, 'DatabaseProvider.init() must be called before accessing DatabaseProvider.instance.');
    return _instance!;
  }

  /// Initialises the database and all repositories.
  ///
  /// Safe to call multiple times — subsequent calls return the existing
  /// instance without re-opening the database.
  static Future<DatabaseProvider> init() async {
    if (_instance != null) return _instance!;

    final db = AppDatabase();
    _instance = DatabaseProvider._(database: db);

    if (kDebugMode) {
      print('[DB] Database initialised on ${_platformName()}');
    }

    return _instance!;
  }

  /// Closes the database connection. Call on app teardown if needed.
  Future<void> dispose() async {
    await _database.close();
    _instance = null;
  }

  static String _platformName() {
    if (kIsWeb) return 'Web (WASM/OPFS)';
    return defaultTargetPlatform.name;
  }
}
