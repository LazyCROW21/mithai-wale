import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../auth/auth_models.dart';
import 'routes.dart';

/// A top-level screen as shown in navigation (desktop sidebar, mobile "More").
@immutable
class AppDestination {
  const AppDestination({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.allowed,
  });

  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations l10n) label;
  final bool Function(AuthSession session) allowed;

  /// Whether [location] is this destination (or a sub-route of it).
  bool matches(String location) =>
      route == AppRoutes.home ? location == AppRoutes.home : location.startsWith(route);
}

bool _perm(AuthSession s, Permission p) => s.can(p);

/// Every navigable screen, in sidebar order.
final List<AppDestination> appDestinations = [
  AppDestination(
    route: AppRoutes.home,
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    label: (l) => l.navDashboard,
    allowed: (s) => _perm(s, Permission.home),
  ),
  AppDestination(
    route: AppRoutes.menu,
    icon: Icons.restaurant_menu_outlined,
    selectedIcon: Icons.restaurant_menu,
    label: (l) => l.navMenu,
    allowed: (s) => _perm(s, Permission.menu),
  ),
  AppDestination(
    route: AppRoutes.orders,
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    label: (l) => l.navOrders,
    allowed: (s) => _perm(s, Permission.orders),
  ),
  AppDestination(
    route: AppRoutes.ledger,
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet,
    label: (l) => l.navLedger,
    allowed: (s) => _perm(s, Permission.ledger),
  ),
  AppDestination(
    route: AppRoutes.inventory,
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    label: (l) => l.navInventory,
    allowed: (s) => _perm(s, Permission.inventory),
  ),
  AppDestination(
    route: AppRoutes.shops,
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront,
    label: (l) => l.navShops,
    allowed: (s) => _perm(s, Permission.shops),
  ),
  AppDestination(
    route: AppRoutes.staff,
    icon: Icons.badge_outlined,
    selectedIcon: Icons.badge,
    label: (l) => l.navStaff,
    allowed: (s) => _perm(s, Permission.staff),
  ),
  AppDestination(
    route: AppRoutes.audit,
    icon: Icons.history_outlined,
    selectedIcon: Icons.history,
    label: (l) => l.navAudit,
    // No server permission yet (planned as online-only); franchise admin only.
    allowed: (s) => s.isFranchiseAdmin,
  ),
  AppDestination(
    route: AppRoutes.profile,
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    label: (l) => l.navProfile,
    allowed: (s) => _perm(s, Permission.profile),
  ),
  AppDestination(
    route: AppRoutes.settings,
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: (l) => l.navSettings,
    allowed: (s) => _perm(s, Permission.settings),
  ),
];

/// Routes that sit directly on the mobile/tablet bottom bar.
const bottomBarRoutes = {AppRoutes.home, AppRoutes.menu, AppRoutes.orders};
