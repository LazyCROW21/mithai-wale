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

import '../../features/home/home_page.dart';
import '../../features/menu/menu_page.dart';
import '../../features/orders/orders_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/reports/reports_page.dart';
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

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute<T>(
      settings: this,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      backgroundColor: backgroundColor,
      modalBarrierColor: barrierColor ?? Colors.black54,
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

// ── Router Instance ───────────────────────────────────────────────────────────

/// The application [GoRouter].
///
/// Use [AppNav] for navigation — do not import this directly in UI code.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  debugLogDiagnostics: true, // set false in production
  initialLocation: AppRoutes.home,
  routes: [
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
      path: AppRoutes.reports,
      name: AppRouteNames.reports,
      builder: (context, state) => const ReportsPage(),
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
      pageBuilder: (context, state) => ModalBottomSheetPage(
        key: state.pageKey,
        name: state.name,
        child: const _AddToCartSheet(),
      ),
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

class _AddToCartSheet extends StatelessWidget {
  const _AddToCartSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add to Cart', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('Add-to-cart sheet — replace with real implementation.'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: AppNav.pop, child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: AppNav.pop, child: const Text('Add'))),
            ],
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
    return AlertDialog(
      title: const Text('Sign out?'),
      content: const Text('You will be returned to the login screen.'),
      actions: [
        TextButton(onPressed: AppNav.pop, child: const Text('Cancel')),
        FilledButton(onPressed: AppNav.pop, child: const Text('Sign Out')),
      ],
    );
  }
}
