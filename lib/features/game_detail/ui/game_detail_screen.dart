import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/run_scope.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/features/home/application/home_notifier.dart';
import 'package:mindforge/features/play/application/seeded_random_provider.dart';
import 'package:mindforge/features/shell/widgets/daily_mix_card.dart';
import 'package:mindforge/features/shell/widgets/daily_mix_summary.dart';
import 'package:mindforge/features/shell/widgets/game_hero_panel.dart';
import 'package:mindforge/features/shell/widgets/stat_box.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/game_registry.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/game_strings.dart';
import 'package:mindforge/l10n/l10n_providers.dart';
import 'package:mindforge/l10n/score_formatter_provider.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/difficulty_segmented.dart';
import 'package:mindforge/ui/components/pop_button.dart';
import 'package:mindforge/ui/components/pop_icon_button.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// One game's detail screen: hero, stat duo, difficulty and Play.
///
/// **It names no game.** Everything on it is read off the definition the route
/// carries, so a game the shell has never heard of renders here with no edit.
///
/// **There is no ray header.** `app.html` gives this screen a plain top bar
/// over the pane: the colour arrives with the hero panel, which is the game's,
/// rather than with a header strip, which is the shell's. A header here would
/// paint the accent edge to edge and leave the hero nothing to say.
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
    // CLASSIC IS THE DEFAULT WHERE IT IS OFFERED, not the first entry.
    // `app.html` shows Classic selected, and it is the right default for a
    // reason a list index cannot express: Chill is for someone who wants no
    // pressure and Blitz is for someone chasing a number, while Classic is
    // what the game IS. A game that does not offer it falls back to its first.
    final chosen =
        _chosen ??
        (offered.contains(Difficulty.classic)
            ? Difficulty.classic
            : offered.first);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            // app.html: `.topbar{padding:2px 20px 16px}`.
            padding: const EdgeInsetsDirectional.fromSTEB(20, 2, 20, 16),
            child: Row(
              children: <Widget>[
                PopIconButton(
                  // The chevron mirrors, because "back" is a
                  // reading-direction word. The glyph table decides that, not
                  // this screen.
                  glyph: SunburstGlyph.back,
                  semanticLabel: l10n.homeButton,
                  onPressed: () => context.go(Routes.home),
                ),
                const SizedBox(width: 14),
                Expanded(
                  // DRAWN, NOT ANNOUNCED. app.html puts the game's name in the
                  // bar and again in the hero below it; the hero's copy is the
                  // h1, so a screen reader that met both would hear the same
                  // three words twice before reaching anything new.
                  child: ExcludeSemantics(
                    child: Text(
                      strings.title,
                      style: type.titleBar.copyWith(color: colours.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 20),
              children: <Widget>[
                GameHeroPanel(
                  accent: definition.accent,
                  kicker: strings.kicker,
                  title: strings.title,
                  tagline: strings.tagline,
                  artwork: definition.buildArtwork(context),
                ),
                const SizedBox(height: 16),
                _StatDuo(definition: definition),
                const SizedBox(height: 18),
                Text(
                  l10n.difficultyTitle,
                  style: type.sectionLabel.copyWith(
                    color: colours.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                DifficultySegmented(
                  labels: <String>[
                    for (final difficulty in offered)
                      _labelFor(l10n, difficulty),
                  ],
                  selectedIndex: offered.indexOf(chosen),
                  onSelected: (index) =>
                      setState(() => _chosen = offered[index]),
                ),
                const SizedBox(height: 16),
                const _DailyMix(),
                const SizedBox(height: 26),
                PopButton(
                  label: l10n.playButton,
                  size: PopButtonSize.large,
                  variant: PopButtonVariant.success,
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
        ],
      ),
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

/// The two numbers under the hero: this game's best, and how often it was
/// played.
///
/// **A dash for the best and a real zero for the count.** They are different
/// facts: a game nobody has played has no best, and printing `0` in any locale
/// states a score that was never achieved — while "played 0 times" is simply
/// true.
class _StatDuo extends ConsumerWidget {
  const _StatDuo({required this.definition});

  final GameDefinition definition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final numbers = ref.watch(localeNumbersProvider);
    final scope = RunScope.of(definition.id, null);
    final stats = ref.watch(runStatsProvider(scope)).value;
    final best = ref.watch(allBestsProvider).value?[definition.id.value];

    // IntrinsicHeight, so the two boxes match even when one label wraps to a
    // second line in German and the other does not. Inside a ListView a
    // stretched Row alone has no height to stretch to.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: StatBox(
              label: l10n.yourBest,
              value: switch (best) {
                Ok(:final value) when value != null =>
                  ref
                      .watch(scoreFormatterProvider)
                      .format(definition.scoreFormat, value.value),
                // An em dash, not a zero, and not a locale-formatted one: it is
                // punctuation, not a number.
                Ok() || Err() || null => '—',
              },
              tone: StatBoxTone.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatBox(
              label: l10n.gamesPlayed,
              value: numbers.count(stats?.gamesPlayed ?? 0),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Daily Mix card in its paper skin.
///
/// The same destination as Home's: a seeded pick over the unlocked registry,
/// stable for the day. The card is not decoration — an inert chevron is the
/// dead affordance E11 forbids.
class _DailyMix extends ConsumerWidget {
  const _DailyMix();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DailyMixCard(
      variant: DailyMixVariant.paper,
      title: AppLocalizations.of(context).dailyMixTitle,
      summary: dailyMixSummary(context, ref),
      onTap: () => context.go(
        Routes.gameDetail(ref.read(homeHubProvider).dailyPick),
      ),
    );
  }
}
