/// Native SQLite connection factory for Android, iOS, and Windows.
///
/// Uses drift's [NativeDatabase] backed by `sqlite3_flutter_libs` which
/// bundles a pre-compiled SQLite binary for each native platform.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens (or creates) the SQLite database file in the application's documents
/// directory and returns a [QueryExecutor] for drift to use.
///
/// Platform-specific paths:
/// - **Android**: `/data/user/0/<package>/databases/mithai_wale.sqlite`
/// - **iOS**: `<app documents>/mithai_wale.sqlite`
/// - **Windows**: `%APPDATA%\mithai_wale\mithai_wale.sqlite`
Future<QueryExecutor> openConnection() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'mithai_wale.sqlite'));

  return NativeDatabase.createInBackground(
    file,
    // Enable WAL journal mode for better concurrent read performance.
    setup: (rawDb) => rawDb.execute('PRAGMA journal_mode=WAL;'),
  );
}
