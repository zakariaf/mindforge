import 'package:flutter/widgets.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

/// A board that plays nothing.
///
/// **It exists to prove the seam, not to be a game.** E08 builds eight screens
/// and both real games arrive in E09 and E10, so without something in the
/// registry the shell has nothing to render and no screenshot to compare. This
/// draws a sunken panel with the run's difficulty on it and reports no
/// outcome — a board that never ends.
///
/// It obeys every rule a real board obeys, deliberately: no `Scaffold`, no
/// `SafeArea`, no navigation, no clock, no chrome, no raw colour. If it dodged
/// the fence it would prove nothing about the fence.
///
/// **E09 deletes this directory in its first commit.**
class PlaceholderBoard extends StatelessWidget {
  /// Creates the board for [run].
  const PlaceholderBoard({required this.run, required this.accent, super.key});

  /// Which run is being played.
  final RunConfig run;

  /// The game's identity colour.
  final GameAccent accent;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colours.surfaceSunk,
        borderRadius: BorderRadiusDirectional.all(
          shape.radiusLg,
        ).resolve(Directionality.of(context)),
        border: Border.all(color: colours.border, width: shape.borderWidth),
      ),
      child: Center(
        child: Text(
          run.difficulty.name,
          style: type.titleBar.copyWith(color: colours.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
