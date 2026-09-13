import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/db_provider.dart';
import 'core/di/service_locator.dart';
import 'core/routing/app_router.dart';
import 'core/state/app_state_providers.dart';

/// App entry point.
///
/// Startup order:
/// 1. [WidgetsFlutterBinding.ensureInitialized] — required for async main
/// 2. [DatabaseProvider.init]   — opens platform-specific SQLite / WASM DB
/// 3. [setupServiceLocator]     — registers get_it singletons / factories
/// 4. [ProviderScope]           — mounts the Riverpod container
/// 5. [MaterialApp.router]      — hooks in the GoRouter
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Database — must come before service locator (repos depend on it)
  await DatabaseProvider.init();

  // 2. Dependency injection
  await setupServiceLocator();

  runApp(
    // 3. Riverpod — wraps the entire widget tree
    const ProviderScope(
      child: MithaiWaleApp(),
    ),
  );
}

/// Root application widget.
///
/// Watches [themeModeProvider] so the entire app re-themes reactively when
/// the user changes the theme preference from Settings.
class MithaiWaleApp extends ConsumerWidget {
  const MithaiWaleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AsyncValue — handle loading and error states gracefully
    final themeAsync = ref.watch(themeModeProvider);
    final themeMode = themeAsync.valueOrNull ?? ThemeMode.system;

    return MaterialApp.router(
      title: 'मिठाई वाले',
      debugShowCheckedModeBanner: false,

      // ── GoRouter ──────────────────────────────────────────────
      routerConfig: appRouter,

      // ── Theming ────────────────────────────────────────────────
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4830A), // Warm saffron
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4830A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,
    );
  }
}
