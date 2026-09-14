import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../../../core/state/app_state_providers.dart';
import '../../menu/widgets/manage_categories_dialog.dart';

class SettingsDesktopView extends ConsumerWidget {
  const SettingsDesktopView({super.key});

  static const _navItems = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home', route: AppRoutes.home),
    (icon: Icons.store_outlined, selectedIcon: Icons.store, label: 'Shop', route: AppRoutes.shop),
    (icon: Icons.restaurant_menu_outlined, selectedIcon: Icons.restaurant_menu, label: 'Menu', route: AppRoutes.menu),
    (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Orders', route: AppRoutes.orders),
    (icon: Icons.analytics_outlined, selectedIcon: Icons.analytics, label: 'Reports', route: AppRoutes.reports),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', route: AppRoutes.profile),
    (icon: Icons.settings, selectedIcon: Icons.settings, label: 'Settings', route: AppRoutes.settings),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? ThemeMode.system;

    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: 6, // Settings index
            onDestinationSelected: (i) => AppNav.go(_navItems[i].route),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 16, 10),
                child: Text(
                  'मिठाई वाले',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 4),
                child: Text('MANAGEMENT', style: TextStyle(fontSize: 11, letterSpacing: 1.4)),
              ),
              ..._navItems.map(
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
                title: const Text('Sign out'),
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
                      Text('Settings', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(32),
                    children: [
                      // Menu Management Banner
                      Card(
                        color: cs.primaryContainer.withAlpha(80),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Menu & Catalog Management',
                                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Add, edit and organize sweets menu items with auto-gen IDs, custom categories, pricing, and units.',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              OutlinedButton.icon(
                                onPressed: () => showManageCategoriesModal(context),
                                icon: const Icon(Icons.category_outlined),
                                label: const Text('Manage Categories'),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                onPressed: () => AppNav.go(AppRoutes.menu),
                                icon: const Icon(Icons.edit_note),
                                label: const Text('Go to Menu Page'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Theme preferences
                      Text('Appearance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant)),
                        child: Column(
                          children: [
                            RadioListTile<ThemeMode>(
                              title: const Text('System Default'),
                              subtitle: const Text('Adapt automatically to operating system theme setting'),
                              value: ThemeMode.system,
                              groupValue: themeMode,
                              onChanged: (mode) {
                                if (mode != null) ref.read(themeModeProvider.notifier).setThemeMode(mode);
                              },
                            ),
                            const Divider(height: 1),
                            RadioListTile<ThemeMode>(
                              title: const Text('Light Mode'),
                              subtitle: const Text('Clean warm saffron light theme'),
                              value: ThemeMode.light,
                              groupValue: themeMode,
                              onChanged: (mode) {
                                if (mode != null) ref.read(themeModeProvider.notifier).setThemeMode(mode);
                              },
                            ),
                            const Divider(height: 1),
                            RadioListTile<ThemeMode>(
                              title: const Text('Dark Mode'),
                              subtitle: const Text('Sleek dark theme for night usage'),
                              value: ThemeMode.dark,
                              groupValue: themeMode,
                              onChanged: (mode) {
                                if (mode != null) ref.read(themeModeProvider.notifier).setThemeMode(mode);
                              },
                            ),
                          ],
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
