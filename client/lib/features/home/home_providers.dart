/// Riverpod provider declarations for the Home feature.
///
/// ### Scope
/// [homeViewModelProvider] is app-scoped (not overridden), meaning all three
/// layout views (mobile / tablet / desktop) share the same [HomeViewModel]
/// instance and [HomeState]. State is preserved when the layout tier changes
/// (e.g. when the user resizes the window from mobile to desktop width).
///
/// ### Usage in a view
/// ```dart
/// class HomeMobileView extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final state = ref.watch(homeViewModelProvider);
///     final vm    = ref.read(homeViewModelProvider.notifier);
///
///     return NavigationBar(
///       selectedIndex: state.selectedNavIndex,
///       onDestinationSelected: vm.selectNavItem,
///       ...
///     );
///   }
/// }
/// ```
///
/// ### Selective rebuild — avoid rebuilding the whole tree
/// ```dart
/// // Only rebuilds when selectedNavIndex changes
/// final navIndex = ref.watch(homeViewModelProvider.select((s) => s.selectedNavIndex));
/// ```
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_state.dart';
import 'home_viewmodel.dart';

/// The single source of truth for Home feature state.
///
/// All Home views read from and write to this provider.
final homeViewModelProvider =
    NotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);
