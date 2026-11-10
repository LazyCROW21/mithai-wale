import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../../../core/state/app_state_providers.dart';
import '../../../l10n/l10n.dart';
import '../../menu/widgets/manage_categories_dialog.dart';
import '../widgets/language_selector_card.dart';

class SettingsMobileView extends ConsumerWidget {
  const SettingsMobileView({super.key});

  static const _navRoutes = [
    AppRoutes.home,
    AppRoutes.shop,
    AppRoutes.orders,
    AppRoutes.profile,
    AppRoutes.settings,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? ThemeMode.system;
    final cs = Theme.of(context).colorScheme;

    final navItems = [
      NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l10n.navHome),
      NavigationDestination(icon: const Icon(Icons.store_outlined), selectedIcon: const Icon(Icons.store), label: l10n.navShop),
      NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: l10n.navOrders),
      NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: l10n.navProfile),
      NavigationDestination(icon: const Icon(Icons.settings), selectedIcon: const Icon(Icons.settings), label: l10n.navSettings),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navSettings, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language Settings Card
          Text(l10n.language, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const LanguageSelectorCard(),
          const SizedBox(height: 20),

          // Menu & Catalog Management Card
          Card(
            color: cs.primaryContainer.withAlpha(80),
            elevation: 1,
            shadowColor: Colors.black12,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.restaurant_menu, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.menuCatalogManagement,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.menuCatalogDesc,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => AppNav.go(AppRoutes.menu),
                          icon: const Icon(Icons.edit_note),
                          label: Text(l10n.openMenu),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => showManageCategoriesModal(context),
                        icon: const Icon(Icons.category_outlined),
                        label: Text(l10n.categories),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Theme Settings
          Text(l10n.appearance, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
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
          const SizedBox(height: 20),

          // Store Info
          Text(l10n.storeInformation, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            elevation: 1,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storefront),
                  title: Text(l10n.storeName),
                  subtitle: Text(l10n.appName),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.currency_rupee),
                  title: Text(l10n.currency),
                  subtitle: Text(l10n.currencyValue),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 4,
        onDestinationSelected: (i) => AppNav.go(_navRoutes[i]),
        destinations: navItems,
      ),
    );
  }
}
