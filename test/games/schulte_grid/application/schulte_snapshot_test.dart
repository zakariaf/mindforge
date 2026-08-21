import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/hud_tone.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/games/schulte_grid/application/schulte_board_notifier.dart';
import 'package:mindforge/games/schulte_grid/application/schulte_snapshot.dart';
import 'package:mindforge/l10n/bidi_text.dart';
import 'package:mindforge/l10n/l10n_providers.dart';
import 'package:mindforge/l10n/locale_numbers.dart';
import 'package:mindforge/shared/feedback/feedback_service.dart';

import '../../../support/fake_feedback_service.dart';

/// What the shell reads off this board, in four locales.
void main() {
  // `localeProvider` resolves the system locale through the platform
  // dispatcher, so the binding has to exist even though nothing here pumps a
  // widget.
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  final config = RunConfig(
    gameId: GameId('schulte_grid'),
    difficulty: Difficulty.classic,
    seed: 42,
  );

  ProviderContainer containerFor(SupportedLocale locale) {
    final settings = const AppSettings.defaults().withLocaleOverride(locale);
    final container = ProviderContainer(
      overrides: [
        feedbackServiceProvider.overrideWithValue(FakeFeedbackService()),
        initialAppSettingsProvider.overrideWithValue(settings),
        settingsProvider.overrideWith(
          (ref) => Stream<AppSettings>.value(settings),
        ),
      ],
    );

    addTearDown(container.dispose);

    return container;
  }

  /// Starts the board and finds [count] tiles in order.
  BoardSnapshot snapshotAfter(ProviderContainer c, int count) {
    final notifier = c.read(schulteBoardNotifierProvider(config).notifier)
      ..start();

    for (var value = 1; value <= count; value++) {
      notifier.tapCell(
        c.read(schulteBoardNotifierProvider(config)).cells.indexOf(value),
      );
    }

    return c.read(schulteSnapshotProvider(config));
  }

  group('the three slots', () {
    test('Time is the shell own clock, published empty', () {
      // Rule 4. A game that filled it would desynchronise across a pause,
      // because the shell stops its ticker and the board would not know.
      final slot = snapshotAfter(
        containerFor(SupportedLocale.en),
        0,
      ).hud.leading;

      expect(slot.labelKey, 'hudTime');
      expect(slot.canonicalValue, 0);
      expect(slot.source, HudSource.runClock);
    });

    test('Next is the value being hunted, and it is the only highlight', () {
      final hud = snapshotAfter(containerFor(SupportedLocale.en), 0).hud;

      expect(hud.trailing!.labelKey, 'hudNext');
      expect(hud.trailing!.canonicalValue, 1);
      expect(
        hud.slots.where((s) => s.tone == HudTone.highlight),
        hasLength(1),
      );
      expect(
        hud.slots.where((s) => s.tone == HudTone.alarm),
        isEmpty,
        reason: 'the alarm is the shell own judgement against the run limit',
      );
    });

    test('and Found is a fraction the shell renders, not a string', () {
      // The value crossing the seam is a canonical INTEGER pair. A board that
      // formatted "6 / 25" itself would be deciding the separator, the digits
      // and the isolation — three decisions that belong to the locale.
      final slot = snapshotAfter(
        containerFor(SupportedLocale.en),
        6,
      ).hud.middle;

      expect(slot.labelKey, 'hudFound');
      expect(slot.format, StatFormat.fraction);
      expect(slot.canonicalValue, 6);
      expect(slot.total, 25);
    });
  });

  group('progress', () {
    test('is foundCount over cellCount, and is not localized', () {
      // Geometry, not text: the track's width is a double in every language.
      expect(snapshotAfter(containerFor(SupportedLocale.en), 0).progress, 0.0);
      expect(snapshotAfter(containerFor(SupportedLocale.fa), 6).progress, 0.24);
      expect(snapshotAfter(containerFor(SupportedLocale.en), 25).progress, 1.0);
    });
  });

  group('the outcome', () {
    test('is null until the last tile, and non-null exactly once', () {
      for (var found = 0; found < 25; found++) {
        expect(
          snapshotAfter(containerFor(SupportedLocale.en), found).outcome,
          isNull,
          reason: 'ended early at $found',
        );
      }

      expect(
        snapshotAfter(containerFor(SupportedLocale.en), 25).outcome,
        isNotNull,
      );
    });

    test('and it carries integers, never a rendered score', () {
      final done = snapshotAfter(containerFor(SupportedLocale.fa), 25);

      expect(done.correctCount, 25);
      expect(done.score, 25);
    });
  });

  group('every locale', () {
    /// What the HUD's Found pill reads, as the shell will render it.
    String renderFound(SupportedLocale locale, int found) {
      final container = containerFor(locale);
      final slot = snapshotAfter(container, found).hud.middle;
      final numbers = container.read(localeNumbersProvider);

      return BidiText.isolate(
        container
            .read(appLocalizationsProvider)
            .foundOfTotal(
              numbers.count(slot.canonicalValue),
              numbers.count(slot.total!),
            ),
      );
    }

    const expected = <SupportedLocale, String>{
      SupportedLocale.en: '6 / 25',
      SupportedLocale.de: '6 / 25',
      SupportedLocale.fa: '۶ / ۲۵',
      SupportedLocale.ckb: '۶ / ۲۵',
    };

    for (final entry in expected.entries) {
      test('renders Found as ${entry.value} in ${entry.key.tag}', () {
        expect(BidiText.strip(renderFound(entry.key, 6)), entry.value);
      });
    }

    test('and the RTL digits are U+06Fx, never the Arabic block', () {
      // THE NAMED ckb TEST, asserted per locale rather than inherited. `intl`
      // ships no ckb symbols, so an unpinned formatter resolves to the default
      // and emits Latin digits while fa still looks right — and U+0660-0669 is
      // the Arabic block, which is the wrong SHAPE for a Persian or Sorani
      // reader even though it is also "Eastern Arabic".
      for (final locale in <SupportedLocale>[
        SupportedLocale.fa,
        SupportedLocale.ckb,
      ]) {
        final digits = BidiText.strip(
          renderFound(locale, 6),
        ).runes.where((r) => r > 0x30);

        for (final rune in digits.where((r) => r != 0x20 && r != 0x2F)) {
          expect(
            rune,
            inInclusiveRange(0x06F0, 0x06F9),
            reason:
                '${locale.tag} emitted U+${rune.toRadixString(16)} — '
                'Latin digits or the Arabic block',
          );
        }
      }
    });

    test('and the fraction is isolated, or RTL reverses it', () {
      // `۶ / ۲۵` inside an RTL line renders as `۲۵ / ۶` without this: the
      // spaces and the slash are neutrals that take the paragraph direction.
      // Invisible in an LTR test run, which is why it is asserted on the
      // string rather than eyeballed in a golden.
      expect(BidiText.isIsolated(renderFound(SupportedLocale.fa, 6)), isTrue);
    });

    test('and every rendered count normalises back to its integer', () {
      for (final locale in SupportedLocale.values) {
        for (var found = 0; found <= 25; found++) {
          final numerator = BidiText.strip(
            renderFound(locale, found),
          ).split('/').first.trim();

          expect(
            int.parse(AsciiNumerals.normalize(numerator)),
            found,
            reason: '${locale.tag} at $found',
          );
        }
      }
    });
  });
}
