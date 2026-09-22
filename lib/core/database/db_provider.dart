/// Singleton database provider for the mithai_wale app using Hive.
library;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'repositories/category_repository.dart';
import 'repositories/hive_category_repository.dart';
import 'repositories/hive_menu_repository.dart';
import 'repositories/hive_settings_repository.dart';
import 'repositories/menu_repository.dart';
import 'repositories/settings_repository.dart';

/// Central access point for all database repositories (Hive-backed).
class DatabaseProvider {
  DatabaseProvider._({
    required Box<String> settingsBox,
    required Box<Map> categoriesBox,
    required Box<Map> menuBox,
  })  : settings = HiveSettingsRepository(settingsBox),
        categories = HiveCategoryRepository(categoriesBox),
        menu = HiveMenuRepository(menuBox);

  // ── Repositories ────────────────────────────────────────────────────────────

  /// Key-value settings repository.
  final ISettingsRepository settings;

  /// Category management repository.
  final ICategoryRepository categories;

  /// Menu items management repository.
  final IMenuRepository menu;

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

    final provider = DatabaseProvider._(
      settingsBox: settingsBox,
      categoriesBox: categoriesBox,
      menuBox: menuBox,
    );

    await provider._seedDefaults();

    _instance = provider;

    if (kDebugMode) {
      print('[DB] Hive database initialised on ${_platformName()}');
    }

    return _instance!;
  }

  Future<void> _seedDefaults() async {
    final existingCategories = await categories.getAll();
    if (existingCategories.isEmpty) {
      final defaultCategories = [
        (name: 'Ladoo', emoji: '🟡'),
        (name: 'Barfi', emoji: '🍬'),
        (name: 'Halwa', emoji: '🍮'),
        (name: 'Peda', emoji: '🟤'),
        (name: 'Rasgulla', emoji: '⚪'),
        (name: 'Jalebi', emoji: '🌀'),
      ];
      for (final cat in defaultCategories) {
        await categories.add(name: cat.name, emoji: cat.emoji);
      }
    }
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
