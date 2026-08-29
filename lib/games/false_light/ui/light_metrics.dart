import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/pop_grid_metrics.dart';

/// How a False Light board divides the field it is given.
///
/// A value type rather than numbers inlined into `build()`, so the geometry can
/// be asserted at five device widths without pumping the board — and so the
/// 48pt tap floor is defended in one place.
@immutable
final class LightMetrics {
  /// Creates metrics.
  const LightMetrics({required this.tileSize, required this.gap});

  /// The metrics for a [columns] x [rows] grid in a field of [size].
  ///
  /// **The tile is square and sized by the tighter axis.** A grid that filled
  /// both axes independently would give blitz a 5-wide, 6-tall field of
  /// rectangles, and a rectangle reads as a different KIND of tile rather than
  /// the same tile in a different place — which on a board whose whole content
  /// is the sameness of the tiles would be a second, accidental channel.
  factory LightMetrics.forField(
    Size size, {
    required int columns,
    required int rows,
  }) {
    final gap = _gapFor(size.width, columns);
    final byWidth = popGridCell(size.width, columns, gap);
    final byHeight = size.height.isFinite
        ? popGridCell(size.height, rows, gap)
        : byWidth;

    return LightMetrics(
      tileSize: byWidth < byHeight ? byWidth : byHeight,
      gap: gap,
    );
  }

  /// The gap the design uses between tiles when there is room for it.
  ///
  /// `app.html`: `.grid5{gap:12px}` is the board-grid rhythm, and this is the
  /// same step Schulte Grid takes.
  static const double roomyGap = SunburstShape.space3;

  /// The gap a cramped field falls back to.
  ///
  /// The step below, taken whole rather than interpolated: a gap that slid
  /// continuously with the width would put a different number on every device
  /// and make a screenshot comparison meaningless.
  ///
  /// **It binds, on the device that matters, and that is what sets the column
  /// cap.** A 320pt phone leaves the board 280pt after the shell's gutter.
  /// Blitz at five columns is `(280 - 4*12) / 5 = 46.4pt` at the roomy gap —
  /// under the 48pt floor — and `(280 - 4*8) / 5 = 49.6pt` at the tight one,
  /// which clears it. Six columns clears neither: 36.7pt roomy and 40pt tight.
  /// That is why the blitz grid is 5 x 6 rather than 6 x 5, and the sixth ROW
  /// is free because a board is taller than it is wide.
  static const double tightGap = SunburstShape.space2;

  /// How wide and tall one tile draws.
  final double tileSize;

  /// The gap between tiles, on both axes.
  final double gap;

  /// The gap a [columns]-wide grid can afford in [width].
  ///
  /// `popGridGap` is the shared derivation; the column count is this board's.
  ///
  /// **From the WIDTH only**, which is safe because the tile is square and
  /// sized by the tighter axis: a board is always taller than it is wide, so
  /// the width is the binding axis on every shipped field.
  static double _gapFor(double width, int columns) =>
      popGridGap(width, columns);

  /// How wide the whole grid draws.
  double widthFor(int columns) => tileSize * columns + gap * (columns - 1);

  /// How tall the whole grid draws.
  double heightFor(int rows) => tileSize * rows + gap * (rows - 1);
}
