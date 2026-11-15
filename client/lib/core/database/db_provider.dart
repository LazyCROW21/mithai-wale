/// Opens local storage and builds the repositories.
///
/// Synced collections (categories, menu, orders, payments, inventory) live in
/// [SyncStore]; settings stay local-only.
library;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../sync/sync_store.dart';
import 'repositories/category_repository.dart';
import 'repositories/hive_category_repository.dart';
import 'repositories/hive_menu_repository.dart';
import 'repositories/hive_orders_repository.dart';
import 'repositories/hive_payments_repository.dart';
import 'repositories/hive_settings_repository.dart';
import 'repositories/inventory_repository.dart';
import 'repositories/menu_repository.dart';
import 'repositories/orders_repository.dart';
import 'repositories/payments_repository.dart';
import 'repositories/settings_repository.dart';

class DatabaseProvider {
  DatabaseProvider._({
    required Box<String> settingsBox,
    required this.sync,
  })  : settings = HiveSettingsRepository(settingsBox),
        categories = HiveCategoryRepository(sync),
        menu = HiveMenuRepository(sync),
        orders = HiveOrdersRepository(sync),
        payments = HivePaymentsRepository(sync),
        inventory = InventoryRepository(sync);

  final SyncStore sync;
  final ISettingsRepository settings;
  final ICategoryRepository categories;
  final IMenuRepository menu;
  final IOrdersRepository orders;
  final IPaymentsRepository payments;
  final InventoryRepository inventory;

  static DatabaseProvider? _instance;

  static DatabaseProvider get instance {
    assert(_instance != null, 'DatabaseProvider.init() must be called first.');
    return _instance!;
  }

  /// Bump to wipe local data on upgrade when the storage format changes.
  static const _schemaVersion = '2';

  static Future<DatabaseProvider> init() async {
    if (_instance != null) return _instance!;

    await Hive.initFlutter();
    final settingsBox = await Hive.openBox<String>('settings');

    // The cart was removed (orders are entered directly); drop its old box.
    if (await Hive.boxExists('cart_items')) await Hive.deleteBoxFromDisk('cart_items');

    // v1 stored int ids and local-only data. Discard it (development stage).
    if (settingsBox.get('db_schema_version') != _schemaVersion) {
      for (final name in const ['categories', 'menu_items', 'orders', 'payments', 'cart_items']) {
        await Hive.deleteBoxFromDisk(name);
      }
      await settingsBox.delete('db_migration_initialized');
      await settingsBox.put('db_schema_version', _schemaVersion);
    }

    _instance = DatabaseProvider._(
      settingsBox: settingsBox,
      sync: await SyncStore.open(),
    );

    if (kDebugMode) {
      debugPrint('[DB] Hive opened on ${kIsWeb ? 'Web (IndexedDB)' : defaultTargetPlatform.name}');
    }
    return _instance!;
  }

  Future<void> dispose() async {
    await Hive.close();
    _instance = null;
  }
}
