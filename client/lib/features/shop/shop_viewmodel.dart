import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/models/category_model.dart';
import '../../core/database/models/menu_item_model.dart';
import '../../core/database/repositories/category_repository.dart';
import '../../core/database/repositories/menu_repository.dart';
import '../../core/di/service_locator.dart';
import 'shop_state.dart';

class ShopViewModel extends Notifier<ShopState> {
  late final _menuRepo = sl<IMenuRepository>();
  late final _categoryRepo = sl<ICategoryRepository>();

  StreamSubscription<List<MenuItem>>? _itemsSub;
  StreamSubscription<List<Category>>? _categoriesSub;

  @override
  ShopState build() {
    _listenToStreams();
    ref.onDispose(() {
      _itemsSub?.cancel();
      _categoriesSub?.cancel();
    });
    return const ShopState(isLoading: true);
  }

  void _listenToStreams() {
    _categoriesSub = _categoryRepo.watchAll().listen((categories) {
      state = state.copyWith(categories: categories, isLoading: false);
    }, onError: (_) {
      state = state.copyWith(isLoading: false);
    });

    _itemsSub = _menuRepo.watchAll().listen((items) {
      state = state.copyWith(items: items, isLoading: false);
    }, onError: (_) {
      state = state.copyWith(isLoading: false);
    });
  }

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectNavItem(int index) {
    state = state.copyWith(selectedNavIndex: index);
  }
}
