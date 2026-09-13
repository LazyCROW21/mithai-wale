---
name: responsive-layout
description: >
  Pattern guide for adding responsive layouts (Mobile / Tablet / Desktop)
  and the cross-platform local database abstraction layer to the mithai_wale
  Flutter project. Read this skill before adding any new screen, feature, or
  database table.
---

# Responsive Layout + Local DB — Skill Guide

## 1. Layout System Overview

All screens in **mithai_wale** must support three layout tiers:

| Tier    | Min Width | Max Width | Nav Pattern          |
|---------|-----------|-----------|----------------------|
| Mobile  | 0 dp      | 599 dp    | Bottom nav bar       |
| Tablet  | 600 dp    | 1023 dp   | Navigation Rail      |
| Desktop | 1024 dp   | ∞         | Persistent Drawer    |

Breakpoints live in [`lib/core/layout/breakpoints.dart`](../../../../lib/core/layout/breakpoints.dart).  
**Do not hard-code widths anywhere else — always use `AppBreakpoints` constants.**

---

## 2. Adding a New Responsive Screen

### Step 1 — Create the feature directory

```
lib/features/<feature_name>/
├── <feature_name>_page.dart        ← thin orchestrator
└── views/
    ├── <feature_name>_mobile_view.dart
    ├── <feature_name>_tablet_view.dart
    └── <feature_name>_desktop_view.dart
```

**Naming convention**: Replace `<feature_name>` with the CamelCase feature name.  
Example for a "Products" feature: `ProductsMobileView`, `ProductsTabletView`, `ProductsDesktopView`.

### Step 2 — Create the page orchestrator

```dart
// lib/features/products/products_page.dart
import 'package:flutter/material.dart';
import 'package:mithai_wale/core/layout/responsive_layout.dart';
import 'views/products_desktop_view.dart';
import 'views/products_mobile_view.dart';
import 'views/products_tablet_view.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile:  ProductsMobileView(),
      tablet:  ProductsTabletView(),
      desktop: ProductsDesktopView(),
    );
  }
}
```

> **Rule**: The page file contains **zero** layout logic. It only wires views.

### Step 3 — Implement each view

Each view is an independent `StatefulWidget` (or `StatelessWidget`) that owns its layout. They may share sub-widgets by extracting them to a shared file, e.g., `_product_card.dart`.

```dart
// lib/features/products/views/products_mobile_view.dart
class ProductsMobileView extends StatelessWidget {
  const ProductsMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    // Mobile-first: single column, bottom nav, etc.
  }
}
```

### Step 4 — Use context extensions for inline checks

When a small widget (not a full view) needs to adapt slightly:

```dart
import 'package:mithai_wale/core/layout/layout_extensions.dart';

Widget build(BuildContext context) {
  final padding = context.isMobile ? 8.0 : 24.0;
  return Padding(padding: EdgeInsets.all(padding), child: ...);
}
```

Available extensions on `BuildContext`:

| Extension        | Type         | Description                        |
|------------------|--------------|------------------------------------|
| `deviceType`     | `DeviceType` | Resolved layout tier enum          |
| `isMobile`       | `bool`       | `true` when `width < 600`          |
| `isTablet`       | `bool`       | `true` when `600 ≤ width < 1024`   |
| `isDesktop`      | `bool`       | `true` when `width ≥ 1024`         |
| `screenWidth`    | `double`     | Current screen width in dp         |
| `screenHeight`   | `double`     | Current screen height in dp        |

---

## 3. Local Database Layer

### Architecture

```
AppDatabase (drift schema)
    │
    ├── connection_native.dart  ← Android, iOS, Windows (SQLite via FFI)
    └── connection_web.dart     ← Web (WASM / OPFS)
           ↕ (selected by conditional import in app_database.dart)

ISettingsRepository (abstract interface)
    └── DriftSettingsRepository (concrete drift impl)
           ↑
    DatabaseProvider.instance.settings   ← use this in UI/services
```

**Key rule**: Business logic and UI must depend on the **abstract interface** (`ISettingsRepository`), never on `DriftSettingsRepository` or `AppDatabase` directly.

