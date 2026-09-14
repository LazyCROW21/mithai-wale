import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/repositories/category_repository.dart';
import '../../core/database/repositories/menu_repository.dart';
import '../../core/di/service_locator.dart';
import 'menu_state.dart';

class MenuViewModel extends Notifier<MenuState> {
  late final _menuRepo = sl<IMenuRepository>();
  late final _categoryRepo = sl<ICategoryRepository>();

  StreamSubscription<List<MenuItem>>? _itemsSub;
  StreamSubscription<List<Category>>? _categoriesSub;

  @override
  MenuState build() {
    _listenToStreams();
    ref.onDispose(() {
      _itemsSub?.cancel();
      _categoriesSub?.cancel();
    });
    return const MenuState(isLoading: true);
  }

  void _listenToStreams() {
    _categoriesSub = _categoryRepo.watchAll().listen((categories) {
      state = state.copyWith(categories: categories, isLoading: false);
    }, onError: (err) {
      state = state.copyWith(error: err.toString(), isLoading: false);
    });

    _itemsSub = _menuRepo.watchAll().listen((items) {
      state = state.copyWith(items: items, isLoading: false);
    }, onError: (err) {
      state = state.copyWith(error: err.toString(), isLoading: false);
    });
  }

  void setCategoryFilter(String categoryName) {
    state = state.copyWith(selectedCategoryFilter: categoryName);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> addMenuItem({
    required String title,
    String? description,
    int? categoryId,
    required double price,
    required String unit,
    bool isAvailable = true,
  }) async {
    try {
      await _menuRepo.add(
        title: title,
        description: description,
        categoryId: categoryId,
        price: price,
        unit: unit,
        isAvailable: isAvailable,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to add item: $e');
    }
  }

  Future<void> updateMenuItem(MenuItem item) async {
    try {
      await _menuRepo.update(item);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update item: $e');
    }
  }

  Future<void> deleteMenuItem(int id) async {
    try {
      await _menuRepo.delete(id);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete item: $e');
    }
  }

  Future<void> toggleAvailability(MenuItem item) async {
    final updated = item.copyWith(isAvailable: !item.isAvailable);
    await updateMenuItem(updated);
  }

  Future<void> addCategory({required String name, String? emoji}) async {
    try {
      await _categoryRepo.add(name: name, emoji: emoji);
    } catch (e) {
      state = state.copyWith(error: 'Failed to add category: $e');
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await _categoryRepo.update(category);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update category: $e');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _categoryRepo.delete(id);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete category: $e');
    }
  }
}
