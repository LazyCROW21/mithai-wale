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

import '../../features/orders/printing/order_print_service.dart';
import '../auth/auth_notifier.dart';
import '../database/db_provider.dart';
import '../printing/document_output.dart';
import '../printing/pdf_renderer.dart';
import '../printing/print_profile_repository.dart';
import '../sync/sync_store.dart';
import '../database/repositories/category_repository.dart';
import '../database/repositories/menu_repository.dart';
import '../database/repositories/inventory_repository.dart';
import '../database/repositories/orders_repository.dart';
import '../database/repositories/payments_repository.dart';
import '../database/repositories/settings_repository.dart';

/// Global service locator instance.
/// Use `sl<T>()` as shorthand for `GetIt.instance<T>()`.
final GetIt sl = GetIt.instance;

/// Registers all application-level dependencies.
Future<void> setupServiceLocator() async {
  // ── Repositories ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<ISettingsRepository>(
    () => DatabaseProvider.instance.settings,
  );
  sl.registerLazySingleton<ICategoryRepository>(
    () => DatabaseProvider.instance.categories,
  );
  sl.registerLazySingleton<IMenuRepository>(
    () => DatabaseProvider.instance.menu,
  );
  sl.registerLazySingleton<IOrdersRepository>(
    () => DatabaseProvider.instance.orders,
  );
  sl.registerLazySingleton<IPaymentsRepository>(
    () => DatabaseProvider.instance.payments,
  );

  sl.registerLazySingleton<InventoryRepository>(
    () => DatabaseProvider.instance.inventory,
  );
  sl.registerLazySingleton<SyncStore>(() => DatabaseProvider.instance.sync);

  // ── Printing ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<IPrintProfileRepository>(
    () => ApiPrintProfileRepository(appAuth.api, () => appAuth.current.session?.ownerKey),
  );
  sl.registerLazySingleton<PdfRenderer>(() => PdfRenderer());
  sl.registerLazySingleton<IDocumentOutput>(() => const PrintingDocumentOutput());
  sl.registerLazySingleton<OrderPrintService>(
    () => OrderPrintService(
      payments: sl<IPaymentsRepository>(),
      profiles: sl<IPrintProfileRepository>(),
      session: () => appAuth.current.session,
    ),
  );

  // ── Services ──────────────────────────────────────────────────────────────
  // sl.registerLazySingleton<AuthService>(() => AuthService());

  // ── ViewModels ────────────────────────────────────────────────────────────
  // Note: Riverpod providers manage ViewModel lifecycle for UI-bound state.
  // Register here only for ViewModels that need DI but are NOT Riverpod-managed.
}
