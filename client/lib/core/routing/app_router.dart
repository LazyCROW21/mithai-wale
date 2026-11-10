/// Application router — every screen, modal bottom sheet, and dialog
/// is declared here as a [GoRoute].
///
/// ### Architecture
/// ```
/// appRouter  (GoRouter)
///   ├── /                       → HomePage
///   ├── /shop                   → ShopPage
///   ├── /orders                 → OrdersPage
///   ├── /reports                → ReportsPage
///   ├── /profile                → ProfilePage
///   ├── /settings               → SettingsPage
///   ├── /product/:id/sheet      → ProductDetailSheet  (ModalBottomSheetPage)
///   ├── /cart/add/sheet         → AddToCartSheet      (ModalBottomSheetPage)
///   └── /logout/dialog          → ConfirmLogoutDialog (AppDialogPage)
/// ```
///
/// ### Adding a new screen
/// 1. Add path + name constants to [AppRoutes] / [AppRouteNames] in routes.dart
/// 2. Add a [GoRoute] entry below
/// 3. Use `AppNav.go(AppRoutes.myRoute)` to navigate
///
/// ### Adding a modal bottom sheet
/// Use [ModalBottomSheetPage] as the `pageBuilder` return value.
/// The route path **must** end with `/sheet` (convention).
///
/// ### Adding a dialog
/// Use [AppDialogPage] as the `pageBuilder` return value.
/// The route path **must** end with `/dialog` (convention).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/layout/layout_extensions.dart';
import '../../features/auth/login_page.dart';
import '../../features/inventory/inventory_page.dart';
import '../../features/shops/shops_page.dart';
import '../../features/staff/staff_page.dart';
import '../../l10n/l10n.dart';
import '../../features/cart/widgets/cart_summary_sheet.dart';
import '../../features/home/home_page.dart';
import '../../features/ledger/ledger_page.dart';
import '../../features/menu/menu_page.dart';
import '../../features/orders/orders_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/shop/shop_page.dart';
import 'router_key.dart';
import 'routes.dart';

// ── Custom Page Types ─────────────────────────────────────────────────────────

