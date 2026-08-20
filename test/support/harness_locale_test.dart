import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Pins three framework facts this epic's tests stand on, and that E04 changes.
///
/// The test names are the documentation. Each one exists so the `fa`/`ckb`
/// delegate gap is discovered here, in a handful of lines, rather than in a
/// game screen in E09.
/// Consumes the framework's "locale is not supported by all of its
/// localization delegates" warning.
///
/// It is reported as a caught error, so a test that ignores it fails for the
/// wrong reason. It is also the **third** fact this file pins: under `fa` with
/// only the default delegates, Flutter itself says the app is misconfigured.
/// **E04 makes this warning stop happening**, and every call here disappears
/// with it.
void expectDelegateWarning(WidgetTester tester) {
  final error = tester.takeException();

  expect(
    error.toString(),
    contains('is not supported by all of its localization delegates'),
    reason: 'expected the framework delegate warning under a non-en locale',
  );
}

void main() {
  final theme = ThemeData();

  testWidgets('pumping a non-en locale resolves that locale', (tester) async {
    late Locale resolved;

    await tester.pumpApp(
      Builder(
        builder: (context) {
          resolved = Localizations.localeOf(context);
          return const SizedBox.shrink();
        },
      ),
      theme: theme,
      locale: const Locale('fa'),
    );

    expect(resolved, const Locale('fa'));
    expectDelegateWarning(tester);
  });

  testWidgets('the default delegates report LTR for fa — E04 replaces this', (
    tester,
  ) async {
    late TextDirection withoutOverride;

    await tester.pumpApp(
      Builder(
        builder: (context) {
          withoutOverride = Directionality.of(context);
          return const SizedBox.shrink();
        },
      ),
      theme: theme,
      locale: const Locale('fa'),
    );
    expectDelegateWarning(tester);

    expect(
      withoutOverride,
      TextDirection.ltr,
      reason:
          'measured on Flutter 3.44.6: Localizations supplies the ambient '
          'Directionality from WidgetsLocalizations.textDirection, '
          '_WidgetsLocalizationsDelegate.isSupported returns true for EVERY '
          'locale, and DefaultWidgetsLocalizations.textDirection is hardcoded '
          'ltr. So pumping locale: fa yields an LTR tree, silently. Any RTL '
          'claim in E03 is a stand-in, and this test is where that is written '
          'down',
    );

    late TextDirection withOverride;
    await tester.pumpApp(
      Builder(
        builder: (context) {
          withOverride = Directionality.of(context);
          return const SizedBox.shrink();
        },
      ),
      theme: theme,
      locale: const Locale('fa'),
      textDirection: TextDirection.rtl,
    );
    expectDelegateWarning(tester);

    expect(withOverride, TextDirection.rtl);
  });

  testWidgets('MaterialLocalizations is absent under fa today', (tester) async {
    Object? lookupError;

    await tester.pumpApp(
      Builder(
        builder: (context) {
          // A Scaffold alone does not read this, so asserting on a Scaffold
          // proves nothing. Reading it directly IS the fact: every Tooltip,
          // SnackBar and AppBar back button does exactly this.
          //
          // Caught here rather than allowed to escape, so the pump raises only
          // the framework's delegate warning and takeException() returns that
          // one error instead of a "multiple exceptions" summary that names
          // neither.
          try {
            MaterialLocalizations.of(context);
          } on Object catch (error) {
            lookupError = error;
          }
          return const SizedBox.shrink();
        },
      ),
      theme: theme,
      locale: const Locale('fa'),
    );

    expectDelegateWarning(tester);

    expect(
      lookupError,
      isNotNull,
      reason:
          'DefaultMaterialLocalizations.delegate.isSupported is '
          "locale.languageCode == 'en', and Localizations._loadAll filters "
          'delegates by isSupported. Under fa with only the default delegates '
          'there is no MaterialLocalizations in scope at all',
    );
    expect(
      lookupError.toString(),
      contains('MaterialLocalizations'),
      reason:
          'E04 DELETES this test in the commit that adds the delegate '
          'trio, and its deletion is part of that epic proof',
    );
  });
}
