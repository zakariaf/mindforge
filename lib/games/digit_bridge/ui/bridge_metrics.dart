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
    required this.targetHeight,
  });

  /// The metrics for a field of [size].
  ///
  /// The gap steps from [roomyGap] to [tightGap] exactly when the roomy gap
  /// would push a chip under [kPopMinTarget] — the same derivation Schulte
  /// Grid's cell sizing makes, and for the same reason: a 48pt tap target is a
  /// floor, and whitespace is the thing that gives way to defend it.
  factory BridgeMetrics.forField(Size size) {
    final gap = _gapFor(size.width);
    final chipWidth = (size.width - gap * (columns - 1)) / columns;

    final forTarget = size.height.isFinite
        ? (size.height - targetToGridGap) * targetShareWhenCramped
        : 0.0;
    final forGrid = size.height.isFinite
        ? size.height - targetToGridGap - forTarget
        : 0.0;
    final chipHeight = size.height.isFinite
        ? ((forGrid - gap * (rows - 1)) / rows).clamp(
            kPopMinTarget,
            double.infinity,
          )
        : kPopMinTarget;

    return BridgeMetrics(
      chipWidth: chipWidth,
      chipHeight: chipHeight,
      gap: gap,
      targetHeight: forTarget,
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

  /// The share of a field the target numeral keeps, at most.
  ///
  /// DERIVED. `app.html` renders one size, where the stimulus and the grid both
  /// sit at their token heights and the question does not arise. It arises at
  /// x2.0 on a 320pt phone, and the answer is that the CHIPS keep the majority:
  /// the target is one glyph run the player reads once, and the chips are six
  /// they scan repeatedly — and the chips also carry the tap floor.
  static const double targetShareWhenCramped = 0.32;

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

  /// How tall the target numeral's box draws.
  final double targetHeight;

  /// The gap a field of [width] can afford.
  static double _gapFor(double width) {
    final roomy = (width - roomyGap * (columns - 1)) / columns;

    return roomy >= kPopMinTarget ? roomyGap : tightGap;
  }

  /// How tall the whole chip grid draws.
  double get gridHeight => chipHeight * rows + gap * (rows - 1);
}
