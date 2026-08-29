import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

/// How a Digit Bridge board divides the field it is given.
///
/// A value type rather than numbers inlined into `build()`, so the geometry can
/// be asserted at five device widths without pumping the whole board — and so
/// the 48pt tap floor is defended in one place rather than at each call site.
@immutable
final class BridgeMetrics {
  /// Creates metrics.
  const BridgeMetrics({
    required this.chipWidth,
    required this.chipHeight,
    required this.gap,
  });

  /// The metrics for a field of [size].
  ///
  /// **The chip's height comes from its WIDTH, not from the field.** An earlier
  /// version divided the leftover height between two rows, which on a 460pt
  /// field drew chips half as wide as they were tall — measured on the
  /// canonical simulator against `screens/09-digit-bridge.png`, where they are
  /// wider than tall. A numeral is a horizontal run, so a portrait chip wastes
  /// its own space above and below the glyphs and makes the six of them read as
  /// a column of cards rather than as a set of choices.
  ///
  /// The gap steps from [roomyGap] to [tightGap] exactly when the roomy gap
  /// would push a chip under [kPopMinTarget] — the same derivation Schulte
  /// Grid's cell sizing makes, and for the same reason: a 48pt tap target is a
  /// floor, and whitespace is what gives way to defend it.
  factory BridgeMetrics.forField(Size size) {
    final gap = _gapFor(size.width);
    final chipWidth = (size.width - gap * (columns - 1)) / columns;
    final chipHeight = (chipWidth / chipAspect).clamp(
      kPopMinTarget,
      double.infinity,
    );

    return BridgeMetrics(
      chipWidth: chipWidth,
      chipHeight: chipHeight,
      gap: gap,
    );
  }

  /// The chip grid is three across and two down, at every difficulty.
  ///
  /// Fixed so the geometry does not change between difficulties: the digit
  /// count carries the difficulty, and a grid that reshaped as well would make
  /// the tap-target floor a different calculation in each.
  static const int columns = 3;

  /// How many rows of chips.
  static const int rows = 2;

  /// The gap the design uses between chips when there is room for it.
  ///
  /// `app.html`: `.grid5{gap:12px}` is the board-grid rhythm, and this is the
  /// same step.
  static const double roomyGap = SunburstShape.space3;

  /// The gap a cramped field falls back to.
  ///
  /// The step below, taken whole rather than interpolated: a gap that slid
  /// continuously with the width would put a different number on every device
  /// and make a screenshot comparison meaningless.
  ///
  /// **It does not bind on any shipped device, and that is measured rather than
  /// hoped.** The narrowest is 320pt, the shell's gutter leaves the board 280pt
  /// (`play_scaffold.dart` gives it `fromSTEB(20, 12, 20, 20)`), and three
  /// columns at the roomy gap is `(280 - 24) / 3 = 85.3pt` — comfortably over
  /// the 48pt floor. The step exists for a grid edit that has not been made:
  /// it binds below 168pt of board width. Stated here rather than deleted,
  /// because a floor nobody can reach is still the reason the floor holds.
  static const double tightGap = SunburstShape.space2;

  /// How much wider than tall a chip draws.
  ///
  /// `app.html`: `.chipnum{aspect-ratio:1.6/1}`. A numeral is a horizontal run,
  /// so the chip is too — and at three across on a 350pt board that is a 108x68
  /// chip, comfortably over the 48pt floor on both axes.
  static const double chipAspect = 1.6;

  /// The gap between the target numeral and the chip grid.
  ///
  /// `app.html`: `.playfill{gap:16px}`, the same step Stroop Rush uses between
  /// its stimulus card and its answer grid.
  static const double targetToGridGap = 16;

  /// How wide one chip draws.
  final double chipWidth;

  /// How tall one chip draws.
  final double chipHeight;

  /// The gap between chips, on both axes.
  final double gap;

  /// How tall the whole chip grid draws.
  double get gridHeight => chipHeight * rows + gap * (rows - 1);

  /// The gap a field of [width] can afford.
  static double _gapFor(double width) {
    final roomy = (width - roomyGap * (columns - 1)) / columns;

    return roomy >= kPopMinTarget ? roomyGap : tightGap;
  }
}
