import 'package:flutter/material.dart';
import 'package:mindforge/features/shell/widgets/halftone_dots.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

/// A game's identity, on its detail screen.
///
/// **It names no game.** Kicker, title, tagline and artwork all arrive as
/// arguments read off a `GameDefinition`, so a game the shell has never heard
/// of renders here with no edit — which is the claim the whole engine rests on.
///
/// It is deliberately **not a control**. The hero is the screen's subject; the
/// Play button at the bottom is how a run starts, and a tappable hero would put
/// a second, undiscoverable way to start one right beside it.
///
/// Every line on it is `textPrimary`. On a saturated fill `textSecondary` drops
/// below 4.5:1, and the kicker is the line most likely to be written as a muted
/// caption out of habit.
class GameHeroPanel extends StatelessWidget {
  /// Creates the panel for a game in [accent].
  const GameHeroPanel({
    required this.accent,
    required this.kicker,
    required this.title,
    required this.tagline,
    this.artwork,
    super.key,
  });

  /// Whose game this is.
  final GameAccent accent;

  /// The tags line above the title, already localized and already cased.
  final String kicker;

  /// The game's name.
  final String title;

  /// One line saying what the player does.
  final String tagline;

  /// The game's own preview, or `null` when it supplies none.
  final Widget? artwork;

  /// The dot lattice pitch inside the hero.
  ///
  /// `app.html`: `.hero .dots{background-size:14px 14px}` — one point tighter
  /// than a header's 15.
  static const double dotPitch = 14;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);
    final artwork = this.artwork;

    return PopSurface(
      fill: colours.accentFor(accent, GameColourRole.base),
      radius: BorderRadiusDirectional.all(shape.radiusXl),
      elevation: PopElevation.e3,
      minTarget: 0,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: HalftoneLayer(
              scene: const HalftoneScene(
                ink: null,
                ray: null,
                pitch: dotPitch,
              ).copyInk(colours.heroDots),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.all(20),
            // AlignmentDirectional.topStart, not a stretched Column. A
            // stretched one would make every line as wide as the panel, and a
            // line whose box already spans the panel cannot be tested for
            // which edge it starts at — the geometry would mirror and no
            // assertion could see it.
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    kicker,
                    style: type.sectionLabel.copyWith(
                      color: colours.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // THE SCREEN'S h1, and the panel is the right place to say
                  // so: the game's name is what the detail screen is about,
                  // and a heading list with one entry is the only kind worth
                  // having.
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: type.heroTitle.copyWith(
                        color: colours.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tagline,
                    style: type.body.copyWith(color: colours.textPrimary),
                  ),
                  if (artwork != null) ...<Widget>[
                    const SizedBox(height: 14),
                    // Decoration, by the same rule as the card's: the panel
                    // above it has already named the game three ways.
                    ExcludeSemantics(child: artwork),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
