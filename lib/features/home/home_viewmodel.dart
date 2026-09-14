import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_state.dart';

class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState();

  void selectNavItem(int index) {
    state = state.copyWith(selectedNavIndex: index);
  }

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void refreshDashboard() {
    state = state.copyWith(isLoading: true);
    // Refresh logic here
    state = state.copyWith(isLoading: false);
  }
}
