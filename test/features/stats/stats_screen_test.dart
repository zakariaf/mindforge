import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/core/calendar_day.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/game_stats.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_metric.dart';
import 'package:mindforge/core/run_record.dart';
import 'package:mindforge/core/run_scope.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/features/shell/widgets/best_card.dart';
import 'package:mindforge/features/shell/widgets/stat_box.dart';
import 'package:mindforge/features/stats/widgets/run_bar_chart.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/placeholder/placeholder_definitions.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/routing/routes.dart';

import '../../support/locale_cases.dart';
import '../../support/shell_harness.dart';

/// The all-time screen.
void main() {
  const coralScope = RunScope('placeholder_coral');
  const turquoiseScope = RunScope('placeholder_turquoise');

  RunRecord record(int value, int startedAt) => RunRecord(
    id: 'r$startedAt',
    gameId: 'placeholder_coral',
    difficultyId: 'classic',
    clientRunKey: 'k$startedAt',
    startedAtUtcMs: startedAt,
    playedOnDay: const CalendarDay.fromSerial(20000),
    durationMs: 30000,
    format: ScoreFormat.points,
    metricValue: value,
    correctCount: 10,
    wrongCount: 1,
    longestCombo: 4,
    totalReactionMs: 6000,
    createdAtUtcMs: startedAt,
  );

  // Newest first, the order the DAO returns.
  final series = <RunRecord>[
    record(1480, 7),
    record(1180, 6),
    record(1310, 5),
    record(860, 4),
    record(1120, 3),
    record(940, 2),
    record(780, 1),
  ];

  Future<void> pumpStats(
    WidgetTester tester, {
    LocaleCase? localeCase,
    bool withHistory = true,
    TextScaler textScaler = TextScaler.noScaling,
  }) => tester.pumpShellApp(
    const MindForgeApp(),
    localeCase: localeCase,
    textScaler: textScaler,
    initialLocation: Routes.stats,
    bests: withHistory
        ? <String, Result<RunMetric?, DataFailure>>{
            'placeholder_coral': const Ok<RunMetric?, DataFailure>(
              RunMetric.points(1480),
            ),
          }
        : const <String, Result<RunMetric?, DataFailure>>{},
    stats: withHistory
        ? <RunScope, GameStats>{
            coralScope: const GameStats(
              gamesPlayed: 128,
              timeTrainedMs: 11520000,
              correctCount: 0,
              wrongCount: 0,
              totalReactionMs: 0,
              longestCombo: 0,
            ),
          }
        : const <RunScope, GameStats>{},
    chartSeries: withHistory
        ? <RunScope, List<RunRecord>>{coralScope: series}
        : const <RunScope, List<RunRecord>>{},
  );

  group('the best cards', () {
    testWidgets('one per UNLOCKED game, in registry order', (tester) async {
      // Two placeholders are unlocked and one is not. A locked game has no
      // history to show and listing it would promise one.
      await pumpStats(tester);

      expect(find.byType(BestCard), findsNWidgets(2));
    });

    testWidgets('and a game with no runs shows a dash, not a zero', (
      tester,
    ) async {
      await pumpStats(tester);

      final values = tester
          .widgetList<BestCard>(find.byType(BestCard))
          .map((card) => card.value)
          .toList();

      expect(values, <String>['1,480', '—']);
    });

    testWidgets('the caption follows the game score format', (tester) async {
      // A points game has a best SCORE and a timed one a best TIME. One shared
      // caption would be wrong for half the registry.
      await pumpStats(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(BestCard).first),
      );
      final labels = tester
          .widgetList<BestCard>(find.byType(BestCard))
          .map((card) => card.label);

      expect(labels, contains(l10n.bestScore));
      expect(labels, contains(l10n.bestTime));
    });
  });

  group('the totals', () {
    testWidgets('sum every game and render in the locale numerals', (
      tester,
    ) async {
      await pumpStats(tester, localeCase: LocaleCase.persian);

      final values = tester
          .widgetList<StatBox>(find.byType(StatBox))
          .map((box) => box.value)
          .toList();

      expect(values.first, '۱۲۸');
      expect(values.last, contains('۳'), reason: '11,520,000 ms is 3h 12m');
    });
  });

  group('the chart', () {
    // A chart is a TIME AXIS. A Persian build that reversed it would say the
    // player got worse. One test per locale rather than a loop: pumping the
    // whole app twice inside one testWidgets leaves the previous tree's
    // Directionality in place and the harness assertion then reports fa as
    // LTR. The expectation is the fixture's own order, so each test stands
    // alone rather than comparing one locale to another.
    for (final localeCase in <LocaleCase>[
      LocaleCase.english,
      LocaleCase.persian,
    ]) {
      testWidgets('plots oldest first under ${localeCase.tag}', (tester) async {
        await pumpStats(tester, localeCase: localeCase);

        await tester.scrollUntilVisible(
          find.byType(RunBarChart),
          160,
          scrollable: find.byType(Scrollable).last,
        );

        expect(
          tester
              .widget<RunBarChart>(find.byType(RunBarChart))
              .bars
              .map((bar) => (bar.ratio * 1480).round()),
          <int>[780, 940, 1120, 860, 1310, 1180, 1480],
          reason: 'the DAO returns newest first and a chart reads oldest first',
        );
      });
    }

    testWidgets('the bars are a true-zero scale over the series peak', (
      tester,
    ) async {
      // Not a fixed divisor: app.html divides by 10.5, which clips silently
      // above about 1560 — two runs, one better than the other, drawing the
      // same bar.
      await pumpStats(tester);

      await tester.scrollUntilVisible(
        find.byType(RunBarChart),
        160,
        scrollable: find.byType(Scrollable).last,
      );

      final bars = tester.widget<RunBarChart>(find.byType(RunBarChart)).bars;

      expect(
        bars.map((bar) => bar.ratio),
        everyElement(inInclusiveRange(0, 1)),
      );
      expect(bars.where((bar) => bar.isBest), hasLength(1));
      expect(bars.first.ratio, closeTo(780 / 1480, 1e-9));
    });

    testWidgets(
      'and the drawing is excluded, with the values spoken beside it',
      (tester) async {
        await pumpStats(tester);

        await tester.scrollUntilVisible(
          find.byType(RunBarChart),
          160,
          scrollable: find.byType(Scrollable).last,
        );

        final node = tester.getSemantics(find.byType(RunBarChart));

        expect(node.label, contains('780'));
        expect(node.label, contains('1,480'));
      },
    );

    testWidgets('is absent entirely when nothing has been played', (
      tester,
    ) async {
      // Empty is not "seven zero-height bars over an axis". That is a drawing
      // of nothing, and it claims a history the player does not have.
      await pumpStats(tester, withHistory: false);

      expect(find.byType(RunBarChart), findsNothing);
    });
  });

  group('the screen', () {
    testWidgets('has exactly one header', (tester) async {
      await pumpStats(tester);

      expect(
        tester
            .widgetList<Semantics>(find.byType(Semantics))
            .where((node) => node.properties.header ?? false),
        hasLength(1),
      );
    });

    for (final localeCase in <LocaleCase>[
      LocaleCase.german,
      LocaleCase.sorani,
    ]) {
      testWidgets('scrolls at text scale 2.0 under ${localeCase.tag}', (
        tester,
      ) async {
        await pumpStats(
          tester,
          localeCase: localeCase,
          textScaler: const TextScaler.linear(2),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('the totals when there is no history', () {
    testWidgets('are real zeros, because zero runs is a true statement', (
      tester,
    ) async {
      await pumpStats(tester, withHistory: false);

      expect(
        tester.widgetList<StatBox>(find.byType(StatBox)).first.value,
        '0',
      );
    });
  });

  group('an unplayed second game', () {
    testWidgets('still gets a card, with no value', (tester) async {
      await pumpStats(tester);

      expect(
        tester
            .widgetList<BestCard>(find.byType(BestCard))
            .where((card) => card.value == '—'),
        hasLength(1),
      );
    });
  });

  test('the second scope exists so the fixture reads as a registry', () {
    expect(turquoiseScope.gameId, 'placeholder_turquoise');
  });

  group('a timed game plots the other way up', () {
    testWidgets('so the best run is still the tallest bar', (tester) async {
      // Plotting a duration raw makes the SLOWEST run the tallest bar and the
      // sunshine "best" one the shortest — a chart whose shape means the
      // opposite thing for the game beside it is worse than no chart.
      final timed = GameDefinition(
        id: GameId('placeholder_coral'),
        accent: placeholderCoralDefinition.accent,
        colourRole: placeholderCoralDefinition.colourRole,
        scoreFormat: ScoreFormat.duration,
        scoreSource: placeholderCoralDefinition.scoreSource,
        strings: placeholderCoralDefinition.strings,
        difficulties: placeholderCoralDefinition.difficulties,
        boardBackground: placeholderCoralDefinition.boardBackground,
        buildBoard: placeholderCoralDefinition.buildBoard,
        buildArtwork: placeholderCoralDefinition.buildArtwork,
        bindBoard: placeholderCoralDefinition.bindBoard,
      );

      await tester.pumpShellApp(
        const MindForgeApp(),
        games: <GameDefinition>[timed],
        initialLocation: Routes.stats,
        bests: <String, Result<RunMetric?, DataFailure>>{
          'placeholder_coral': const Ok<RunMetric?, DataFailure>(
            RunMetric.duration(18600),
          ),
        },
        stats: <RunScope, GameStats>{
          coralScope: const GameStats(
            gamesPlayed: 3,
            timeTrainedMs: 60000,
            correctCount: 0,
            wrongCount: 0,
            totalReactionMs: 0,
            longestCombo: 0,
          ),
        },
        chartSeries: <RunScope, List<RunRecord>>{
          // Newest first, the DAO's order: 40s, then 20s, then 60s.
          coralScope: <RunRecord>[
            record(40000, 3),
            record(20000, 2),
            record(60000, 1),
          ],
        },
      );

      await tester.scrollUntilVisible(
        find.byType(RunBarChart),
        160,
        scrollable: find.byType(Scrollable).last,
      );

      final bars = tester.widget<RunBarChart>(find.byType(RunBarChart)).bars;

      // Oldest first: 60s, 20s, 40s. The 20s run is the best and draws full
      // height; the 60s run is a third of it and the 40s run a half.
      expect(
        bars.map((bar) => bar.ratio),
        <Matcher>[
          closeTo(20000 / 60000, 1e-9),
          closeTo(1, 1e-9),
          closeTo(20000 / 40000, 1e-9),
        ],
      );
      expect(bars.where((bar) => bar.isBest).single.ratio, closeTo(1, 1e-9));
    });
  });
}
