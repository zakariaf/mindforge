import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/features/play/application/seeded_random_provider.dart';
import 'package:mindforge/features/shell/widgets/ray_header.dart';
import 'package:mindforge/games/game_registry.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/game_strings.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/difficulty_segmented.dart';
import 'package:mindforge/ui/components/pop_button.dart';
import 'package:mindforge/ui/components/pop_icon_button.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// One game's detail screen: hero, difficulty and Play.
///
/// **It names no game.** Everything on it is read off the definition the route
/// carries, so a game the shell has never heard of renders here with no edit.
class GameDetailScreen extends ConsumerStatefulWidget {
  /// Creates the screen for [gameId].
  const GameDetailScreen({required this.gameId, super.key});

  /// Which game.
  final GameId gameId;

  @override
  ConsumerState<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends ConsumerState<GameDetailScreen> {
  Difficulty? _chosen;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final type = SunburstType.of(context);
    final l10n = AppLocalizations.of(context);
    final definition = ref.watch(gameDefinitionProvider(widget.gameId));
    final strings = ref.watch(gameStringsProvider)(definition);

    // The game's OWN difficulties, not the enum's. Schulte Grid may ship
    // without Blitz, and a screen that offered all three would start a run the
    // definition refuses.
    final offered = definition.difficulties;
    final chosen = _chosen ?? offered.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RayHeader(
          fill: colours.accentFor(definition.accent, GameColourRole.base),
          rays: colours.bandRayFor(definition.accent),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  PopIconButton(
                    // Icons.adaptive-style: the glyph mirrors because "back"
                    // is a reading-direction word.
                    glyph: SunburstGlyph.back,
                    semanticLabel: l10n.homeButton,
                    onPressed: () => context.go(Routes.home),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                strings.kicker,
                style: type.sectionLabel.copyWith(color: colours.textSecondary),
              ),
              const SizedBox(height: 6),
              Semantics(
                header: true,
                child: Text(
                  strings.title,
                  style: type.heroTitle.copyWith(color: colours.textPrimary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.tagline,
                style: type.body.copyWith(color: colours.textPrimary),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l10n.difficultyTitle,
                  style: type.title.copyWith(color: colours.textPrimary),
                ),
                const SizedBox(height: 12),
                DifficultySegmented(
                  labels: <String>[
                    for (final difficulty in offered)
                      _labelFor(l10n, difficulty),
                  ],
                  selectedIndex: offered.indexOf(chosen),
                  onSelected: (index) =>
                      setState(() => _chosen = offered[index]),
                ),
                const Spacer(),
                PopButton(
                  label: l10n.playButton,
                  size: PopButtonSize.large,
                  leading: SunburstGlyph.go,
                  expand: true,
                  onPressed: () => context.go(
                    Routes.countdown(
                      RunConfig(
                        gameId: definition.id,
                        difficulty: chosen,
                        // A FRESH SEED per run. "Play again" is a new seed,
                        // therefore a new notifier, therefore a fresh round.
                        seed: ref.read(seededRandomProvider)(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The ARB label for [difficulty].
  ///
  /// A switch over the ENUM, not over a game id: `Difficulty` carries the key
  /// and gen-l10n cannot look one up at runtime, so this is the same sanctioned
  /// shape as `game_strings.dart`.
  String _labelFor(AppLocalizations l10n, Difficulty difficulty) =>
      switch (difficulty) {
        Difficulty.chill => l10n.difficultyChill,
        Difficulty.classic => l10n.difficultyClassic,
        Difficulty.blitz => l10n.difficultyBlitz,
      };
}
