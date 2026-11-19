/// Application router — every screen, modal bottom sheet, and dialog
/// is declared here as a [GoRoute].
///
/// ### Architecture
/// ```
/// appRouter  (GoRouter)   initial: /   redirect: _authRedirect
///   ├── /login                  → LoginPage            (public)
///   ├── ShellRoute              → AppShell (bottom bar on mobile/tablet, side bar on desktop)
///   │   ├── /                   → HomePage (dashboard)  shop filter for franchise admin
///   │   ├── /menu               → MenuPage              read-only for employees
///   │   ├── /orders             → OrdersPage            shop filter for franchise admin
///   │   ├── /ledger             → LedgerPage            shop filter for franchise admin
///   │   ├── /inventory          → InventoryPage         shop filter for franchise admin
///   │   ├── /shops              → ShopsPage             franchise admin
///   │   ├── /staff              → StaffPage             franchise admin
///   │   ├── /audit              → AuditPage             franchise admin (placeholder)
///   │   ├── /profile            → ProfilePage
///   │   ├── /settings           → SettingsPage
///   │   └── /more               → MorePage              mobile/tablet hub
///   ├── /product/:id/sheet      → ProductDetailSheet   (ModalBottomSheetPage)
///   ├── /orders/new/dialog      → CreateOrderDialog    (AppDialogPage)
///   └── /logout/dialog          → ConfirmLogoutDialog  (AppDialogPage)
/// ```
///
/// ### Adding a new screen
/// 1. Add path + name constants to [AppRoutes] / [AppRouteNames] in routes.dart
/// 2. Add a [GoRoute] inside the [ShellRoute] below
/// 3. Add it to `appDestinations` so it shows in the side bar / "More"
/// 4. Use `AppNav.go(AppRoutes.myRoute)` to navigate
///
/// ### Adding a modal bottom sheet
/// Use [ModalBottomSheetPage] as the `pageBuilder` return value, outside the
/// shell with `parentNavigatorKey: rootNavigatorKey`.
/// The route path **must** end with `/sheet` (convention).
///
/// ### Adding a dialog
/// Use [AppDialogPage] as the `pageBuilder` return value, outside the shell
/// with `parentNavigatorKey: rootNavigatorKey`.
/// The route path **must** end with `/dialog` (convention).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/sync/sync_engine.dart';
import '../../features/audit/audit_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/inventory/inventory_page.dart';
import '../../features/shops/shops_page.dart';
import '../../features/staff/staff_page.dart';
import '../../l10n/l10n.dart';
import '../../features/home/home_page.dart';
import '../../features/ledger/ledger_page.dart';
import '../../features/menu/menu_page.dart';
import '../../features/more/more_page.dart';
import '../../features/orders/orders_page.dart';
import '../../features/orders/widgets/create_order_dialog.dart';
import '../../features/profile/profile_page.dart';
import '../../features/settings/settings_page.dart';
import '../widgets/app_shell.dart';
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

/// Whether [session] may open [location]. Sheets/dialogs follow the screen
/// they belong to; `/more` and `/logout/dialog` are open to any signed-in user.
bool _canOpen(AuthSession session, String location) {
  if (location.startsWith(AppRoutes.audit)) return session.isFranchiseAdmin;
  if (location.startsWith('/product')) return session.can(Permission.menu);
  final needed = switch (location) {
    AppRoutes.home => Permission.home,
    _ when location.startsWith(AppRoutes.shops) => Permission.shops,
    _ when location.startsWith(AppRoutes.staff) => Permission.staff,
    _ when location.startsWith(AppRoutes.inventory) => Permission.inventory,
    _ when location.startsWith(AppRoutes.orders) => Permission.orders,
    _ when location.startsWith(AppRoutes.menu) => Permission.menu,
    _ when location.startsWith(AppRoutes.ledger) => Permission.ledger,
    _ when location.startsWith(AppRoutes.profile) => Permission.profile,
    _ when location.startsWith(AppRoutes.settings) => Permission.settings,
    _ => null,
  };
  return needed == null || session.can(needed);
}

String? _authRedirect(BuildContext context, GoRouterState state) {
  final auth = appAuth.current;
  final loc = state.matchedLocation;
  if (auth.status != AuthStatus.signedIn) {
    return loc == AppRoutes.login ? null : AppRoutes.login;
  }
  final session = auth.session!;
  // Landing screen: the dashboard, or "More" if the dashboard is not allowed
  // (never redirect to a location that would itself be refused, so no loops).
  final landing = _canOpen(session, AppRoutes.home) ? AppRoutes.home : AppRoutes.more;
  if (loc == AppRoutes.login) return landing;
  if (!_canOpen(session, loc)) return loc == landing ? null : landing;
  return null;
}

/// A shell screen; switching between them is instant (no push animation).
GoRoute _screen(String path, String name, Widget page) => GoRoute(
      path: path,
      name: name,
      pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, name: name, child: page),
    );

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

    // ── Screens (inside the persistent nav shell) ────────────────────────────
    ShellRoute(
      builder: (context, state, child) => AppShell(location: state.matchedLocation, child: child),
      routes: [
        _screen(AppRoutes.home, AppRouteNames.home, const HomePage()),
        _screen(AppRoutes.menu, AppRouteNames.menu, const MenuPage()),
        _screen(AppRoutes.orders, AppRouteNames.orders, const OrdersPage()),
        _screen(AppRoutes.ledger, AppRouteNames.ledger, const LedgerPage()),
        _screen(AppRoutes.inventory, AppRouteNames.inventory, const InventoryPage()),
        _screen(AppRoutes.shops, AppRouteNames.shops, const ShopsPage()),
        _screen(AppRoutes.staff, AppRouteNames.staff, const StaffPage()),
        _screen(AppRoutes.audit, AppRouteNames.audit, const AuditPage()),
        _screen(AppRoutes.profile, AppRouteNames.profile, const ProfilePage()),
        _screen(AppRoutes.settings, AppRouteNames.settings, const SettingsPage()),
        _screen(AppRoutes.more, AppRouteNames.more, const MorePage()),
      ],
    ),

    // ── Modal Bottom Sheets ───────────────────────────────────────────────────
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
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

    // ── Dialogs ───────────────────────────────────────────────────────────────
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.createOrder,
      name: AppRouteNames.createOrder,
      pageBuilder: (context, state) => AppDialogPage(
        key: state.pageKey,
        name: state.name,
        barrierDismissible: false,
        child: const CreateOrderDialog(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
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


class _ConfirmLogoutDialog extends ConsumerWidget {
  const _ConfirmLogoutDialog();

  Future<void> _signOut() async {
    AppNav.pop();
    // Explicit sign-out wipes this user's local data; the router then
    // redirects to /login once the auth state flips.
    await syncEngine.stopAndWipe();
    await appAuth.signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sync = ref.watch(syncStatusProvider);
    final pending = sync.pending;
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(l10n.authSignOutTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.authSignOutMessage),
          if (pending > 0) ...[
            const SizedBox(height: 12),
            Text(l10n.syncSignOutPending(pending), style: TextStyle(color: cs.error)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: AppNav.pop, child: Text(l10n.actionCancel)),
        if (pending > 0) ...[
          OutlinedButton(
            onPressed: sync.isBusy ? null : syncEngine.syncNow,
            child: Text(l10n.syncNow),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            onPressed: _signOut,
            child: Text(l10n.syncSignOutAnyway),
          ),
        ] else
          FilledButton(onPressed: _signOut, child: Text(l10n.actionSignOut)),
      ],
    );
  }
}
