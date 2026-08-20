import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/features/home/application/home_notifier.dart';
import 'package:mindforge/features/shell/widgets/daily_mix_card.dart';
import 'package:mindforge/features/shell/widgets/daily_mix_summary.dart';
import 'package:mindforge/features/shell/widgets/ray_header.dart';
import 'package:mindforge/features/shell/widgets/wordmark.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/game_strings.dart';
import 'package:mindforge/l10n/l10n_providers.dart';
import 'package:mindforge/l10n/score_formatter_provider.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/game_card.dart';
import 'package:mindforge/ui/components/pop_chip.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// The game hub.
///
/// **Every game-specific fact on this screen is data read off the registry** —
/// the card, its accent, its BEST pill, whether it is locked. There is no
/// switch on a game id here and adding a fourth definition adds a fourth card
/// with no edit to this file, which is the claim the whole engine exists to
/// support.
class HomeScreen extends ConsumerWidget {
  /// Creates the hub.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colours = SunburstColors.of(context);
    final type = SunburstType.of(context);
    final l10n = AppLocalizations.of(context);
    final hub = ref.watch(homeHubProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RayHeader(
          fill: colours.accent,
          rays: colours.headerRay,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // THE LOCKUP KEEPS ITS WIDTH AND THE CHIP TAKES WHAT IS LEFT.
              // A Spacer between two natural-width children overflows at a
              // large text scale, and of the two things that could give way
              // the brand is the wrong one: a wrapped "No streak yet" is still
              // readable, a truncated "MindFo…" is a defect.
              const Row(
                children: <Widget>[
                  Wordmark(),
                  SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: _StreakChip(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.homeGreeting(hub.daypart.selector),
                style: type.greeting.copyWith(color: colours.textPrimary),
              ),
              const SizedBox(height: 4),
              // THE ONE h1 ON THIS SCREEN. A screen reader's heading list is
              // only useful if exactly one thing claims to be the heading.
              Semantics(
                header: true,
                child: Text(
                  l10n.homeReadyPrompt,
                  style: type.displayXl.copyWith(color: colours.textPrimary),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
            children: <Widget>[
              const _DailyMix(),
              const SizedBox(height: 18),
              // app.html: `.seclab` is a baseline-aligned row, the heading at
              // the start edge and the count at the end. Not a title and a
              // caption stacked: the count belongs BESIDE the thing it counts.
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  // The HEADING gives way, not the count. "Deine Spiele" and
                  // "2 freigeschaltet" together are wider than 350 in German,
                  // and a truncated count would state the wrong number.
                  Expanded(
                    child: Text(
                      l10n.yourGamesTitle,
                      style: type.sectionTitle.copyWith(
                        color: colours.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.gamesUnlocked(
                      hub.unlockedCount,
                      ref.watch(localeNumbersProvider).count(hub.unlockedCount),
                    ),
                    style: type.sectionCount.copyWith(
                      color: colours.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final game in hub.games) ...<Widget>[
                _RegistryCard(definition: game),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The daily streak, as a chip.
///
/// **An ICU plural, including at zero.** "No streak yet" is the `=0` branch of
/// the same message, not a second string and not a chip reading "0 day streak"
/// — which is what string concatenation produces and what a plural exists to
/// prevent.
class _StreakChip extends ConsumerWidget {
  const _StreakChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(streakProvider).value?.currentDays ?? 0;

    return PopChip(
      glyph: SunburstGlyph.flame,
      label: AppLocalizations.of(context).streakDays(
        days,
        ref.watch(localeNumbersProvider).count(days),
      ),
    );
  }
}

/// The Daily Mix card in its grape skin.
class _DailyMix extends ConsumerWidget {
  const _DailyMix();

  @override
  Widget build(BuildContext context, WidgetRef ref) => DailyMixCard(
    title: AppLocalizations.of(context).dailyMixTitle,
    summary: dailyMixSummary(context, ref),
    onTap: () =>
        context.go(Routes.gameDetail(ref.read(homeHubProvider).dailyPick)),
  );
}

/// One card, built entirely from a [GameDefinition].
class _RegistryCard extends ConsumerWidget {
  const _RegistryCard({required this.definition});

  final GameDefinition definition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colours = SunburstColors.of(context);
    final l10n = AppLocalizations.of(context);
    final strings = ref.watch(gameStringsProvider)(definition);

    return GameCard(
      title: strings.title,
      subtitle: strings.tagline,
      accent: colours.accentFor(definition.accent, GameColourRole.base),
      semanticLabel: strings.title,
      locked: definition.isLocked,
      // A SEPARATE STRING from the subtitle. A locked card that reused its
      // tagline as the badge printed the same sentence twice, which E05 fixed
      // and this must not reintroduce.
      lockedLabel: definition.isLocked ? l10n.comingSoon : null,
      bestLabel: definition.isLocked ? null : l10n.bestLabel,
      bestValue: definition.isLocked ? null : _best(ref, definition),
      artwork: definition.buildArtwork(context),
      onTap: definition.isLocked
          ? null
          : () => context.go(Routes.gameDetail(definition.id)),
    );
  }

  /// The formatted personal best, or `null` when there is none.
  ///
  /// **`null`, not a zero.** A game nobody has played has no best, and printing
  /// `0` in any locale states a score that was never achieved.
  String? _best(WidgetRef ref, GameDefinition definition) {
    final bests = ref.watch(allBestsProvider).value;
    final entry = bests?[definition.id.value];

    if (entry == null) return null;

    return switch (entry) {
      Ok(:final value) when value != null =>
        ref
            .watch(scoreFormatterProvider)
            .format(definition.scoreFormat, value.value),
      // A read that failed is not a zero either: the pill is simply absent
      // until the store answers.
      Ok() || Err() => null,
    };
  }
}
