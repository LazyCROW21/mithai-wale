/// ViewModel for the Home feature.
///
/// Encapsulates all business logic for the Home screens. The three views
/// (mobile / tablet / desktop) share this single ViewModel — they read the
/// same [HomeState] and call the same methods, but render it differently.
///
/// ### Riverpod pattern used: [Notifier]
/// [Notifier] is the modern (generator-free) replacement for [StateNotifier].
/// Use [AsyncNotifier] instead if [build] needs to perform async work
/// (e.g., fetching products from an API).
///
/// ### Accessing services
/// Pull get_it-registered services via [sl] in [build] or methods:
/// ```dart
/// final _repo = sl<IProductsRepository>();
/// ```
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_state.dart';

/// Business logic layer for the Home feature.
///
/// Consumed by [homeViewModelProvider] — never instantiate directly.
class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() {
    // Return the initial state. Pull any required services from sl<T>() here.
    return const HomeState();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  /// Switches the active nav destination to [index].
  void selectNavItem(int index) {
    if (state.selectedNavIndex == index) return;
    state = state.copyWith(selectedNavIndex: index);
  }

  // ── Category filter ────────────────────────────────────────────────────────

  /// Applies [category] as the active product filter.
  void selectCategory(String category) {
    if (state.selectedCategory == category) return;
    state = state.copyWith(selectedCategory: category);
  }

  /// Resets the category filter to show all products.
  void clearCategory() => selectCategory('All');

  // ── Async example ──────────────────────────────────────────────────────────
  // If you need async work, convert to AsyncNotifier<HomeState> and use
  // `state = AsyncLoading()` / `state = AsyncData(newState)` / `state = AsyncError(e, st)`.
}
