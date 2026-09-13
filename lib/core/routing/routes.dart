/// Typed route path and name constants for the entire application.
///
/// ### Rules
/// 1. All path strings live **only** here — never hard-code paths elsewhere.
/// 2. Every route has both a `path` (for [GoRouter] definition) and
///    a `name` (for [GoRouter.pushNamed] / [GoRouter.goNamed]).
/// 3. Modal bottom-sheet and dialog routes are distinguished by the suffix
///    convention documented below.
///
/// ### Path conventions
/// | Suffix      | Kind                     | Transition            |
/// |-------------|--------------------------|----------------------|
/// | (none)      | Regular screen           | Default slide        |
/// | `/sheet`    | Modal bottom sheet       | Slide up             |
/// | `/dialog`   | Dialog                   | Fade + scale         |
library;

/// Route path constants.
abstract final class AppRoutes {
  // ── Top-level screens ─────────────────────────────────────────────────────
  static const home = '/';
  static const shop = '/shop';
  static const orders = '/orders';
  static const reports = '/reports';
  static const profile = '/profile';
  static const settings = '/settings';

  // ── Modal bottom sheets ───────────────────────────────────────────────────
  /// Path template — use [productDetailPath] to generate the concrete path.
  static const productDetail = '/product/:id/sheet';

  /// Generates the concrete product-detail sheet path for [id].
  static String productDetailPath(String id) => '/product/$id/sheet';

  static const addToCart = '/cart/add/sheet';

  // ── Dialogs ───────────────────────────────────────────────────────────────
  static const confirmLogout = '/logout/dialog';
}

/// Route name constants (used with [GoRouter.pushNamed]).
abstract final class AppRouteNames {
  // Screens
  static const home = 'home';
  static const shop = 'shop';
  static const orders = 'orders';
  static const reports = 'reports';
  static const profile = 'profile';
  static const settings = 'settings';

  // Modals
  static const productDetail = 'product-detail';
  static const addToCart = 'add-to-cart';
  static const confirmLogout = 'confirm-logout';
}
