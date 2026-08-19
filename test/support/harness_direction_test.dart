import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';
import 'locale_cases.dart';

/// `pumpApp` used to hand `MaterialApp` no delegates at all, so every locale
/// resolved through `DefaultWidgetsLocalizations` — hardcoded LTR. Its own doc
/// claimed the opposite. That is the silent half of the `ckb` bug, in the
/// harness rather than the app.
void main() {
  for (final localeCase in LocaleCase.all) {
    testWidgets('pumpApp resolves ${localeCase.tag} to its real direction', (
      tester,
    ) async {
      late TextDirection resolved;

      await tester.pumpApp(
        Builder(
          builder: (context) {
            resolved = Directionality.of(context);
            return const SizedBox.shrink();
          },
        ),
        locale: localeCase.flutterLocale,
      );

      expect(tester.takeException(), isNull);
      expect(resolved, localeCase.direction);
    });
  }
}
