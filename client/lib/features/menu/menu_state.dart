import 'package:flutter/foundation.dart' hide Category;

import '../../core/database/models/category_model.dart';
import '../../core/database/models/menu_item_model.dart';

@immutable
class MenuState {
  const MenuState({
    this.items = const [],
    this.categories = const [],
    this.selectedCategoryFilter = 'All',
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  final List<MenuItem> items;
  final List<Category> categories;
  final String selectedCategoryFilter;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  List<MenuItem> get filteredItems {
    return items.where((item) {
      final matchesSearch = searchQuery.isEmpty ||
          item.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (item.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);

      if (selectedCategoryFilter == 'All') {
        return matchesSearch;
      }

      final Category? category = categories.cast<Category?>().firstWhere(
        (c) => c?.id == item.categoryId,
        orElse: () => null,
      );

      final matchesCategory = category?.name.toLowerCase() == selectedCategoryFilter.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  MenuState copyWith({
    List<MenuItem>? items,
    List<Category>? categories,
    String? selectedCategoryFilter,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return MenuState(
      items: items ?? this.items,
      categories: categories ?? this.categories,
      selectedCategoryFilter: selectedCategoryFilter ?? this.selectedCategoryFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuState &&
          listEquals(items, other.items) &&
          listEquals(categories, other.categories) &&
          selectedCategoryFilter == other.selectedCategoryFilter &&
          searchQuery == other.searchQuery &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode =>
      Object.hash(items, categories, selectedCategoryFilter, searchQuery, isLoading, error);
}
