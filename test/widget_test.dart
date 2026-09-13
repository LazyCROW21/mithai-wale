// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';

import 'package:mithai_wale/main.dart';

void main() {
  testWidgets('App smoke test — home page renders', (WidgetTester tester) async {
    // Build the app. DatabaseProvider.init() is skipped in widget tests
    // because the DB is not initialised; test against the widget tree only.
    await tester.pumpWidget(const MithaiWaleApp());
    await tester.pump();

    // The app title should appear somewhere in the widget tree.
    expect(find.text('मिठाई वाले'), findsWidgets);
  });
}
