import 'package:flutter/foundation.dart';

@immutable
class ShopState {
  const ShopState({
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.selectedNavIndex = 1,
    this.isLoading = false,
  });

  final String selectedCategory;
  final String searchQuery;
  final int selectedNavIndex;
  final bool isLoading;

  ShopState copyWith({
    String? selectedCategory,
    String? searchQuery,
    int? selectedNavIndex,
    bool? isLoading,
  }) {
    return ShopState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedNavIndex: selectedNavIndex ?? this.selectedNavIndex,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopState &&
          selectedCategory == other.selectedCategory &&
          searchQuery == other.searchQuery &&
          selectedNavIndex == other.selectedNavIndex &&
          isLoading == other.isLoading;

  @override
  int get hashCode => Object.hash(selectedCategory, searchQuery, selectedNavIndex, isLoading);
}
