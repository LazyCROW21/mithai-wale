/// Immutable state for the Home feature.
///
/// All fields have sensible defaults so [HomeState()] is a valid initial state.
/// Use [copyWith] to produce a new state with selective field overrides.
///
/// ### Why plain Dart (no freezed)?
/// Plain `copyWith` + manual `==` is sufficient here and avoids code generation.
/// If the class grows complex, migrate to `freezed`.
library;

/// Immutable state snapshot for the Home feature screens.
class HomeState {
  const HomeState({
    this.selectedNavIndex = 0,
    this.selectedCategory = 'All',
    this.isLoading = false,
  });

  /// Currently active navigation destination index (0 = Home, 1 = Shop, etc.).
  final int selectedNavIndex;

  /// Active product category filter.
  final String selectedCategory;

  /// `true` while an async operation is in progress.
  final bool isLoading;

  /// Returns a copy of this state with the provided fields replaced.
  HomeState copyWith({
    int? selectedNavIndex,
    String? selectedCategory,
    bool? isLoading,
  }) {
    return HomeState(
      selectedNavIndex: selectedNavIndex ?? this.selectedNavIndex,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeState &&
          runtimeType == other.runtimeType &&
          selectedNavIndex == other.selectedNavIndex &&
          selectedCategory == other.selectedCategory &&
          isLoading == other.isLoading;

  @override
  int get hashCode =>
      selectedNavIndex.hashCode ^ selectedCategory.hashCode ^ isLoading.hashCode;

  @override
  String toString() =>
      'HomeState(selectedNavIndex: $selectedNavIndex, selectedCategory: $selectedCategory, isLoading: $isLoading)';
}
