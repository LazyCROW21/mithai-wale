import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../auth/auth_models.dart';
import '../auth/auth_notifier.dart';
import '../layout/layout_extensions.dart';
import '../routing/app_destinations.dart';
import '../routing/router_key.dart';
import '../routing/routes.dart';

/// Persistent app frame around every signed-in screen.
///
/// * Mobile / tablet: bottom bar — Dashboard · Menu · [New order] · Orders · More.
/// * Desktop: side bar listing every screen the user may open.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).session;
    if (session == null) return child;
    return context.isDesktop
        ? _DesktopShell(session: session, location: location, child: child)
        : _BottomBarShell(session: session, location: location, child: child);
  }
}

class _NewOrderFab extends StatelessWidget {
  const _NewOrderFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'shell-new-order',
      tooltip: context.l10n.navNewOrder,
      elevation: 6,
      onPressed: AppNav.showCreateOrder,
      child: const Icon(Icons.add_shopping_cart),
    );
  }
}

// ── Mobile / tablet ──────────────────────────────────────────────────────────

class _BottomBarShell extends StatelessWidget {
  const _BottomBarShell({required this.session, required this.location, required this.child});

  final AuthSession session;
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final byRoute = {for (final d in appDestinations) d.route: d};
    final canOrder = session.can(Permission.orders);
    final onBar = bottomBarRoutes.any((r) => byRoute[r]!.matches(location));

    Widget tab(AppDestination d) => d.allowed(session)
        ? _BarTab(
            icon: d.icon,
            selectedIcon: d.selectedIcon,
            label: d.label(l10n),
            selected: d.matches(location),
            onTap: () => AppNav.go(d.route),
          )
        : const SizedBox.shrink();

    return Scaffold(
      body: child,
      floatingActionButton: canOrder ? const _NewOrderFab() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        padding: EdgeInsets.zero,
        height: 68,
        elevation: 8,
        child: Row(
          children: [
            Expanded(child: tab(byRoute[AppRoutes.home]!)),
            Expanded(child: tab(byRoute[AppRoutes.menu]!)),
            if (canOrder) const SizedBox(width: 72),
            Expanded(child: tab(byRoute[AppRoutes.orders]!)),
            Expanded(
              child: _BarTab(
                icon: Icons.menu,
                selectedIcon: Icons.menu_open,
                label: l10n.navMore,
                selected: !onBar,
                onTap: () => AppNav.go(AppRoutes.more),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarTab extends StatelessWidget {
  const _BarTab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.onSecondaryContainer : cs.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? cs.secondaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(selected ? selectedIcon : icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Desktop ──────────────────────────────────────────────────────────────────

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({required this.session, required this.location, required this.child});

  final AuthSession session;
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final items = appDestinations.where((d) => d.allowed(session)).toList();
    final selected = items.indexWhere((d) => d.matches(location));

    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: selected < 0 ? null : selected,
            onDestinationSelected: (i) => AppNav.go(items[i].route),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 16, 4),
                child: Text(
                  l10n.appName,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 16, 12),
                child: Text(
                  '${session.name} · ${session.role.label(l10n)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (session.can(Permission.orders))
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      elevation: 3,
                      shadowColor: Colors.black38,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: AppNav.showCreateOrder,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(l10n.navNewOrder),
                  ),
                ),
              for (final d in items)
                NavigationDrawerDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label(l10n)),
                ),
              const Divider(indent: 28, endIndent: 28),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 28),
                leading: const Icon(Icons.logout_outlined),
                title: Text(l10n.actionSignOut),
                onTap: () => AppNav.push(AppRoutes.confirmLogout),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// AppBar leading for screens opened from "More": returns there on
/// mobile/tablet; nothing on desktop (the side bar is always visible).
class MoreBackButton extends StatelessWidget {
  const MoreBackButton({super.key});

  /// Use as `AppBar(leading: MoreBackButton.of(context))`.
  static Widget? of(BuildContext context) => context.isDesktop ? null : const MoreBackButton();

  @override
  Widget build(BuildContext context) {
    return BackButton(onPressed: () => AppNav.go(AppRoutes.more));
  }
}
