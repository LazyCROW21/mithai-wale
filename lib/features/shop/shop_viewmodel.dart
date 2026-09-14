import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shop_state.dart';

class ShopViewModel extends Notifier<ShopState> {
  @override
  ShopState build() => const ShopState();

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
