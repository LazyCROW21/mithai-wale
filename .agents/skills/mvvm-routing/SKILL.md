---
name: mvvm-routing
description: >
  Pattern guide for MVVM architecture (Riverpod), routing (go_router), and
  dependency injection (get_it) in the mithai_wale Flutter project.
  Read this skill before adding any new feature, route, service, or ViewModel.
---

# MVVM + Routing + DI — Skill Guide

## 1. Architecture Overview

```
                         ┌──────────────┐
                         │  main.dart   │
                         │  (entry pt.) │
                         └──────┬───────┘
              ┌─────────────────┼──────────────────┐
              ▼                 ▼                  ▼
     DatabaseProvider    setupServiceLocator   ProviderScope
     (drift / SQLite)    (get_it singletons)  (Riverpod root)
                                │
                                ▼
                          MaterialApp.router
                          (GoRouter / appRouter)
```

### Three-layer rule
| Layer | Tool | Responsibility |
|-------|------|---------------|
| **State** | Riverpod `Notifier` | UI state, user actions |
| **Services / Repos** | get_it `lazySingleton` | Data access, business services |
| **Navigation** | go_router + `AppNav` | Routing between screens and modals |

---

## 2. MVVM File Structure

Every feature follows the same 6-file pattern:

```
lib/features/<feature>/
├── <feature>_page.dart         ← thin orchestrator (uses ResponsiveLayout)
├── <feature>_state.dart        ← immutable state class with copyWith + ==
├── <feature>_viewmodel.dart    ← Notifier<XState> with all business logic
├── <feature>_providers.dart    ← NotifierProvider declarations
└── views/
    ├── <feature>_mobile_view.dart   ← ConsumerWidget
    ├── <feature>_tablet_view.dart   ← ConsumerWidget
    └── <feature>_desktop_view.dart  ← ConsumerWidget
```

### Naming convention
| Class kind | Pattern | Example |
|------------|---------|---------|
| State | `XState` | `HomeState` |
| ViewModel | `XViewModel` | `HomeViewModel` |
| Provider file | `x_providers.dart` | `home_providers.dart` |
| Page | `XPage` | `HomePage` |
| Views | `XMobileView`, `XTabletView`, `XDesktopView` | `HomeMobileView` |

---

## 3. Adding a New Feature (Step-by-Step)

### Step 1 — State class (`x_state.dart`)
```dart
class ProductsState {
  const ProductsState({this.items = const [], this.isLoading = false});

  final List<Product> items;
  final bool isLoading;

  ProductsState copyWith({List<Product>? items, bool? isLoading}) => ProductsState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
  );

  @override
  bool operator ==(Object other) => identical(this, other) ||
      other is ProductsState && items == other.items && isLoading == other.isLoading;

  @override
  int get hashCode => items.hashCode ^ isLoading.hashCode;
}
```

### Step 2 — ViewModel (`x_viewmodel.dart`)
```dart
class ProductsViewModel extends Notifier<ProductsState> {
  // Pull services from get_it
  late final _repo = sl<IProductsRepository>();

  @override
  ProductsState build() => const ProductsState();

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _repo.getAll();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void selectItem(Product item) { /* ... */ }
}
```

> Use `AsyncNotifier<XState>` instead of `Notifier<XState>` when `build()` itself
> is asynchronous (e.g., fetches data on first mount).

### Step 3 — Providers (`x_providers.dart`)
```dart
final productsViewModelProvider =
    NotifierProvider<ProductsViewModel, ProductsState>(ProductsViewModel.new);
```

### Step 4 — Page orchestrator (`x_page.dart`)
```dart
class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) => const ResponsiveLayout(
    mobile:  ProductsMobileView(),
    tablet:  ProductsTabletView(),
    desktop: ProductsDesktopView(),
  );
}
```

### Step 5 — Views (`views/x_<tier>_view.dart`)
```dart
class ProductsMobileView extends ConsumerWidget {
  const ProductsMobileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Selective rebuild — only re-renders when isLoading changes
    final isLoading = ref.watch(productsViewModelProvider.select((s) => s.isLoading));
    final items     = ref.watch(productsViewModelProvider.select((s) => s.items));
    final vm        = ref.read(productsViewModelProvider.notifier);

    return Scaffold(/* ... */);
  }
}
```

> Use `ref.watch(provider.select((s) => s.field))` to avoid full rebuilds.
> Use `ref.read(provider.notifier)` to call ViewModel methods (never in `build`).

