import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_models.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../../../core/state/app_state_providers.dart';
import '../../../l10n/l10n.dart';
import '../../menu/widgets/manage_categories_dialog.dart';
import '../widgets/language_selector_card.dart';
import '../widgets/sync_card.dart';

class SettingsDesktopView extends ConsumerWidget {
  const SettingsDesktopView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canEditCatalog = ref.watch(sessionProvider).role != AppRole.employee;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? ThemeMode.system;


    return Scaffold(
      body: Row(
        children: [
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
                      const SyncCard(),
                      const SizedBox(height: 32),

                      // Menu Management Banner
                      // Employees can view the menu but not manage the catalog.
                      if (canEditCatalog)
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
