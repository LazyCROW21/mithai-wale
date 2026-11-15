import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_shell.dart';
import '../../../core/auth/auth_models.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../../../core/state/app_state_providers.dart';
import '../../../l10n/l10n.dart';
import '../../menu/widgets/manage_categories_dialog.dart';
import '../widgets/language_selector_card.dart';
import '../widgets/sync_card.dart';

class SettingsTabletView extends ConsumerWidget {
  const SettingsTabletView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canEditCatalog = ref.watch(sessionProvider).role != AppRole.employee;
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? ThemeMode.system;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: MoreBackButton.of(context),
        title: Text(l10n.navSettings, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Row(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Language Settings Card
                Text(l10n.language, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const LanguageSelectorCard(),
                const SizedBox(height: 24),
                const SyncCard(),
                const SizedBox(height: 24),

                // Menu & Catalog Management Card
                // Employees can view the menu but not manage the catalog.
                if (canEditCatalog)
                Card(
                  color: cs.primaryContainer.withAlpha(80),
                  elevation: 1,
                  shadowColor: Colors.black12,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.menuCatalogManagement,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.menuCatalogDesc,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
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
                const SizedBox(height: 24),

                // Appearance Settings
                Text(l10n.appearance, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
    );
  }
}
