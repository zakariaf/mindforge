import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/run_outcome.dart';
import 'package:mindforge/features/play/application/run_notifier.dart';
import 'package:mindforge/features/shell/widgets/ray_header.dart';
import 'package:mindforge/games/game_registry.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/l10n_providers.dart';
import 'package:mindforge/l10n/score_formatter_provider.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/motion/pop_celebration.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_badge.dart';
import 'package:mindforge/ui/components/pop_button.dart';
import 'package:mindforge/ui/components/pop_card.dart';

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
          fill: colours.accentFor(definition.accent, GameColourRole.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  l10n.resultsTitle,
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
              PopCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.finalScore,
                      style: type.sectionLabel.copyWith(
                        color: colours.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatter.format(
                        definition.scoreFormat,
                        run.snapshot.score,
                      ),
                      style: type.scoreHero.copyWith(
                        color: colours.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (outcome is RunCompleted)
                Row(
                  children: <Widget>[
                    for (final stat in outcome.stats)
                      Expanded(child: _StatCell(stat: stat)),
                  ],
                ),
              const SizedBox(height: 24),
              PopButton(
                label: l10n.playAgain,
                size: PopButtonSize.large,
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

/// One cell of the results trio.
class _StatCell extends ConsumerWidget {
  const _StatCell({required this.stat});

  final ResultStat stat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colours = SunburstColors.of(context);
    final type = SunburstType.of(context);
    final l10n = ref.watch(appLocalizationsProvider);
    final numbers = ref.watch(localeNumbersProvider);

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 10),
      child: PopCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              switch (stat.labelKey) {
                'accuracyLabel' => l10n.accuracyLabel,
                'longestStreakLabel' => l10n.longestStreakLabel,
                'avgReactionLabel' => l10n.avgReactionLabel,
                _ => throw StateError(
                  'no results label is registered for "${stat.labelKey}"',
                ),
              },
              style: type.sectionLabel.copyWith(color: colours.textSecondary),
            ),
            const SizedBox(height: 3),
            Text(
              switch (stat.format) {
                StatFormat.percent => numbers.percent(
                  stat.canonicalValue / 1000,
                ),
                StatFormat.duration => numbers.seconds(stat.canonicalValue),
                StatFormat.points || StatFormat.count => numbers.count(
                  stat.canonicalValue,
                ),
              },
              style: type.statValue.copyWith(color: colours.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
