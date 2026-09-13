/// Global navigator key and context-free navigation helpers.
///
/// The [rootNavigatorKey] is passed to [GoRouter.navigatorKey], giving the
/// app a stable handle to the root [NavigatorState] without needing a
/// [BuildContext].
///
/// ### Context-free navigation
/// Use [AppNav] anywhere — inside ViewModels, services, get_it factories,
/// or notification handlers:
///
/// ```dart
/// AppNav.go(AppRoutes.shop);
/// AppNav.push(AppRoutes.productDetail, params: {'id': '42'});
/// AppNav.pop();
/// AppNav.showBottomSheet(const AddToCartSheet());
/// ```
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';
import 'routes.dart';

/// Root [NavigatorState] key — passed to [GoRouter.navigatorKey].
/// Use [AppNav] for navigation instead of this key directly.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Context-free navigation facade backed by [appRouter].
///
/// All methods delegate to the [GoRouter] instance so routing logic
/// (redirects, guards, transitions) is always respected.
abstract final class AppNav {
  // ── Screen navigation ─────────────────────────────────────────────────────

  /// Replaces the entire navigation stack with [path].
  static void go(String path, {Object? extra}) => appRouter.go(path, extra: extra);

  /// Pushes [path] onto the stack, returning to the previous route on pop.
  static Future<T?> push<T>(String path, {Object? extra}) =>
      appRouter.push(path, extra: extra);

  /// Pushes a named route by [name] with optional path + query parameters.
  static Future<T?> pushNamed<T>(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) =>
      appRouter.pushNamed<T>(
        name,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
      );

  /// Pops the top-most route. Optionally returns [result] to the caller.
  static void pop<T>([T? result]) => appRouter.pop(result);

  /// Returns `true` if the router can pop the current route.
  static bool canPop() => appRouter.canPop();

  // ── Modal helpers ─────────────────────────────────────────────────────────

  /// Opens the product detail bottom-sheet route for [productId].
  static Future<void> showProductDetail(String productId) =>
      push(AppRoutes.productDetailPath(productId));

  /// Opens the add-to-cart bottom-sheet route.
  static Future<void> showAddToCart({Object? extra}) =>
      push(AppRoutes.addToCart, extra: extra);

  // ── Low-level access ──────────────────────────────────────────────────────

  /// Direct access to the underlying [NavigatorState].
  /// Prefer [AppNav] helpers over using this directly.
  static NavigatorState? get navigator => rootNavigatorKey.currentState;
}
