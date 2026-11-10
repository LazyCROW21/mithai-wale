import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/app_state_providers.dart';
import '../../../l10n/l10n.dart';

/// Card component allowing the user to select the app language.
/// Supports English ('en'), Gujarati ('gu'), and System Default (null).
class LanguageSelectorCard extends ConsumerWidget {
  const LanguageSelectorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final localeAsync = ref.watch(localeProvider);
    final currentLocale = localeAsync.valueOrNull;

    // Determine current selection code: 'en', 'gu', or 'system'
    final selectedCode = currentLocale?.languageCode ?? 'system';

    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: RadioGroup<String>(
        groupValue: selectedCode,
        onChanged: (val) {
          if (val == 'en') {
            ref.read(localeProvider.notifier).setLocale(const Locale('en'));
          } else if (val == 'gu') {
            ref.read(localeProvider.notifier).setLocale(const Locale('gu'));
          } else {
            ref.read(localeProvider.notifier).setLocale(null);
          }
        },
        child: Column(
          children: [
            RadioListTile<String>(
              title: Text(l10n.themeSystem),
              subtitle: Text(l10n.languageSubtitle),
              secondary: const Icon(Icons.language),
              value: 'system',
            ),
            const Divider(height: 1),
            RadioListTile<String>(
              title: Text(l10n.languageEnglish),
              subtitle: const Text('English (Default)'),
              secondary: const Text('🇬🇧', style: TextStyle(fontSize: 22)),
              value: 'en',
            ),
            const Divider(height: 1),
            RadioListTile<String>(
              title: Text(l10n.languageGujarati),
              subtitle: const Text('ગુજરાતીમાં ઉપયોગ કરો'),
              secondary: const Text('🇮🇳', style: TextStyle(fontSize: 22)),
              value: 'gu',
            ),
          ],
        ),
      ),
    );
  }
}
