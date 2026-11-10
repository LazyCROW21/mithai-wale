// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mithai_wale/core/state/app_state_providers.dart';
import 'package:mithai_wale/main.dart';

void main() {
  testWidgets('App smoke test — home page renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith(() => _MockThemeModeNotifier()),
        ],
        child: const MithaiWaleApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The app title should appear somewhere in the widget tree.
    expect(find.text('मिठाई वाले'), findsWidgets);
  });
}

class _MockThemeModeNotifier extends ThemeModeNotifier {
  @override
  Future<ThemeMode> build() async => ThemeMode.light;
}
