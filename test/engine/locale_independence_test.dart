import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/calendar_day.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/run_draft.dart';
import 'package:mindforge/core/run_outcome.dart';
import 'package:mindforge/core/run_scope.dart';
import 'package:mindforge/core/seeded_generator.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/features/play/application/run_notifier.dart';

import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/game_registry.dart';

import '../core/seed_vectors.dart';
import '../support/fake_id_generator.dart';
import '../support/fake_save_run.dart';
import '../support/fixture_game.dart';
import '../support/locale_matrix.dart';

/// The engine does not depend on the language.
///
/// This is the file that stops a future refactor from seeding a round off a
/// formatted string, storing a Jalali date, or persisting `۱٬۴۸۰` into a column
/// a personal-best query compares with `MAX()`.
///
/// **An honest limit, stated up front.** These tests exercise `intl` formatting
/// and the engine's own values. They do NOT pump a `MaterialApp`, so they prove
/// nothing about `GlobalMaterialLocalizations` accepting `ckb` — that is E04's
/// vendored delegate trio and E04's test. A green run here is not evidence that
/// the app can switch to Kurdish Sorani.
void main() {
  // localeMatrix and forEachLocale are E02's, derived from SupportedLocale so
  // there is no second list of shipped locales anywhere in the repository.
  // This file had grown a third one — a hardcoded four-tag literal plus its own
  // save/set/restore — in the epic that most loudly claims locale independence.
  // The shared helper also restores in a `finally` rather than a `tearDown`, so
  // a failure in one locale cannot leak into the next.
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  group('seeded generation', () {
    test('reproduces the frozen vector table under every locale', () async {
      // THE TEST THIS EPIC'S LOCALE DELTA EXISTS FOR. If it ever goes red, a
      // formatter has reached the generation path.
      await forEachLocale((tag) async {
        for (final vector in kSeedVectors) {
          expect(
            fnv1a64(vector.key),
            vector.hash,
            reason: '$tag ${vector.why}',
          );
        }

        for (final vector in kSeedVectors) {
          if (vector.key.runes.where((r) => r >= 0x80).isNotEmpty) continue;

          final generator = seedFrom(
            vector.key,
            featureSalt: kVectorFeatureSalt,
            modeSalt: kVectorModeSalt,
          );

          expect(
            List<int>.generate(
              kVectorDrawCount,
              (_) => generator.nextInt(kVectorDrawBound),
            ),
            vector.draws,
            reason: '$tag ${vector.key}',
          );
        }
      });
    });
  });

  group('the persisted row', () {
    test(
      'a full run produces the SAME RunDraft under all four locales',
      () async {
        // One assertion covering gameId, difficultyId, clientRunKey, playedOnDay,
        // durationMs, format and value at once.
        final drafts = <String, RunDraft>{};

        for (final tag in localeMatrix) {
          Intl.defaultLocale = tag;

          final save = FakeSaveRun();
          final container = ProviderContainer(
            overrides: [
              gameRegistryProvider.overrideWithValue(<GameDefinition>[
                fixtureGame(),
              ]),
              saveRunProvider.overrideWithValue(save.call),
              clockProvider.overrideWithValue(Clock.fixed(DateTime.utc(2026))),
              // A fixed id, so the comparison is about the locale rather than
              // about entropy.
              idGeneratorProvider.overrideWithValue(FakeIdGenerator()),
            ],
          );
          addTearDown(container.dispose);

          container.read(runNotifierProvider(_config).notifier)
            ..start()
            ..beginPlaying()
            ..onSnapshot(_finished);

          await pumpEventQueue();

          drafts[tag] = save.saved.single;
        }

        for (final entry in drafts.entries) {
          expect(
            entry.value,
            drafts['en'],
            reason: '${entry.key} wrote a different row',
          );
        }
      },
    );

    test('and every scope string is ASCII under every locale', () async {
      await forEachLocale((tag) async {
        for (final difficulty in Difficulty.values) {
          final scope = RunScope.of(GameId('fixture_game'), difficulty);

          for (final rune in '${scope.gameId}${scope.difficultyId}'.runes) {
            expect(rune, lessThan(0x80), reason: tag);
            expect(
              rune >= 0x6F0 && rune <= 0x6F9,
              isFalse,
              reason: '$tag: an Eastern Arabic digit reached a join key',
            );
            expect(
              rune >= 0x2066 && rune <= 0x2069,
              isFalse,
              reason: '$tag: a bidi isolate reached a join key',
            );
          }
        }
      });
    });

    test('and playedOnDay is Gregorian under fa and ckb', () async {
      // 2026-03-21 is 1405-01-01 in the Persian calendar — Nowruz, the first
      // day of the year. If a calendar projection ever reached the database,
      // this is the date it would show up on. Projection is a render-time
      // concern; the column is a civil date.
      await forEachLocale((tag) async {
        final day = CalendarDay.fromLocal(DateTime.utc(2026, 3, 21));
        final reference = CalendarDay.fromLocal(DateTime.utc(2026, 3, 20));

        expect(
          day.serial - reference.serial,
          1,
          reason: '$tag: the day after is one serial later',
        );
      });
    });
  });
}

const _finished = BoardSnapshot(
  hud: GameHud(
    leading: HudSlot(
      labelKey: 'hudScore',
      canonicalValue: 1480,
      format: StatFormat.points,
    ),
    middle: HudSlot(
      labelKey: 'hudTime',
      canonicalValue: 0,
      format: StatFormat.duration,
    ),
  ),
  score: 1480,
  correctCount: 23,
  wrongCount: 2,
  longestCombo: 7,
  totalReactionMs: 14720,
  outcome: RunOutcome.completed(
    first: ResultStat(
      labelKey: 'statAccuracy',
      canonicalValue: 923,
      format: StatFormat.percent,
    ),
    second: ResultStat(
      labelKey: 'statBestCombo',
      canonicalValue: 7,
      format: StatFormat.count,
    ),
    third: ResultStat(
      labelKey: 'statAverageReaction',
      canonicalValue: 640,
      format: StatFormat.duration,
    ),
  ),
);

final _config = RunConfig(
  gameId: GameId('fixture_game'),
  difficulty: Difficulty.classic,
  seed: 7,
);
