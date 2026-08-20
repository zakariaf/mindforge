import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/ckb_localizations.dart';
import 'package:mindforge/l10n/supported_locales.dart';
import 'package:mindforge/theme/sunburst_theme.dart';

import 'locale_cases.dart';

/// A logical viewport a test can render at.
///
/// Every preset is at **DPR 2**, deliberately: that is the exact geometry
/// `design/sunburst-pop/capture-screens.sh` rendered the eight reference PNGs
/// at (780×1688 = 390×844 @2), and also the `MindForge iPhone 14` simulator's
/// logical size. A golden lane at DPR 3 cannot be laid beside a DPR-2
/// reference, so one number serves every consumer.
@immutable
final class Device {
  /// Creates a device preset.
  const Device(this.name, {required this.logicalSize, required this.dpr});

  /// A short label used in golden file names and test descriptions.
  final String name;

  /// The viewport in logical points.
  final Size logicalSize;

  /// The device pixel ratio.
  final double dpr;

  /// The narrowest phone the layout must survive.
  static const compact320 = Device(
    '320',
    logicalSize: Size(320, 640),
    dpr: 2,
  );

  /// A common small phone.
  static const small360 = Device('360', logicalSize: Size(360, 800), dpr: 2);

  /// **The reference.** 390×844 — the geometry of every PNG under
  /// `design/sunburst-pop/screens/` and of the canonical simulator
  /// `MindForge iPhone 14` (`C13DDC02-375D-4E1B-8F81-44EB407D09A4`).
  static const reference390 = Device(
    '390',
    logicalSize: Size(390, 844),
    dpr: 2,
  );

  /// A large phone.
  static const large430 = Device('430', logicalSize: Size(430, 932), dpr: 2);

  /// The one size matrix in the repository. E05, E08, E09, E10 and E11 all
  /// iterate this list rather than declaring their own.
  static const all = <Device>[compact320, small360, reference390, large430];

  @override
  String toString() => 'Device($name @${dpr}x)';
}

/// Sizes the test viewport to `device` and restores it afterwards.
void useDevice(WidgetTester tester, Device device) {
  final view = tester.view
    ..devicePixelRatio = device.dpr
    ..physicalSize = device.logicalSize * device.dpr;

  addTearDown(view.reset);
}

/// Pumps a widget inside the app shell a real screen sees.
extension PumpApp on WidgetTester {
  /// Pumps [child] in [localeCase]'s locale, with the **real** delegate list.
  ///
  /// This is what E05 and every later epic use for a locale matrix, and it
  /// differs from [pumpApp] in the way that matters: it does **not** take a
  /// `textDirection`. Direction follows the locale through `Localizations`,
  /// exactly as it does in production, so a component that assumed a physical
  /// side fails here rather than being pinned upright by the harness.
  ///
  /// It also asserts the direction it got, so a delegate regression surfaces as
  /// a failure in whichever test noticed rather than as silently mirrored
  /// pixels in a golden nobody re-read.
  Future<void> pumpLocalized(
    Widget child,
    LocaleCase localeCase, {
    ThemeData? theme,
    bool disableAnimations = false,
    TextScaler textScaler = TextScaler.noScaling,
    bool boldText = false,
  }) async {
    late TextDirection resolved;

    await pumpWidget(
      ProviderScope(
        // MediaQuery is layered ABOVE MaterialApp, and built with
        // MediaQueryData.fromView rather than a bare MediaQueryData():
        // constructing one from scratch drops padding, view insets and every
        // accessibility flag the real app reads, and layering it below
        // MaterialApp would leave MaterialApp itself reading the unscaled one.
        child: MediaQuery(
          data: MediaQueryData.fromView(view).copyWith(
            disableAnimations: disableAnimations,
            textScaler: textScaler,
            boldText: boldText,
          ),
          child: MaterialApp(
            theme: theme ?? buildSunburstTheme(),
            locale: localeCase.flutterLocale,
            supportedLocales: supportedLocales,
            localizationsDelegates: localizationsDelegatesFor(
              AppLocalizations.localizationsDelegates,
            ),
            home: Builder(
              builder: (context) {
                resolved = Directionality.of(context);
                return child;
              },
            ),
          ),
        ),
      ),
    );

    expect(
      resolved,
      localeCase.direction,
      reason:
          'the ambient direction under ${localeCase.tag} is not what the '
          'locale requires. That is a delegate regression, and it would '
          'otherwise show up as silently mirrored pixels in a golden nobody '
          're-read',
    );
  }

  /// Pumps a throwaway tree in [localeCase] and returns [read] of its context.
  ///
  /// The `late X captured; pumpLocalized(Builder(...))` idiom was written out
  /// eight times across four files, ten lines each, to get one value out of a
  /// pumped tree. Usually the value is an inherited lookup:
  ///
  /// ```dart
  /// final l10n = await tester.readInLocale(localeCase, AppLocalizations.of);
  /// ```
  Future<T> readInLocale<T>(
    LocaleCase localeCase,
    T Function(BuildContext context) read, {
    ThemeData? theme,
  }) async {
    late T value;

    await pumpLocalized(
      Builder(
        builder: (context) {
          value = read(context);
          return const SizedBox.shrink();
        },
      ),
      localeCase,
      theme: theme,
    );

    return value;
  }

  /// Pumps [child] under a `MaterialApp` carrying [theme].
  ///
  /// **It takes no `textDirection`, deliberately.** It used to, as a test-only
  /// stand-in for the absent `GlobalWidgetsLocalizations` — E04 vendored those
  /// delegates, so direction now follows the locale here exactly as it does in
  /// production. A hardcoded root `Directionality` is precisely what hides a
  /// physical-side bug: it happens to look right. Use [pumpLocalized] when the
  /// locale matters.
  ///
  /// [theme] defaults to `buildSunburstTheme()`, the one theme the app ships.
  /// A task testing a single extension in isolation passes an inline
  /// `ThemeData(extensions: [...])` instead.
  ///
  /// There is deliberately **no `overrides` parameter yet**. Riverpod 3 does
  /// not export `Override` from `flutter_riverpod` — it lives behind
  /// `src/internals.dart` — so the type cannot be named here, and E03 has
  /// nothing to override anyway. E05 adds it, by whatever means Riverpod
  /// exposes then.
  ///
  Future<void> pumpApp(
    Widget child, {
    ThemeData? theme,
    Locale locale = const Locale('en'),
    bool disableAnimations = false,
  }) {
    return pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: theme ?? buildSunburstTheme(),
          locale: locale,
          supportedLocales: supportedLocales,
          // The REAL delegate list. Without it MaterialApp falls through to
          // DefaultWidgetsLocalizations, whose textDirection is hardcoded LTR
          // — measured: pumpApp(locale: Locale('ckb')) resolved to ltr, and a
          // test that calls takeException() ate the framework's warning and
          // then rendered Sorani left-to-right. The doc below said direction
          // followed the locale here; it did not until this line.
          localizationsDelegates: localizationsDelegatesFor(
            AppLocalizations.localizationsDelegates,
          ),
          home: Builder(
            builder: (context) => MediaQuery(
              // Layered ABOVE MaterialApp and built from .copyWith, never from
              // a bare MediaQueryData(): constructing one from scratch drops
              // padding, text scale and every accessibility flag the real app
              // reads.
              data: MediaQuery.of(context).copyWith(
                disableAnimations: disableAnimations,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
