import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/games/game_registry.dart';
import 'package:mindforge/l10n/locale_resolution.dart';
import 'package:mindforge/l10n/supported_locales.dart';
import 'package:mindforge/theme/sunburst_theme.dart';

import 'locale_cases.dart';
import 'shell_harness.dart';

void main() {
  Widget probe(void Function(BuildContext context) read) => Builder(
    builder: (context) {
      read(context);
      return const SizedBox.shrink();
    },
  );

  group('the reference device', () {
    testWidgets('is pinned in physical pixels at DPR 2', (tester) async {
      // DPR 2, NOT 3: that is what capture-screens.sh rendered both PNG sets
      // at, and a golden blessed at DPR 3 cannot be laid beside a DPR-2
      // reference. E03 pinned it; this is the tripwire that stops a later
      // epic changing it quietly.
      await tester.pumpShellApp(const MindForgeApp());

      expect(tester.view.physicalSize, const Size(780, 1688));
      expect(tester.view.devicePixelRatio, 2.0);
    });

    testWidgets('and the view resets between tests', (tester) async {
      // Proves addTearDown(view.reset) fired in the test above.
      expect(tester.view.physicalSize, isNot(const Size(780, 1688)));
    });

    testWidgets('and MediaQuery carries the logical size, not a bare data', (
      tester,
    ) async {
      // A bare MediaQueryData() would zero the size. This is what catches it.
      late Size size;

      await tester.pumpShellApp(
        _AppWith(probe((context) => size = MediaQuery.sizeOf(context))),
      );

      expect(size, const Size(390, 844));
    });
  });

  group('every shipped locale', () {
    for (final localeCase in LocaleCase.all) {
      testWidgets('${localeCase.tag} resolves its own direction', (
        tester,
      ) async {
        // pumpLocalized asserts this itself; the value here is that the SHELL
        // harness routes through it rather than building its own chain.
        late TextDirection direction;
        late Locale locale;

        await tester.pumpShellApp(
          _AppWith(
            probe((context) {
              direction = Directionality.of(context);
              locale = Localizations.localeOf(context);
            }),
          ),
          localeCase: localeCase,
        );

        expect(direction, localeCase.direction);
        expect(locale.toLanguageTag(), localeCase.tag);
      });
    }

    testWidgets('and ckb pumps the whole app without throwing', (tester) async {
      // THE SHARP ONE. GlobalMaterialLocalizations ships no ckb, so pumping
      // Material under Sorani exercises E04's vendored delegate trio — a
      // missing entry throws on the first widget that asks for a tooltip
      // string. If this reds, stop: it is an E04 defect, not something a shell
      // screen patches.
      await tester.pumpShellApp(
        const MindForgeApp(),
        localeCase: LocaleCase.sorani,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('the app composition', () {
    testWidgets('registers the placeholder games', (tester) async {
      late List<String> ids;

      await tester.pumpShellApp(
        _AppWith(
          Consumer(
            builder: (context, ref, _) {
              ids = ref
                  .watch(gameRegistryProvider)
                  .map((game) => game.id.value)
                  .toList();
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(ids, hasLength(3));
    });

    testWidgets('and the repository accepts exactly those ids', (tester) async {
      // The wiring bootstrap() does. Without it every save fails, silently,
      // because saveRun refuses an id outside this set.
      late Set<String> accepted;

      await tester.pumpShellApp(
        _AppWith(
          Consumer(
            builder: (context, ref, _) {
              accepted = ref.watch(registeredGameIdsProvider);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(accepted, <String>{
        'placeholder_coral',
        'placeholder_turquoise',
        'placeholder_locked',
      });
    });
  });
}

/// The real app's theme and delegates, around one probe widget.
///
/// `pumpShellApp` pumps an APP, so a test that only wants to read a value from
/// the app's context wraps it in one rather than pumping a bare widget — which
/// would have no Localizations and no theme to read.
class _AppWith extends StatelessWidget {
  const _AppWith(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (context, ref, _) => MaterialApp(
      theme: buildSunburstTheme(),
      locale: Locale(ref.watch(localeProvider).tag),
      supportedLocales: supportedLocales,
      localizationsDelegates: appLocalizationsDelegates,
      home: child,
    ),
  );
}
