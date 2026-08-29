import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

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
    final gap = _gapFor(size, columns: columns, rows: rows);
    final byWidth = (size.width - gap * (columns - 1)) / columns;
    final byHeight = size.height.isFinite
        ? (size.height - gap * (rows - 1)) / rows
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
  /// **It binds, on the device that matters.** Blitz is six columns wide and a
  /// 320pt phone leaves the board 280pt after the shell's gutter, so the roomy
  /// gap gives `(280 - 60) / 6 = 36.7pt` — under the floor — and the tight one
  /// gives `(280 - 40) / 6 = 40pt`, which is still under it. That is why the
  /// blitz grid is 5 x 6 and not 6 x 5: five columns at the tight gap is
  /// `(280 - 32) / 5 = 49.6pt`, and the sixth row is free because a board is
  /// taller than it is wide.
  static const double tightGap = SunburstShape.space2;

  /// How wide and tall one tile draws.
  final double tileSize;

  /// The gap between tiles, on both axes.
  final double gap;

  /// The gap a [columns] x [rows] grid can afford in [size].
  static double _gapFor(Size size, {required int columns, required int rows}) {
    final roomy = (size.width - roomyGap * (columns - 1)) / columns;

    return roomy >= kPopMinTarget ? roomyGap : tightGap;
  }

  /// How wide the whole grid draws.
  double widthFor(int columns) => tileSize * columns + gap * (columns - 1);

  /// How tall the whole grid draws.
  double heightFor(int rows) => tileSize * rows + gap * (rows - 1);
}
