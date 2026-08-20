import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

/// The cell a board game prints a number on.
///
/// Sized as a **grid unit**, from the constraints it is given rather than from
/// a device check — and identically in all four locales. A Schulte cell is 64
/// logical points everywhere; what changes between locales is the digits
/// printed on it, not the cell.
const double kGridTileSize = 64;

/// The tile size on the narrowest phone.
const double kGridTileSizeCompact = 60;

/// Where a board tile is in its own little story.
enum PopGridTileState {
  /// Untouched, and not the one being looked for.
  idle,

  /// The one being looked for.
  next,

  /// Already found. Permanent.
  found,

  /// Tapped when it was not the one.
  wrong,

  /// Not in play.
  disabled;

  /// The elevation this state sits at.
  PopElevation get elevation => switch (this) {
    PopGridTileState.idle => PopElevation.e1,
    PopGridTileState.next => PopElevation.e2,
    // Found is SUNK, permanently, and draws no shadow at all — the tile has
    // been pressed into the board and stays there.
    PopGridTileState.found => PopElevation.flat,
    PopGridTileState.wrong => PopElevation.flat,
    PopGridTileState.disabled => PopElevation.e1,
  };
}

/// One cell of a board.
///
/// Every state is distinguishable **without colour**: the fill changes, and so
/// does the depth, the ring and whether a shadow is drawn. Hue is never the
/// only channel, which is what makes the greyscale golden a real check rather
/// than a formality.
class PopGridTile extends StatelessWidget {
  /// Creates a tile labelled [label].
  const PopGridTile({
    required this.label,
    required this.state,
    required this.semanticLabel,
    this.onTap,
    super.key,
  });

  /// The already-localized number or letter printed on the tile.
  final String label;

  /// Where the tile is in its story.
  final PopGridTileState state;

  /// The already-localized label a screen reader announces.
  final String semanticLabel;

  /// What a completed tap does.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    final scaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Decided from CONSTRAINTS, never from a device check: a tile in a
        // narrow grid is narrow because its grid is, not because of what phone
        // it is on.
        final base = constraints.maxWidth.isFinite && constraints.maxWidth < 64
            ? kGridTileSizeCompact
            : kGridTileSize;

        // THE CELL GROWS WITH THE TEXT. It never shrinks its label to fit:
        // measured, two Eastern Arabic digits at 2.0x do not fit a 64pt cell,
        // and the answer accessibility-as-code rules 4 and 5 give is that the
        // slot grows. Scaling the glyph down to the box instead would make the
        // number on a Schulte board unreadable for exactly the player who
        // asked for larger text.
        final needed = _labelExtent(context, scaler) + SunburstShape.space4;
        final side = base > needed ? base : needed;

        return SizedBox.square(
          dimension: side,
          child: PopSurface(
            fill: _fill(colours),
            radius: BorderRadiusDirectional.all(shape.radiusSm),
            elevation: state.elevation,
            enabled: state != PopGridTileState.disabled,
            onTap: onTap,
            semanticLabel: semanticLabel,
            minTarget: 0,
            child: Center(
              child: Text(
                label,
                style: type.numericHud.copyWith(color: _ink(colours)),
              ),
            ),
          ),
        );
      },
    );
  }

  /// How wide the label wants to be, at the scale actually in use.
  double _labelExtent(BuildContext context, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: SunburstType.of(context).numericHud),
      textDirection: Directionality.of(context),
      textScaler: scaler,
    )..layout();
    final extent = painter.width > painter.height
        ? painter.width
        : painter.height;
    painter.dispose();

    return extent;
  }

  Color _fill(SunburstColors colours) => switch (state) {
    PopGridTileState.idle => colours.surfaceRaised,
    PopGridTileState.next => colours.accent,
    PopGridTileState.found => colours.gameSchulteDeep,
    PopGridTileState.wrong => colours.danger,
    PopGridTileState.disabled => colours.surfaceSunk,
  };

  Color _ink(SunburstColors colours) => switch (state) {
    PopGridTileState.idle || PopGridTileState.next => colours.textPrimary,
    // A deep fill takes the inverted ink, which is also the second channel
    // separating found and wrong from idle in greyscale.
    PopGridTileState.found || PopGridTileState.wrong => colours.surfaceRaised,
    PopGridTileState.disabled => colours.textDisabled,
  };
}
