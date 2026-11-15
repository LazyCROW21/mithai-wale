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
  static const orders = '/orders';
  static const profile = '/profile';
  static const settings = '/settings';
  static const menu = '/menu';
  static const ledger = '/ledger';
  static const login = '/login';
  static const shops = '/shops';
  static const staff = '/staff';
  static const inventory = '/inventory';
  static const audit = '/audit';

  /// Mobile/tablet hub listing every screen not on the bottom bar.
  static const more = '/more';

  // ── Modal bottom sheets ───────────────────────────────────────────────────
  /// Path template — use [productDetailPath] to generate the concrete path.
  static const productDetail = '/product/:id/sheet';

  /// Generates the concrete product-detail sheet path for [id].
  static String productDetailPath(String id) => '/product/$id/sheet';

  // ── Dialogs ───────────────────────────────────────────────────────────────
  static const confirmLogout = '/logout/dialog';

  /// Counter order entry (replaces the old shop + cart flow).
  static const createOrder = '/orders/new/dialog';
}

/// Route name constants (used with [GoRouter.pushNamed]).
abstract final class AppRouteNames {
  // Screens
  static const home = 'home';
  static const orders = 'orders';
  static const profile = 'profile';
  static const settings = 'settings';
  static const menu = 'menu';
  static const ledger = 'ledger';
  static const login = 'login';
  static const shops = 'shops';
  static const staff = 'staff';
  static const inventory = 'inventory';
  static const audit = 'audit';
  static const more = 'more';

  // Modals
  static const productDetail = 'product-detail';
  static const confirmLogout = 'confirm-logout';
  static const createOrder = 'create-order';
}