/// A [Page] that presents its [child] as a modal bottom sheet.
///
/// The sheet slides up from the bottom with a scrim. Tapping the scrim
/// or calling [AppNav.pop] dismisses it.
class ModalBottomSheetPage<T> extends Page<T> {
  const ModalBottomSheetPage({
    required this.child,
    this.isScrollControlled = true,
    this.useSafeArea = true,
    this.backgroundColor,
    this.barrierColor,
    this.constraints,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final bool isScrollControlled;
  final bool useSafeArea;
  final Color? backgroundColor;
  final Color? barrierColor;
  final BoxConstraints? constraints;

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute<T>(
      settings: this,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      backgroundColor: backgroundColor,
      modalBarrierColor: barrierColor ?? Colors.black54,
      constraints: constraints ?? const BoxConstraints(maxWidth: 960),
      builder: (context) => child,
    );
  }
}

/// A [Page] that presents its [child] as a modal dialog.
///
/// The background is dimmed. Tapping outside (when [barrierDismissible])
/// or calling [AppNav.pop] dismisses the dialog.
class AppDialogPage<T> extends Page<T> {
  const AppDialogPage({
    required this.child,
    this.barrierDismissible = true,
    this.barrierColor,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final bool barrierDismissible;
  final Color? barrierColor;

  @override
  Route<T> createRoute(BuildContext context) {
    return DialogRoute<T>(
      settings: this,
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      builder: (context) => child,
    );
  }
}

// ── Auth guard ────────────────────────────────────────────────────────────────

/// Bridges [appAuth] state changes to GoRouter so redirects re-run on sign in/out.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh() {
    appAuth.addListener((_) => notifyListeners(), fireImmediately: false);
  }
}

/// Feature permission required to open a location (null = no extra requirement).
Permission? _permissionFor(String location) {
  if (location == AppRoutes.home) return Permission.home;
  if (location.startsWith(AppRoutes.shops)) return Permission.shops;
  if (location.startsWith(AppRoutes.staff)) return Permission.staff;
  if (location.startsWith(AppRoutes.inventory)) return Permission.inventory;
  if (location.startsWith(AppRoutes.shop)) return Permission.shop;
  if (location.startsWith(AppRoutes.orders)) return Permission.orders;
  if (location.startsWith(AppRoutes.menu)) return Permission.menu;
  if (location.startsWith(AppRoutes.ledger)) return Permission.ledger;
  if (location.startsWith(AppRoutes.profile)) return Permission.profile;
  if (location.startsWith(AppRoutes.settings)) return Permission.settings;
  if (location.startsWith('/product') || location.startsWith('/cart')) return Permission.shop;
  return null;
}

String? _authRedirect(BuildContext context, GoRouterState state) {
  final auth = appAuth.current;
  final loc = state.matchedLocation;
  if (auth.status != AuthStatus.signedIn) {
    return loc == AppRoutes.login ? null : AppRoutes.login;
  }
  if (loc == AppRoutes.login) return AppRoutes.home;
  final needed = _permissionFor(loc);
  if (needed != null && !auth.session!.can(needed)) return AppRoutes.home;
  return null;
}

// ── Router Instance ───────────────────────────────────────────────────────────

/// The application [GoRouter].
///
/// Use [AppNav] for navigation — do not import this directly in UI code.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  debugLogDiagnostics: true, // set false in production
  initialLocation: AppRoutes.home,
  redirect: _authRedirect,
  refreshListenable: _AuthRefresh(),
  routes: [
    GoRoute(
      path: AppRoutes.login,
      name: AppRouteNames.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.shops,
      name: AppRouteNames.shops,
      builder: (context, state) => const ShopsPage(),
    ),
    GoRoute(
      path: AppRoutes.staff,
      name: AppRouteNames.staff,
      builder: (context, state) => const StaffPage(),
    ),
    GoRoute(
      path: AppRoutes.inventory,
      name: AppRouteNames.inventory,
      builder: (context, state) => const InventoryPage(),
    ),
    // ── Screens ──────────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.home,
      name: AppRouteNames.home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.shop,
      name: AppRouteNames.shop,
      builder: (context, state) => const ShopPage(),
    ),
    GoRoute(
      path: AppRoutes.orders,
      name: AppRouteNames.orders,
      builder: (context, state) => const OrdersPage(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      name: AppRouteNames.profile,
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: AppRouteNames.settings,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: AppRoutes.menu,
      name: AppRouteNames.menu,
      builder: (context, state) => const MenuPage(),
    ),
    GoRoute(
      path: AppRoutes.ledger,
      name: AppRouteNames.ledger,
      builder: (context, state) => const LedgerPage(),
    ),

    // ── Modal Bottom Sheets ───────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.productDetail,
      name: AppRouteNames.productDetail,
      pageBuilder: (context, state) => ModalBottomSheetPage(
        key: state.pageKey,
        name: state.name,
        child: _ProductDetailSheet(
          productId: state.pathParameters['id'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.addToCart,
      name: AppRouteNames.addToCart,
      pageBuilder: (context, state) {
        if (context.isMobile) {
          return MaterialPage(
            key: state.pageKey,
            name: state.name,
            child: const CartSummarySheet(),
          );
        }
        return ModalBottomSheetPage(
          key: state.pageKey,
          name: state.name,
          constraints: const BoxConstraints(maxWidth: 960),
          child: const CartSummarySheet(),
        );
      },
    ),

    // ── Dialogs ───────────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.confirmLogout,
      name: AppRouteNames.confirmLogout,
      pageBuilder: (context, state) => AppDialogPage(
        key: state.pageKey,
        name: state.name,
        child: const _ConfirmLogoutDialog(),
      ),
    ),
  ],

  // Global error page
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          Text('Page not found', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(state.uri.toString(), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => appRouter.go(AppRoutes.home),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);

// ── Stub modal widgets (replace with real implementations) ────────────────────

class _ProductDetailSheet extends StatelessWidget {
  const _ProductDetailSheet({required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Product #$productId', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Product detail sheet — replace with real implementation.'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => AppNav.pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}


class _ConfirmLogoutDialog extends StatelessWidget {
  const _ConfirmLogoutDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.authSignOutTitle),
      content: Text(l10n.authSignOutMessage),
      actions: [
        TextButton(onPressed: AppNav.pop, child: Text(l10n.actionCancel)),
        FilledButton(
          onPressed: () {
            AppNav.pop();
            // The router redirects to /login once the state flips.
            appAuth.signOut();
          },
          child: Text(l10n.actionSignOut),
        ),
      ],
    );
  }
}
