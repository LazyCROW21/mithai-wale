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
class SettingsTable extends Table {
  /// Unique setting identifier (e.g. `theme_mode`, `locale`).
  TextColumn get key => text().withLength(min: 1, max: 128)();

  /// String-encoded setting value.
  TextColumn get value => text().withLength(max: 1024)();

  @override
  Set<Column> get primaryKey => {key};
}

/// Stores categories for sweets/items.
@DataClassName('Category')
class CategoriesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get emoji => text().nullable().withLength(max: 10)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Stores menu items with pricing, category, and unit details.
@DataClassName('MenuItem')
class MenuItemsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  IntColumn get categoryId =>
      integer().nullable().references(CategoriesTable, #id, onDelete: KeyAction.setNull)();
  RealColumn get price => real()();
  TextColumn get unit => text().withLength(max: 50)(); // 'per piece', 'gm', 'kg', 'litre'
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ── Database ──────────────────────────────────────────────────────────────────

/// The root drift database class.
@DriftDatabase(tables: [SettingsTable, CategoriesTable, MenuItemsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openExecutor());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaults();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(categoriesTable);
            await m.createTable(menuItemsTable);
            await _seedDefaults();
          }
        },
      );

  Future<void> _seedDefaults() async {
    final catCount = await select(categoriesTable).get();
    if (catCount.isEmpty) {
      final defaultCategories = [
        (name: 'Ladoo', emoji: '🟡'),
        (name: 'Barfi', emoji: '🍬'),
        (name: 'Halwa', emoji: '🍮'),
        (name: 'Peda', emoji: '🟤'),
        (name: 'Rasgulla', emoji: '⚪'),
        (name: 'Jalebi', emoji: '🌀'),
      ];
      for (final cat in defaultCategories) {
        await into(categoriesTable).insert(
          CategoriesTableCompanion.insert(
            name: cat.name,
            emoji: Value(cat.emoji),
          ),
        );
      }
    }

    final itemCount = await select(menuItemsTable).get();
    if (itemCount.isEmpty) {
      final cats = await select(categoriesTable).get();
      final catMap = {for (var c in cats) c.name: c.id};

      final defaultItems = [
        (title: 'Motichoor Ladoo', desc: 'Fresh & delicious pure ghee motichoor ladoo', category: 'Ladoo', price: 480.0, unit: 'kg'),
        (title: 'Kaju Barfi', desc: 'Premium cashew barfi with silver leaf', category: 'Barfi', price: 720.0, unit: 'kg'),
        (title: 'Gajar Halwa', desc: 'Rich winter carrot halwa cooked in milk & khoya', category: 'Halwa', price: 360.0, unit: 'kg'),
        (title: 'Milk Peda', desc: 'Traditional Mathura style milk peda', category: 'Peda', price: 400.0, unit: 'kg'),
        (title: 'Rasgulla', desc: 'Soft & spongy authentic Bengali rasgullas', category: 'Rasgulla', price: 320.0, unit: 'per piece'),
        (title: 'Jalebi', desc: 'Crispy ghee fried jalebi in saffron syrup', category: 'Jalebi', price: 280.0, unit: 'kg'),
      ];

      for (final item in defaultItems) {
        await into(menuItemsTable).insert(
          MenuItemsTableCompanion.insert(
            title: item.title,
            description: Value(item.desc),
            categoryId: Value(catMap[item.category]),
            price: item.price,
            unit: item.unit,
          ),
        );
      }
    }
  }
}

/// Synchronous-looking wrapper that lets us pass an async executor to the
/// super constructor without an async constructor.
QueryExecutor _openExecutor() {
  // ignore: invalid_use_of_visible_for_testing_member
  return LazyDatabase(() => openConnection());
}
