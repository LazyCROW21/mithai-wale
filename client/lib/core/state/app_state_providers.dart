/// Global (app-level) Riverpod providers.
///
/// These providers are **not** feature-specific — they represent cross-cutting
/// app state such as theme, locale, and auth status.
///
/// Feature-specific providers live in `lib/features/<x>/<x>_providers.dart`.
///
/// ### Dependency on get_it
/// Global providers that need services pull them from [sl] so that
/// [ProviderScope] does not need to be aware of concrete implementations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/repositories/settings_repository.dart';
import '../di/service_locator.dart';

// ── Theme ─────────────────────────────────────────────────────────────────────

/// Manages the app-wide [ThemeMode] and persists it via [ISettingsRepository].
///
/// ```dart
/// // Read
/// final mode = ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;
///
/// // Write (from a settings screen)
/// ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
/// ```
class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  Future<ThemeMode> build() async {
    final repo = sl<ISettingsRepository>();
    final stored = await repo.get(_key);
    return _parse(stored);
  }

  /// Persists [mode] and updates the reactive state.
  Future<void> setThemeMode(ThemeMode mode) async {
    final repo = sl<ISettingsRepository>();
    await repo.set(_key, mode.name);
    state = AsyncData(mode);
  }

  static ThemeMode _parse(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

/// App-wide theme mode provider.
/// Returns [AsyncValue<ThemeMode>] — handle loading/error states in the root widget.
final themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// ── Locale ────────────────────────────────────────────────────────────────────

/// Manages the app-wide [Locale] and persists it via [ISettingsRepository].
///
/// Supported locales:
/// - `Locale('en')` — English
/// - `Locale('gu')` — Gujarati
/// - `null`          — System / device default
class LocaleNotifier extends AsyncNotifier<Locale?> {
  static const _key = 'app_locale';

  @override
  Future<Locale?> build() async {
    final repo = sl<ISettingsRepository>();
    final stored = await repo.get(_key);
    return _parse(stored);
  }

  /// Persists [locale] and updates the reactive state.
  /// Pass `null` to reset to system default.
  Future<void> setLocale(Locale? locale) async {
    final repo = sl<ISettingsRepository>();
    if (locale == null) {
      await repo.remove(_key);
      state = const AsyncData(null);
    } else {
      await repo.set(_key, locale.languageCode);
      state = AsyncData(locale);
    }
  }

  static Locale? _parse(String? value) => switch (value) {
        'en' => const Locale('en'),
        'gu' => const Locale('gu'),
        _ => null,
      };
}

/// App-wide locale provider.
/// Returns [AsyncValue<Locale?>] — `null` indicates device default.
final localeProvider =
    AsyncNotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

// ── Auth (placeholder) ────────────────────────────────────────────────────────

/// Placeholder for the authenticated user ID.
/// Replace with a real [AsyncNotifier] once auth is implemented.
final currentUserIdProvider = StateProvider<String?>((ref) => null);
