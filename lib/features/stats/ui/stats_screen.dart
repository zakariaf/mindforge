import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/features/shell/widgets/best_card.dart';
import 'package:mindforge/features/shell/widgets/equal_row.dart';
import 'package:mindforge/features/shell/widgets/ray_header.dart';
import 'package:mindforge/features/shell/widgets/section_heading.dart';
import 'package:mindforge/features/shell/widgets/shell_pane.dart';
import 'package:mindforge/features/shell/widgets/stat_box.dart';
import 'package:mindforge/features/stats/application/stats_notifier.dart';
import 'package:mindforge/features/stats/widgets/run_bar_chart.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/game_strings.dart';
import 'package:mindforge/l10n/l10n_providers.dart';
import 'package:mindforge/l10n/score_formatter_provider.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_card.dart';

/// All-time numbers, per game.
///
/// **The list is the registry, not a hardcoded set.** A game with no runs shows
/// no best rather than a zero, for the same reason Home shows no BEST pill: a
/// zero states a score nobody achieved.
class StatsScreen extends ConsumerWidget {
  /// Creates the screen.
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colours = SunburstColors.of(context);
    final type = SunburstType.of(context);
    final l10n = AppLocalizations.of(context);
    final numbers = ref.watch(localeNumbersProvider);
    final formatter = ref.watch(scoreFormatterProvider);
    final strings = ref.watch(gameStringsProvider);
    final stats = ref.watch(statsHubProvider);

    return ShellPane(
      header: RayHeader(
        // NO RAYS. `app.html`'s `.stats-hdr` carries the dot lattice and no
        // ray layer at all, and this is the header the "all three glow the
        // same" defect shows up on first.
        fill: colours.accentCool,
        rays: null,
        padding: RayHeader.tabInset,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.statsAllTime,
              style: type.greeting.copyWith(color: colours.textPrimary),
            ),
            Semantics(
              header: true,
              child: Text(
                l10n.statsTitle,
                style: type.displayL.copyWith(color: colours.textPrimary),
              ),
            ),
          ],
        ),
      ),
      children: <Widget>[
        for (final entry in stats.bests) ...<Widget>[
          BestCard(
            // WHICH KIND OF BEST, from the game's own score format: a
            // points game has a best SCORE and a timed one a best TIME,
            // and one shared caption would be wrong for half the
            // registry.
            label: switch (entry.definition.scoreFormat) {
              ScoreFormat.points => l10n.bestScore,
              ScoreFormat.duration => l10n.bestTime,
            },
            gameName: strings(entry.definition).title,
            value: switch (entry.metric) {
              // An em dash, not a zero: punctuation, not a number.
              null => '—',
              final metric => formatter.format(
                entry.definition.scoreFormat,
                metric.value,
              ),
            },
            accent: entry.definition.accent,
          ),
          const SizedBox(height: 12),
        ],
        EqualRow(
          children: <Widget>[
            StatBox(
              label: l10n.gamesPlayed,
              value: numbers.count(stats.gamesPlayed),
            ),
            StatBox(
              label: l10n.timeTrained,
              value: l10n.durationHoursMinutes(
                numbers.count(
                  stats.timeTrainedMs ~/ Duration.millisecondsPerHour,
                ),
                numbers.count(
                  stats.timeTrainedMs %
                      Duration.millisecondsPerHour ~/
                      Duration.millisecondsPerMinute,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _Chart(),
      ],
    );
  }
}

/// The recent-runs card, or nothing at all.
///
/// **Absent rather than empty when there is no history.** A chart card holding
/// seven zero-height bars and an axis is a drawing of nothing; a player who has
/// never finished a run is better served by the screen simply not claiming to
/// have a history for them.
class _Chart extends ConsumerWidget {
  const _Chart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colours = SunburstColors.of(context);
    final type = SunburstType.of(context);
    final l10n = AppLocalizations.of(context);
    final numbers = ref.watch(localeNumbersProvider);
    final formatter = ref.watch(scoreFormatterProvider);
    final stats = ref.watch(statsHubProvider);
    final game = stats.chartGame;

    if (game == null || stats.isEmpty) return const SizedBox.shrink();

    final values = stats.series
        .map((record) => record.metricValue)
        .toList(growable: false);
    // TRUE ZERO, and scaled to the series rather than to a constant. app.html
    // divides by a fixed 10.5, which clips silently above about 1560: two runs
    // one better than the other would draw the same bar.
    final peak = values.reduce(math.max);
    final floor = values.reduce(math.min);
    final bestValue = switch (game.scoreFormat) {
      ScoreFormat.points => peak,
      // Lower is better for a timed game: the BEST run is the shortest one.
      ScoreFormat.duration => floor,
    };

    // TALLER IS BETTER IN BOTH DIRECTIONS. Plotting a duration raw makes the
    // SLOWEST run the tallest bar and the sunshine "best" one the shortest —
    // a chart whose shape means the opposite thing for the game beside it is
    // worse than no chart. A timed run is plotted as the best time over this
    // one, so the best run is the full-height bar and a slower run is a
    // shorter one. Both still stand on a true-zero axis.
    double ratioOf(int value) => switch (game.scoreFormat) {
      ScoreFormat.points => peak == 0 ? 0 : value / peak,
      ScoreFormat.duration => value == 0 ? 0 : floor / value,
    };

    return PopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeading(
            title: l10n.lastNRuns(
              stats.series.length,
              numbers.count(stats.series.length),
            ),
            trailing: l10n.chartSubtitle(
              ref.watch(gameStringsProvider)(game).title,
              formatter.format(game.scoreFormat, bestValue),
            ),
          ),
          const SizedBox(height: 14),
          RunBarChart(
            semanticLabel: values
                .map(
                  (value) => formatter.format(game.scoreFormat, value),
                )
                .join(', '),
            bars: <ChartBar>[
              for (final value in values)
                ChartBar(
                  ratio: ratioOf(value),
                  isBest: value == bestValue,
                  label: formatter.format(game.scoreFormat, value),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // THE AXIS IS THE BAND'S BOTTOM EDGE. A 3px ink line drawn under the
          // bars rather than a baseline the bars float above: true zero, so no
          // bar can overstate its run.
          Container(
            height: SunburstShape.of(context).borderWidth,
            color: colours.border,
          ),
          const SizedBox(height: 7),
          Row(
            children: <Widget>[
              Text(
                l10n.chartOldest,
                style: type.sectionCount.copyWith(
                  color: colours.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                l10n.chartLatest,
                style: type.sectionCount.copyWith(
                  color: colours.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
