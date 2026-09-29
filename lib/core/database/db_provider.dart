/// Singleton database provider for the mithai_wale app using Hive.
library;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'repositories/cart_repository.dart';
import 'repositories/category_repository.dart';
import 'repositories/hive_cart_repository.dart';
import 'repositories/hive_category_repository.dart';
import 'repositories/hive_menu_repository.dart';
import 'repositories/hive_orders_repository.dart';
import 'repositories/hive_payments_repository.dart';
import 'repositories/hive_settings_repository.dart';
import 'repositories/menu_repository.dart';
import 'repositories/orders_repository.dart';
import 'repositories/payments_repository.dart';
import 'repositories/settings_repository.dart';

/// Central access point for all database repositories (Hive-backed).
class DatabaseProvider {
  DatabaseProvider._({
    required Box<String> settingsBox,
    required Box<Map> categoriesBox,
    required Box<Map> menuBox,
    required Box<Map> cartBox,
    required Box<Map> ordersBox,
    required Box<Map> paymentsBox,
  }) : settings = HiveSettingsRepository(settingsBox),
       categories = HiveCategoryRepository(categoriesBox),
       menu = HiveMenuRepository(menuBox),
       cart = HiveCartRepository(cartBox),
       orders = HiveOrdersRepository(ordersBox),
       payments = HivePaymentsRepository(paymentsBox);

  // ── Repositories ────────────────────────────────────────────────────────────

  /// Key-value settings repository.
  final ISettingsRepository settings;

  /// Category management repository.
  final ICategoryRepository categories;

  /// Menu items management repository.
  final IMenuRepository menu;

  /// Shopping cart persistence repository.
  final ICartRepository cart;

  /// Orders management repository.
  final IOrdersRepository orders;

  /// Payments ledger repository.
  final IPaymentsRepository payments;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  static DatabaseProvider? _instance;

  /// Returns the initialised [DatabaseProvider].
  static DatabaseProvider get instance {
    assert(
      _instance != null,
      'DatabaseProvider.init() must be called before accessing DatabaseProvider.instance.',
    );
    return _instance!;
  }

  /// Initialises Hive and all boxes and repositories.
  static Future<DatabaseProvider> init() async {
    if (_instance != null) return _instance!;

    await Hive.initFlutter();

    final settingsBox = await Hive.openBox<String>('settings');
    final categoriesBox = await Hive.openBox<Map>('categories');
    final menuBox = await Hive.openBox<Map>('menu_items');
    final cartBox = await Hive.openBox<Map>('cart_items');
    final ordersBox = await Hive.openBox<Map>('orders');
    final paymentsBox = await Hive.openBox<Map>('payments');

    final provider = DatabaseProvider._(
      settingsBox: settingsBox,
      categoriesBox: categoriesBox,
      menuBox: menuBox,
      cartBox: cartBox,
      ordersBox: ordersBox,
      paymentsBox: paymentsBox,
    );

    await provider._runMigrations();

    _instance = provider;

    if (kDebugMode) {
      print('[DB] Hive database initialised on ${_platformName()}');
    }

    return _instance!;
  }

  /// Runs database migrations once on initial database creation.
  Future<void> _runMigrations() async {
    const migrationKey = 'db_migration_initialized';
    final isMigrated = await settings.get(migrationKey);

    // Clean up any legacy dummy demo orders
    final existingOrders = await orders.getAll();
    for (final o in existingOrders) {
      if (o.id == '#ORD-1001' || o.id == '#ORD-1002' || o.id == '#ORD-1003') {
        await orders.delete(o.id);
      }
    }

    // If migrations have already run once on DB creation, do not re-run.
    if (isMigrated == 'true') {
      return;
    }

    // 1. Seed default categories (without emoji)
    final existingCategories = await categories.getAll();
    if (existingCategories.isEmpty) {
      const defaultCategories = [
        'Ladoo',
        'Barfi',
        'Halwa',
        'Peda',
        'Rasgulla',
        'Jalebi',
      ];
      for (final name in defaultCategories) {
        await categories.add(name: name);
      }
    } else {
      // Clear emojis from existing categories if any were created earlier
      for (final cat in existingCategories) {
        if (cat.emoji != null) {
          await categories.update(cat.copyWith(emoji: null));
        }
      }
    }

    // 2. Seed default menu items
    final existingItems = await menu.getAll();
    if (existingItems.isEmpty) {
      final allCats = await categories.getAll();
      int? findCatId(String name) {
        try {
          return allCats
              .firstWhere((c) => c.name.toLowerCase() == name.toLowerCase())
              .id;
        } catch (_) {
          return null;
        }
      }

      final defaultItems = [
        (
          title: 'Motichoor Ladoo',
          price: 440.0,
          unit: 'kg',
          cat: 'Ladoo',
          desc: 'Melt-in-mouth tiny boondi spheres made with pure desi ghee',
        ),
        (
          title: 'Besan Ladoo',
          price: 400.0,
          unit: 'kg',
          cat: 'Ladoo',
          desc:
              'Aromatic roasted gram flour with desi ghee and crunchy dry fruits',
        ),
        (
          title: 'Kaju Katli',
          price: 950.0,
          unit: 'kg',
          cat: 'Barfi',
          desc: 'Classic diamond-shaped cashew fudge with silver leaf',
        ),
        (
          title: 'Pista Barfi',
          price: 650.0,
          unit: 'kg',
          cat: 'Barfi',
          desc: 'Rich milk fudge blended with premium pistachio pieces',
        ),
        (
          title: 'Gajar Halwa',
          price: 480.0,
          unit: 'kg',
          cat: 'Halwa',
          desc: 'Slow-cooked grated carrots, whole milk, mawa and cashew nuts',
        ),
        (
          title: 'Moong Dal Halwa',
          price: 520.0,
          unit: 'kg',
          cat: 'Halwa',
          desc: 'Traditional winter delicacy roasted in pure desi ghee',
        ),
        (
          title: 'Mathura Peda',
          price: 460.0,
          unit: 'kg',
          cat: 'Peda',
          desc: 'Caramelized khoya peda with cardamom aroma',
        ),
        (
          title: 'Kesar Peda',
          price: 500.0,
          unit: 'kg',
          cat: 'Peda',
          desc: 'Saffron-infused soft khoya peda with pistachio garnish',
        ),
        (
          title: 'Bengali Rasgulla',
          price: 320.0,
          unit: 'kg',
          cat: 'Rasgulla',
          desc: 'Spongy cottage cheese balls soaked in light sugar syrup',
        ),
        (
          title: 'Crispy Jalebi',
          price: 360.0,
          unit: 'kg',
          cat: 'Jalebi',
          desc: 'Golden spirals fried crispy and steeped in saffron syrup',
        ),
      ];

      for (final item in defaultItems) {
        await menu.add(
          title: item.title,
          description: item.desc,
          price: item.price,
          unit: item.unit,
          categoryId: findCatId(item.cat),
          isAvailable: true,
        );
      }
    }

    // Persist migration flag so this runs only once on DB creation
    await settings.set(migrationKey, 'true');
  }

  /// Disposes Hive boxes.
  Future<void> dispose() async {
    await Hive.close();
    _instance = null;
  }

  static String _platformName() {
    if (kIsWeb) return 'Web (IndexedDB via Hive)';
    return defaultTargetPlatform.name;
  }
}
