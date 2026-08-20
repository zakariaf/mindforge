import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/features/home/application/home_notifier.dart';
import 'package:mindforge/features/shell/widgets/ray_header.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/game_strings.dart';
import 'package:mindforge/l10n/score_formatter_provider.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_card.dart';

/// All-time numbers, per game.
///
/// **The list is the registry, not a hardcoded set.** A game with no runs shows
/// a dash rather than a zero, for the same reason Home shows no BEST pill: a
/// zero states a score nobody achieved.
class StatsScreen extends ConsumerWidget {
  /// Creates the screen.
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colours = SunburstColors.of(context);
    final type = SunburstType.of(context);
    final l10n = AppLocalizations.of(context);
    final hub = ref.watch(homeHubProvider);
    final strings = ref.watch(gameStringsProvider);
    final formatter = ref.watch(scoreFormatterProvider);
    final bests = ref.watch(allBestsProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RayHeader(
          fill: colours.accent,
          child: Semantics(
            header: true,
            child: Text(
              l10n.statsTitle,
              style: type.displayL.copyWith(color: colours.textPrimary),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
            children: <Widget>[
              Text(
                l10n.statsAllTime,
                style: type.sectionLabel.copyWith(
                  color: colours.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              for (final game in hub.games.where((g) => !g.isLocked))
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 10),
                  child: PopCard(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            strings(game).title,
                            style: type.title.copyWith(
                              color: colours.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          switch (bests?[game.id.value]) {
                            Ok(:final value) when value != null =>
                              formatter.format(game.scoreFormat, value.value),
                            // An em dash, not a zero: a game nobody has played
                            // has no best, and a zero in any locale states a
                            // score that was never achieved.
                            _ => '—',
                          },
                          style: type.statValue.copyWith(
                            color: colours.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
