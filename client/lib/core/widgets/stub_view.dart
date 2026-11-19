import 'package:flutter/material.dart';

/// Reusable placeholder widget for stub feature views.
/// Replace the [Scaffold] content with the real implementation when building
/// out each feature. Delete this file once all stubs are replaced.
class StubView extends StatelessWidget {
  const StubView({super.key, required this.featureName, required this.layoutTier});

  final String featureName;
  final String layoutTier;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(featureName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_rounded, size: 64, color: cs.primary),
            const SizedBox(height: 16),
            Text(
              '$featureName — $layoutTier',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Replace this stub with the real implementation.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
