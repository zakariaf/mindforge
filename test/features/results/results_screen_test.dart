import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/run_outcome.dart';
import 'package:mindforge/features/play/application/run_notifier.dart';
import 'package:mindforge/features/play/domain/run_phase.dart';
import 'package:mindforge/features/play/domain/run_state.dart';
import 'package:mindforge/features/results/ui/results_screen.dart';
import 'package:mindforge/features/shell/widgets/result_stat_cell.dart';
import 'package:mindforge/features/shell/widgets/score_slab.dart';
import 'package:mindforge/games/placeholder/placeholder_definitions.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/ui/components/pop_badge.dart';
import 'package:mindforge/ui/components/pop_bottom_nav.dart';

import '../../support/locale_cases.dart';
import '../../support/shell_harness.dart';

/// What a finished run says.
void main() {
  final config = RunConfig(
    gameId: placeholderCoralDefinition.id,
    difficulty: Difficulty.classic,
    seed: 7,
  );

  RunState finished({bool isPersonalBest = false}) => RunState(
    config: config,
    phase: RunPhase.over,
    elapsed: const Duration(seconds: 42),
    isPersonalBest: isPersonalBest,
    snapshot: const BoardSnapshot(
      hud: GameHud(
        leading: HudSlot(
          labelKey: 'hudScoreLabel',
          canonicalValue: 1240,
          format: StatFormat.points,
        ),
        middle: HudSlot(
          labelKey: 'hudTimeLabel',
          canonicalValue: 42000,
          format: StatFormat.duration,
        ),
      ),
      score: 1240,
      correctCount: 23,
      wrongCount: 2,
      longestCombo: 11,
      totalReactionMs: 14720,
      outcome: RunOutcome.completed(
        first: ResultStat(
          labelKey: 'accuracyLabel',
          format: StatFormat.percent,
          canonicalValue: 920,
        ),
        second: ResultStat(
          labelKey: 'avgReactionLabel',
          format: StatFormat.duration,
          canonicalValue: 640,
        ),
        third: ResultStat(
          labelKey: 'longestStreakLabel',
          format: StatFormat.count,
          canonicalValue: 11,
        ),
      ),
    ),
  );

  Future<void> pumpResults(
    WidgetTester tester, {
    bool isPersonalBest = false,
    LocaleCase? localeCase,
  }) => tester.pumpShellApp(
    ProviderScope(
      overrides: [
        runNotifierProvider(config).overrideWith(
          () => _FrozenRun(config, finished(isPersonalBest: isPersonalBest)),
        ),
      ],
      child: const MindForgeApp(),
    ),
    localeCase: localeCase,
    initialLocation: Routes.results(config),
  );

  group('the composition', () {
    testWidgets('is a score slab over three cells, and no bottom nav', (
      tester,
    ) async {
      await pumpResults(tester);

      expect(find.byType(ScoreSlab), findsOneWidget);
      expect(find.byType(ResultStatCell), findsNWidgets(3));
      expect(find.byType(PopBottomNav), findsNothing);
    });

    testWidgets('the three cells are turquoise, paper and coral in order', (
      tester,
    ) async {
      // app.html tones the trio by POSITION, not by what each cell means. A
      // uniform paper row is the transcription defect this catches.
      await pumpResults(tester);

      expect(
        tester
            .widgetList<ResultStatCell>(find.byType(ResultStatCell))
            .map((cell) => cell.tone),
        <ResultStatTone>[
          ResultStatTone.cool,
          ResultStatTone.paper,
          ResultStatTone.warm,
        ],
      );
    });

    testWidgets('and the score reaches the slab already formatted', (
      tester,
    ) async {
      await pumpResults(tester);

      expect(
        tester.widget<ScoreSlab>(find.byType(ScoreSlab)).value,
        '1,240',
      );
    });
  });

  group('the personal-best badge', () {
    testWidgets('is absent when the run did not beat anything', (tester) async {
      await pumpResults(tester);

      expect(find.byType(PopBadge), findsNothing);
    });

    testWidgets('and present, tilted, when it did', (tester) async {
      // It appears on the SAME edge the save succeeded on, so a celebration
      // can never outlive a failed insert.
      await pumpResults(tester, isPersonalBest: true);

      expect(
        tester.widget<PopBadge>(find.byType(PopBadge)).variant,
        PopBadgeVariant.best,
      );
    });
  });

  group('the numerals are the locale own', () {
    for (final localeCase in LocaleCase.rightToLeft) {
      testWidgets('${localeCase.tag} prints Eastern Arabic digits', (
        tester,
      ) async {
        await pumpResults(tester, localeCase: localeCase);

        expect(
          tester.widget<ScoreSlab>(find.byType(ScoreSlab)).value,
          contains('۱'),
          reason: 'the score fell back to Latin digits',
        );

        for (final cell in tester.widgetList<ResultStatCell>(
          find.byType(ResultStatCell),
        )) {
          expect(
            cell.value,
            matches(RegExp('[۰-۹]')),
            reason: '${cell.label} printed Latin digits',
          );
        }
      });
    }
  });

  group('the two ways out', () {
    testWidgets('Home returns to the hub', (tester) async {
      await pumpResults(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ResultsScreen)),
      );

      await tester.tap(find.text(l10n.homeButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The LOCATION, not the absence of a widget: go() unwinds to the shell
      // branch and the outgoing route is still in the tree while it does.
      expect(
        GoRouter.of(
          tester.element(find.byType(ResultsScreen)),
        ).state.uri.path,
        Routes.home,
      );
    });
  });
}

/// A run frozen in one state.
///
/// A real `RunNotifier` subclass rather than a mock: the family hands its
/// argument to the constructor, and the results screen reads the run through
/// exactly the provider the app uses. Its `build()` returns the state instead
/// of starting a ticker, which is the only thing a finished run does not need.
class _FrozenRun extends RunNotifier {
  _FrozenRun(super.config, this._frozen);

  final RunState _frozen;

  @override
  RunState build() => _frozen;
}
