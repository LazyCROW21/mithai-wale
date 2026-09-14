import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../../../core/state/app_state_providers.dart';
import '../../menu/widgets/manage_categories_dialog.dart';

class SettingsTabletView extends ConsumerWidget {
  const SettingsTabletView({super.key});

  static const _navRoutes = [
    AppRoutes.home,
    AppRoutes.shop,
    AppRoutes.orders,
    AppRoutes.profile,
    AppRoutes.settings,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? ThemeMode.system;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: 4,
            onDestinationSelected: (i) => AppNav.go(_navRoutes[i]),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
              NavigationRailDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: Text('Shop')),
              NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Orders')),
              NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profile')),
              NavigationRailDestination(icon: Icon(Icons.settings), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Card(
                  color: cs.primaryContainer.withAlpha(80),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Menu & Catalog Management',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Manage items, auto-generated IDs, pricing, units (per piece, gm, kg, litre) and categories.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: () => showManageCategoriesModal(context),
                          icon: const Icon(Icons.category_outlined),
                          label: const Text('Manage Categories'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: () => AppNav.go(AppRoutes.menu),
                          icon: const Icon(Icons.edit_note),
                          label: const Text('Open Menu Management'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Appearance', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant)),
                  child: Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        title: const Text('System Default'),
                        value: ThemeMode.system,
                        groupValue: themeMode,
                        onChanged: (mode) {
                          if (mode != null) ref.read(themeModeProvider.notifier).setThemeMode(mode);
                        },
                      ),
                      const Divider(height: 1),
                      RadioListTile<ThemeMode>(
                        title: const Text('Light Mode'),
                        value: ThemeMode.light,
                        groupValue: themeMode,
                        onChanged: (mode) {
                          if (mode != null) ref.read(themeModeProvider.notifier).setThemeMode(mode);
                        },
                      ),
                      const Divider(height: 1),
                      RadioListTile<ThemeMode>(
                        title: const Text('Dark Mode'),
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
    );
  }
}
