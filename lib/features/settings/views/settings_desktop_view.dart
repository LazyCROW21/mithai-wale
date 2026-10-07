import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../../../core/state/app_state_providers.dart';
import '../../../l10n/l10n.dart';
import '../../menu/widgets/manage_categories_dialog.dart';
import '../widgets/language_selector_card.dart';

class SettingsDesktopView extends ConsumerWidget {
  const SettingsDesktopView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? ThemeMode.system;

    final navItems = [
      (icon: Icons.home_outlined, selectedIcon: Icons.home, label: l10n.navHome, route: AppRoutes.home),
      (icon: Icons.store_outlined, selectedIcon: Icons.store, label: l10n.navShop, route: AppRoutes.shop),
      (icon: Icons.restaurant_menu_outlined, selectedIcon: Icons.restaurant_menu, label: l10n.navMenu, route: AppRoutes.menu),
      (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: l10n.navOrders, route: AppRoutes.orders),
      (icon: Icons.person_outline, selectedIcon: Icons.person, label: l10n.navProfile, route: AppRoutes.profile),
      (icon: Icons.settings, selectedIcon: Icons.settings, label: l10n.navSettings, route: AppRoutes.settings),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: 5, // Settings index
            onDestinationSelected: (i) => AppNav.go(navItems[i].route),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 16, 10),
                child: Text(
                  l10n.appName,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 4),
                child: Text('MANAGEMENT', style: TextStyle(fontSize: 11, letterSpacing: 1.4)),
              ),
              ...navItems.map(
                (item) => NavigationDrawerDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: Text(item.label),
                ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cs.outlineVariant))),
                  child: Row(
                    children: [
                      Text(l10n.navSettings, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(32),
                    children: [
                      // Language Preferences Card
                      Text(l10n.language, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const LanguageSelectorCard(),
                      const SizedBox(height: 32),

                      // Menu Management Banner
                      Card(
                        color: cs.primaryContainer.withAlpha(80),
                        elevation: 1,
                        shadowColor: Colors.black12,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.menuCatalogManagement,
                                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.menuCatalogDesc,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              OutlinedButton.icon(
                                onPressed: () => showManageCategoriesModal(context),
                                icon: const Icon(Icons.category_outlined),
                                label: Text(l10n.manageCategories),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                onPressed: () => AppNav.go(AppRoutes.menu),
                                icon: const Icon(Icons.edit_note),
                                label: Text(l10n.openMenu),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Theme preferences
                      Text(l10n.appearance, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 1,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant)),
                        child: RadioGroup<ThemeMode>(
                          groupValue: themeMode,
                          onChanged: (mode) {
                            if (mode != null) ref.read(themeModeProvider.notifier).setThemeMode(mode);
                          },
                          child: Column(
                            children: [
                              RadioListTile<ThemeMode>(
                                title: Text(l10n.themeSystem),
                                subtitle: Text(l10n.themeSystemDesc),
                                value: ThemeMode.system,
                              ),
                              const Divider(height: 1),
                              RadioListTile<ThemeMode>(
                                title: Text(l10n.themeLight),
                                subtitle: Text(l10n.themeLightDesc),
                                value: ThemeMode.light,
                              ),
                              const Divider(height: 1),
                              RadioListTile<ThemeMode>(
                                title: Text(l10n.themeDark),
                                subtitle: Text(l10n.themeDarkDesc),
                                value: ThemeMode.dark,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