### Adding a New Table

#### Step 1 — Define the table class in `app_database.dart`

```dart
class ProductsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 256)();
  IntColumn get priceInPaisa => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### Step 2 — Register the table in `@DriftDatabase`

```dart
@DriftDatabase(tables: [SettingsTable, ProductsTable])   // ← add here
class AppDatabase extends _$AppDatabase { ... }
```

#### Step 3 — Bump the schema version and add a migration

```dart
@override
int get schemaVersion => 2;   // ← increment

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 2) await m.createTable(productsTable);
  },
);
```

#### Step 4 — Regenerate code

```bash
dart run build_runner build --delete-conflicting-outputs
```

#### Step 5 — Create abstract interface

```dart
// lib/core/database/repositories/products_repository.dart
abstract interface class IProductsRepository {
  Future<List<ProductEntry>> getAll();
  Future<void> add(ProductEntry product);
  Future<void> delete(int id);
  Stream<List<ProductEntry>> watch();
}
```

#### Step 6 — Create drift implementation

```dart
// lib/core/database/repositories/drift_products_repository.dart
class DriftProductsRepository implements IProductsRepository {
  const DriftProductsRepository(this._db);
  final AppDatabase _db;
  // implement using _db.select(_db.productsTable) etc.
}
```

#### Step 7 — Expose via `DatabaseProvider`

```dart
// In DatabaseProvider
final IProductsRepository products;

DatabaseProvider._({required AppDatabase database})
    : _database = database,
      settings = DriftSettingsRepository(database),
      products = DriftProductsRepository(database);   // ← add
```

### Using the Database in a Widget

```dart
// Read once
final theme = await DatabaseProvider.instance.settings.get('theme_mode');

// Reactive (StreamBuilder)
StreamBuilder<String?>(
  stream: DatabaseProvider.instance.settings.watch('theme_mode'),
  builder: (context, snapshot) {
    final mode = snapshot.data ?? 'system';
    return Text('Theme: $mode');
  },
);

// Write
await DatabaseProvider.instance.settings.set('theme_mode', 'dark');
```

---

## 4. Platform-Specific DB Notes

| Platform | Driver | Storage Location |
|----------|--------|-----------------|
| Android  | `NativeDatabase` (sqlite3_flutter_libs) | `/data/user/0/<pkg>/databases/mithai_wale.sqlite` |
| iOS      | `NativeDatabase` (sqlite3_flutter_libs) | `<app docs>/mithai_wale.sqlite` |
| Windows  | `NativeDatabase` (sqlite3_flutter_libs) | `%APPDATA%\mithai_wale\mithai_wale.sqlite` |
| Web      | `WasmDatabase` (OPFS) | Browser Origin Private File System |

### Web Setup (one-time)
1. Copy `sqlite3.wasm` from the `sqlite3` package to `web/`
2. Copy `drift_worker.js` from the `drift` package to `web/`
3. These files are already referenced in `connection_web.dart`

---

## 5. File Checklist for a New Feature

> **Also read the `mvvm-routing` skill** for the full MVVM + routing + DI checklist.

```
✅ lib/features/<x>/<x>_page.dart              (uses ResponsiveLayout)
✅ lib/features/<x>/<x>_state.dart             (immutable state class)
✅ lib/features/<x>/<x>_viewmodel.dart         (Notifier<XState>)
✅ lib/features/<x>/<x>_providers.dart         (NotifierProvider)
✅ lib/features/<x>/views/<x>_mobile_view.dart  (ConsumerWidget)
✅ lib/features/<x>/views/<x>_tablet_view.dart  (ConsumerWidget)
✅ lib/features/<x>/views/<x>_desktop_view.dart (ConsumerWidget)
✅ lib/core/routing/routes.dart                (path + name constants)
✅ lib/core/routing/app_router.dart            (GoRoute entry)
✅ lib/core/database/repositories/<x>_repository.dart     (interface, if DB needed)
✅ lib/core/database/repositories/drift_<x>_repository.dart (impl, if DB needed)
✅ lib/core/di/service_locator.dart            (register repo/service if DB needed)
```

