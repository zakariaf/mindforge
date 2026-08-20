import 'package:flutter/material.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/components/tabular_text.dart';

/// One game's personal best on the Stats screen.
///
/// **It formats nothing.** `ScoreFormat` did that upstream, once, for every
/// screen: `points` 1480 is `1,480` in `en`, `1.480` in `de` and `۱٬۴۸۰` in
/// `fa` and `ckb`, and none of those decisions is made here.
///
/// The label is `textPrimary` on every accent — `textSecondary` is 2.8:1 on
/// coral, and a caption is exactly the line a transcription mutes by habit.
class BestCard extends StatelessWidget {
  /// Creates the card for a game in [accent].
  const BestCard({
    required this.label,
    required this.gameName,
    required this.value,
    required this.accent,
    super.key,
  });

  /// What kind of best this is: "BEST SCORE", "BEST TIME".
  final String label;

  /// The game's name.
  final String gameName;

  /// The already-localized value.
  final String value;

  /// Whose game this is.
  final GameAccent accent;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    return MergeSemantics(
      child: PopSurface(
        fill: colours.accentFor(accent, GameColourRole.base),
        radius: BorderRadiusDirectional.all(shape.radiusLg),
        minTarget: 0,
        padding: const EdgeInsetsDirectional.fromSTEB(15, 13, 15, 13),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    style: type.label.copyWith(color: colours.textPrimary),
                  ),
                  Text(
                    gameName,
                    style: type.bestGameName.copyWith(
                      color: colours.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // The chip step, not e1 and not e2: `app.html` gives it
            // `2px 2px 0 var(--ink)`, the same half-step the selected segment
            // and the badges take.
            PopSurface(
              fill: colours.surface,
              radius: BorderRadiusDirectional.all(shape.radiusMd),
              elevation: PopElevation.chip,
              nested: true,
              minTarget: 0,
              padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 4),
              child: TabularText(
                value,
                style: type.bestValue.copyWith(color: colours.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
