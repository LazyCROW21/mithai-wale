/// Dependency injection setup using [GetIt].
///
/// Call [setupServiceLocator] once in [main] **before** [runApp].
///
/// ### Access pattern
/// ```dart
/// import 'package:mithai_wale/core/di/service_locator.dart';
///
/// final repo = sl<ISettingsRepository>();
/// ```
///
/// ### Registration rules
/// | Kind              | Registration      | Why                              |
/// |-------------------|-------------------|----------------------------------|
/// | Repository/Service| `lazySingleton`   | Shared state, single connection  |
/// | ViewModel         | `factory`         | Fresh instance per screen        |
/// | API Client        | `singleton`       | Expensive to create              |
library;

import 'package:get_it/get_it.dart';

import '../database/db_provider.dart';
import '../database/repositories/settings_repository.dart';

/// Global service locator instance.
/// Use `sl<T>()` as shorthand for `GetIt.instance<T>()`.
final GetIt sl = GetIt.instance;

/// Registers all application-level dependencies.
///
/// Repositories are registered as [lazySingleton] — created on first access
/// and reused thereafter. This keeps startup fast.
///
/// Add new registrations in the section that matches the dependency kind:
///
/// ```dart
/// // Repositories
/// sl.registerLazySingleton<IProductsRepository>(() => DriftProductsRepository(sl()));
///
/// // Services
/// sl.registerLazySingleton<AuthService>(() => AuthService(sl()));
///
/// // ViewModels (factories — new instance per feature mount)
/// sl.registerFactory<ProductsViewModel>(() => ProductsViewModel(sl(), sl()));
/// ```
Future<void> setupServiceLocator() async {
  // ── Repositories ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<ISettingsRepository>(
    () => DatabaseProvider.instance.settings,
  );

  // ── Services ──────────────────────────────────────────────────────────────
  // sl.registerLazySingleton<AuthService>(() => AuthService());

  // ── ViewModels ────────────────────────────────────────────────────────────
  // Note: Riverpod providers manage ViewModel lifecycle for UI-bound state.
  // Register here only for ViewModels that need DI but are NOT Riverpod-managed.
}
