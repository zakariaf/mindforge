import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/features/home/application/home_notifier.dart';
import 'package:mindforge/features/shell/widgets/ray_header.dart';
import 'package:mindforge/features/shell/widgets/wordmark.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/game_strings.dart';
import 'package:mindforge/l10n/score_formatter_provider.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/game_card.dart';

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
              const Row(children: <Widget>[Wordmark()]),
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
              Text(
                l10n.yourGamesTitle,
                style: type.title.copyWith(color: colours.textPrimary),
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
