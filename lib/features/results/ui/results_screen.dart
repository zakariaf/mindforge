import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/run_outcome.dart';
import 'package:mindforge/features/play/application/run_notifier.dart';
import 'package:mindforge/features/shell/widgets/equal_row.dart';
import 'package:mindforge/features/shell/widgets/ray_header.dart';
import 'package:mindforge/features/shell/widgets/result_stat_cell.dart';
import 'package:mindforge/features/shell/widgets/score_slab.dart';
import 'package:mindforge/games/game_registry.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/difficulty_strings.dart';
import 'package:mindforge/l10n/game_strings.dart';
import 'package:mindforge/l10n/l10n_providers.dart';
import 'package:mindforge/l10n/score_formatter_provider.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/motion/pop_celebration.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_badge.dart';
import 'package:mindforge/ui/components/pop_button.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// What a finished run says.
///
/// **The personal-best badge only appears when the row was written.** The run
/// notifier sets `isPersonalBest` on the same edge that reports the save
/// succeeded, so a celebration here can never outlive a failed insert — the
/// player would have found it gone on the next launch.
class ResultsScreen extends ConsumerWidget {
  /// Creates the results for [config].
  const ResultsScreen({required this.config, super.key});

  /// The run that ended.
  final RunConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colours = SunburstColors.of(context);
    final type = SunburstType.of(context);
    final l10n = AppLocalizations.of(context);
    final definition = ref.watch(gameDefinitionProvider(config.gameId));
    final run = ref.watch(runNotifierProvider(config));
    final formatter = ref.watch(scoreFormatterProvider);
    final outcome = run.outcome;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RayHeader(
          // LEAF, not the game's accent: the results header celebrates the
          // run, and `app.html`'s `.res-hdr` is the one header whose fill is
          // the success colour rather than the game's.
          fill: colours.success,
          rays: colours.headerRayResults,
          child: Column(
            // The default centre, deliberately, and named here because every
            // other header in the app is start-aligned: `app.html`'s
            // `.res-hdr` centres the kicker and the shout. The results screen
            // is a moment rather than a place, and a centred banner reads as
            // one — start-aligned it looked like another list screen.
            children: <Widget>[
              // The game and difficulty, above the shout. app.html:
              // `.res-hdr .kicker` — the run this screen is about, in one
              // line, before the celebration.
              Text(
                l10n.gameAndDifficulty(
                  ref.watch(gameStringsProvider)(definition).title,
                  difficultyLabel(l10n, config.difficulty),
                ),
                textAlign: TextAlign.center,
                style: type.sectionLabel.copyWith(color: colours.textPrimary),
              ),
              const SizedBox(height: 6),
              Semantics(
                header: true,
                child: Text(
                  l10n.resultsTitle,
                  textAlign: TextAlign.center,
                  style: type.displayL.copyWith(color: colours.textPrimary),
                ),
              ),
              if (run.isPersonalBest) ...<Widget>[
                const SizedBox(height: 10),
                // One celebration, latched, blocking nothing.
                PopCelebration(
                  moment: Moment.personalBest,
                  child: PopBadge(
                    label: l10n.newPersonalBest,
                    variant: PopBadgeVariant.best,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
            children: <Widget>[
              ScoreSlab(
                label: l10n.finalScore,
                value: formatter.format(
                  definition.scoreFormat,
                  run.snapshot.score,
                ),
              ),
              const SizedBox(height: 16),
              if (outcome is RunCompleted)
                // TONED BY POSITION, not by what each stat means. app.html
                // gives the trio turquoise, paper and coral in reading order,
                // and a cell that picked its colour from its label would
                // re-order itself the day a game reports different stats.
                EqualRow(
                  // 10, not the duo's 12: three cells in the same pane need the
                  // points back. app.html: `.trio{gap:10px}`.
                  gap: 10,
                  children: <Widget>[
                    for (final (index, stat) in outcome.stats.indexed)
                      _StatCell(stat: stat, tone: _toneAt(index)),
                  ],
                ),
              const SizedBox(height: 24),
              PopButton(
                label: l10n.playAgain,
                size: PopButtonSize.large,
                // LEAF, not the default sunshine: `app.html` gives the results
                // screen's primary the success colour, because it is the
                // affirmative end of a run rather than the app's accent.
                variant: PopButtonVariant.success,
                leading: SunburstGlyph.go,
                expand: true,
                // A NEW SEED, therefore a new notifier, therefore a fresh run
                // rather than a resumed one.
                onPressed: () => context.go(Routes.gameDetail(config.gameId)),
              ),
              const SizedBox(height: 10),
              PopButton(
                label: l10n.homeButton,
                variant: PopButtonVariant.secondary,
                expand: true,
                onPressed: () => context.go(Routes.home),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Which tone the cell at [index] takes.
///
/// app.html tones `.tri` by `:nth-child`, so the trio always reads turquoise,
/// paper, coral regardless of which three stats a game reports.
ResultStatTone _toneAt(int index) => switch (index) {
  0 => ResultStatTone.cool,
  2 => ResultStatTone.warm,
  _ => ResultStatTone.paper,
};

/// One cell of the results trio.
class _StatCell extends ConsumerWidget {
  const _StatCell({required this.stat, required this.tone});

  final ResultStat stat;

  final ResultStatTone tone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final numbers = ref.watch(localeNumbersProvider);

    return ResultStatCell(
      tone: tone,
      label: switch (stat.labelKey) {
        'accuracyLabel' => l10n.accuracyLabel,
        'longestStreakLabel' => l10n.longestStreakLabel,
        'avgReactionLabel' => l10n.avgReactionLabel,
        _ => throw StateError(
          'no results label is registered for "${stat.labelKey}"',
        ),
      },
      value: switch (stat.format) {
        StatFormat.percent => numbers.percent(stat.canonicalValue / 1000),
        // MILLISECONDS UNDER A SECOND, seconds above it. A reaction time is
        // the sub-second case and `0.6s` throws away the digit that matters;
        // a Schulte run time is the other, and `18600ms` is unreadable. The
        // unit is an ARB string rendered as its own run, never glued to the
        // number — a value hand-joined to its unit is what breaks in RTL.
        StatFormat.duration =>
          stat.canonicalValue < Duration.millisecondsPerSecond
              ? '${numbers.count(stat.canonicalValue)}'
                    '${l10n.unitMilliseconds}'
              : '${numbers.seconds(stat.canonicalValue)}${l10n.unitSeconds}',
        StatFormat.points || StatFormat.count => numbers.count(
          stat.canonicalValue,
        ),
      },
    );
  }
}
