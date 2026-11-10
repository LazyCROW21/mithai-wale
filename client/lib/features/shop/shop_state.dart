import 'package:flutter/foundation.dart' hide Category;

import '../../core/database/models/category_model.dart';
import '../../core/database/models/menu_item_model.dart';

@immutable
class ShopState {
  const ShopState({
    this.items = const [],
    this.categories = const [],
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.selectedNavIndex = 1,
    this.isLoading = false,
  });

  final List<MenuItem> items;
  final List<Category> categories;
  final String selectedCategory;
  final String searchQuery;
  final int selectedNavIndex;
  final bool isLoading;

  /// Returns only available products filtered by selected category and search query.
  List<MenuItem> get availableProducts {
    return items.where((item) {
      if (!item.isAvailable) return false;

      // Category filter
      if (selectedCategory != 'All') {
        final category = categories.where((c) => c.id == item.categoryId).firstOrNull;
        if (category == null || category.name.toLowerCase() != selectedCategory.toLowerCase()) {
          return false;
        }
      }

      // Search filter
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final matchesTitle = item.title.toLowerCase().contains(query);
        final matchesDesc = item.description?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesDesc) return false;
      }

      return true;
    }).toList();
  }

  /// Helper to get the category for a specific menu item.
  Category? getCategoryFor(MenuItem item) {
    if (item.categoryId == null) return null;
    return categories.where((c) => c.id == item.categoryId).firstOrNull;
  }

  ShopState copyWith({
    List<MenuItem>? items,
    List<Category>? categories,
    String? selectedCategory,
    String? searchQuery,
    int? selectedNavIndex,
    bool? isLoading,
  }) {
    return ShopState(
      items: items ?? this.items,
      categories: categories ?? this.categories,
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
          listEquals(items, other.items) &&
          listEquals(categories, other.categories) &&
          selectedCategory == other.selectedCategory &&
          searchQuery == other.searchQuery &&
          selectedNavIndex == other.selectedNavIndex &&
          isLoading == other.isLoading;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(items),
        Object.hashAll(categories),
        selectedCategory,
        searchQuery,
        selectedNavIndex,
        isLoading,
      );
}