---

## 4. Routing

### Adding a new screen route
1. Add path + name constants to [`routes.dart`](../../../../lib/core/routing/routes.dart):
```dart
static const products = '/products';
// in AppRouteNames:
static const products = 'products';
```

2. Add a `GoRoute` to [`app_router.dart`](../../../../lib/core/routing/app_router.dart):
```dart
GoRoute(
  path: AppRoutes.products,
  name: AppRouteNames.products,
  builder: (context, state) => const ProductsPage(),
),
```

3. Navigate (context-free, anywhere in the app):
```dart
AppNav.go(AppRoutes.products);
AppNav.pushNamed(AppRouteNames.products);
```

### Adding a modal bottom sheet route
Path **must** end with `/sheet` (convention):
```dart
// routes.dart
static const productDetail = '/product/:id/sheet';
static String productDetailPath(String id) => '/product/$id/sheet';

// app_router.dart
GoRoute(
  path: AppRoutes.productDetail,
  name: AppRouteNames.productDetail,
  pageBuilder: (context, state) => ModalBottomSheetPage(
    key: state.pageKey,
    child: ProductDetailSheet(id: state.pathParameters['id']!),
  ),
),

// Call it
AppNav.push(AppRoutes.productDetailPath('42'));
```

### Adding a dialog route
Path **must** end with `/dialog` (convention):
```dart
pageBuilder: (context, state) => AppDialogPage(
  key: state.pageKey,
  child: const MyDialog(),
),
```

### Context-free navigation — `AppNav`
| Method | Use case |
|--------|---------|
| `AppNav.go(path)` | Replace entire stack |
| `AppNav.push(path)` | Push, can pop back |
| `AppNav.pushNamed(name, pathParameters: {})` | Named navigation |
| `AppNav.pop()` | Dismiss top route |
| `AppNav.showProductDetail(id)` | Open product sheet |
| `AppNav.showAddToCart()` | Open add-to-cart sheet |

---

## 5. Dependency Injection (get_it)

### Accessing a service
```dart
import 'package:mithai_wale/core/di/service_locator.dart';

final repo = sl<ISettingsRepository>();
```

### Registering a new service
Add to `setupServiceLocator()` in [`service_locator.dart`](../../../../lib/core/di/service_locator.dart):

```dart
// Repository (shared, single instance)
sl.registerLazySingleton<IProductsRepository>(
  () => DriftProductsRepository(DatabaseProvider.instance._database),
);

// Service (shared)
sl.registerLazySingleton<NotificationService>(() => NotificationService());

// ViewModel (fresh per mount — rare; prefer Riverpod for UI-bound VMs)
sl.registerFactory<CheckoutViewModel>(() => CheckoutViewModel(sl(), sl()));
```

### Registration cheat-sheet
| Registration | When to use |
|-------------|-------------|
| `registerSingleton` | Created immediately at startup |
| `registerLazySingleton` | Created on first access (preferred for repos) |
| `registerFactory` | Fresh instance each call |
| `registerFactoryParam` | Factory with a runtime parameter |

---

## 6. Global vs. Local Providers

| Scenario | Use |
|----------|-----|
| App-wide (theme, auth, locale) | `lib/core/state/app_state_providers.dart` |
| Feature-specific UI state | `lib/features/<x>/<x>_providers.dart` |
| State that multiple features share | Core state, or pass via router `extra` |
| Derived / computed state | `Provider((ref) => ref.watch(...).someField)` |

---

## 7. File Checklist for a New Feature

```
✅ lib/features/<x>/<x>_page.dart              (ResponsiveLayout orchestrator)
✅ lib/features/<x>/<x>_state.dart             (HomeState pattern)
✅ lib/features/<x>/<x>_viewmodel.dart         (Notifier<XState>)
✅ lib/features/<x>/<x>_providers.dart         (NotifierProvider)
✅ lib/features/<x>/views/<x>_mobile_view.dart  (ConsumerWidget)
✅ lib/features/<x>/views/<x>_tablet_view.dart  (ConsumerWidget)
✅ lib/features/<x>/views/<x>_desktop_view.dart (ConsumerWidget)
✅ lib/core/routing/routes.dart                (add path + name constants)
✅ lib/core/routing/app_router.dart            (add GoRoute)
✅ lib/core/di/service_locator.dart            (register service if needed)
```
