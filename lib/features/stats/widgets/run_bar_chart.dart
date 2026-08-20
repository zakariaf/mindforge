import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

/// One column of the chart.
@immutable
final class ChartBar {
  /// Creates a bar.
  const ChartBar({
    required this.ratio,
    required this.isBest,
    required this.label,
  });

  /// How tall the bar is, as a fraction of the band.
  ///
  /// **Value over the series maximum, clamped to `[0, 1]`.** `app.html` divides
  /// by a fixed 10.5, which clips silently above about 1560 — a run better than
  /// that would draw the same height as one exactly at it. DERIVED change, and
  /// the reason the band cannot be overstated.
  final double ratio;

  /// Whether this is the best run in the series.
  final bool isBest;

  /// The already-localized value printed above it.
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartBar &&
          other.ratio == ratio &&
          other.isBest == isBest &&
          other.label == label;

  @override
  int get hashCode => Object.hash(ratio, isBest, label);
}

/// Everything one bar is drawn from, as a value.
@immutable
final class BarScene {
  /// Creates a scene.
  const BarScene({
    required this.fill,
    required this.stripe,
    required this.ink,
    required this.borderWidth,
    required this.shadow,
    required this.pitch,
    required this.angle,
  });

  /// The base colour.
  final Color fill;

  /// The stripe drawn over it — the non-colour channel, so the best bar is
  /// still distinguishable in greyscale by its lighter stripe.
  final Color stripe;

  /// The border and shadow ink.
  final Color ink;

  /// The border width.
  final double borderWidth;

  /// The hard offset shadow. It does **not** mirror.
  final Offset shadow;

  /// Stripe spacing.
  final double pitch;

  /// Stripe angle, in degrees.
  final double angle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarScene &&
          other.fill == fill &&
          other.stripe == stripe &&
          other.ink == ink &&
          other.borderWidth == borderWidth &&
          other.shadow == shadow &&
          other.pitch == pitch &&
          other.angle == angle;

  @override
  int get hashCode =>
      Object.hash(fill, stripe, ink, borderWidth, shadow, pitch, angle);
}

/// Paints one striped, ink-bordered bar with its hard offset shadow.
///
/// Every `Paint` is built in the constructor. This painter sits inside a card
/// that repaints whenever the pane scrolls.
class BarPainter extends CustomPainter {
  /// Creates a painter for [scene].
  BarPainter(this.scene)
    : _fill = Paint()..color = scene.fill,
      _ink = Paint()..color = scene.ink,
      _border = Paint()
        ..color = scene.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = scene.borderWidth,
      _stripe = Paint()
        ..color = scene.stripe
        ..style = PaintingStyle.stroke
        ..strokeWidth = scene.pitch / 2;

  /// What to paint.
  final BarScene scene;

  final Paint _fill;
  final Paint _ink;
  final Paint _border;
  final Paint _stripe;

  /// The bar's corner radii. `app.html`: `border-radius:8px 8px 3px 3px`.
  static const Radius topRadius = Radius.circular(8);

  /// The bottom corners, which sit on the axis.
  static const Radius bottomRadius = Radius.circular(3);

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndCorners(
      Offset.zero & size,
      topLeft: topRadius,
      topRight: topRadius,
      bottomLeft: bottomRadius,
      bottomRight: bottomRadius,
    );

    // The shadow first, offset, and it does NOT mirror: one imaginary light
    // for the whole app, the same rule every raised surface follows.
    canvas
      ..drawRRect(body.shift(scene.shadow), _ink)
      ..save()
      ..clipRRect(body)
      ..drawRRect(body, _fill);

    // The stripes run at a fixed angle in PAGE space. They are texture, and a
    // texture that flipped per locale would be a different drawing for no
    // reason a reader could name.
    final radians = scene.angle * math.pi / 180;
    final step = scene.pitch / math.cos(radians);
    final lean = size.height * math.tan(radians);

    for (var x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(Offset(x, size.height), Offset(x + lean, 0), _stripe);
    }

    canvas
      ..restore()
      ..drawRRect(body.deflate(scene.borderWidth / 2), _border);
  }

  @override
  bool shouldRepaint(BarPainter old) => old.scene != scene;
}

/// The last few runs, as bars over a true-zero axis.
///
/// **The plotted series is pinned left to right in every locale.** A chart is a
/// time axis: reversing it under RTL would say the player got worse. The card
/// around it, its heading and its axis labels all mirror normally — this is
/// exactly the pinned-painter island `i18n-rtl-l10n` sanctions, applied to one
/// subtree and no wider.
///
/// **The axis is true zero.** The band's bottom edge IS the 3px ink line, so no
/// bar can overstate its run by starting above the baseline.
class RunBarChart extends StatelessWidget {
  /// Creates the chart over [bars].
  const RunBarChart({
    required this.bars,
    required this.semanticLabel,
    super.key,
  });

  /// The series, oldest first.
  final List<ChartBar> bars;

  /// What a screen reader hears instead of the drawing.
  final String semanticLabel;

  /// The band's height. `app.html`: `.bars{height:164px}`.
  static const double bandHeight = 164;

  /// The gap between bars. `app.html`: `.bars{gap:7px}`.
  static const double barGap = 7;

  /// The gap between a bar and its value label. `app.html`: `.bar{gap:5px}`.
  static const double labelGap = 5;

  /// How many lines a value label may take before the band reserves for it.
  ///
  /// Two, and the reserve is unconditional. Reserving one and letting the
  /// second line push is what overflows; reserving two costs eight points of
  /// bar height and cannot.
  static const int labelMaxLines = 2;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    final labelStyle = type.label.copyWith(
      color: colours.textSecondary,
      letterSpacing: 0,
    );

    final ordinary = BarScene(
      fill: colours.gameStroop,
      stripe: colours.gameStroopDeep,
      ink: colours.border,
      borderWidth: shape.borderWidth,
      shadow: shape.eChip,
      pitch: shape.stripePitch,
      angle: shape.stripeAngle,
    );
    final best = BarScene(
      fill: colours.accent,
      stripe: colours.accentDeep,
      ink: colours.border,
      borderWidth: shape.borderWidth,
      shadow: shape.eChip,
      pitch: shape.stripePitch,
      angle: shape.stripeAngle,
    );

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: bandHeight,
          // THE LABEL BAND IS MEASURED, and it is the SAME height for every
          // column. A constant reserve was wrong the moment the type step, the
          // script or the text scale moved — Vazirmatn's line box is not
          // Fredoka's — and a per-column reserve is worse: one label wrapping
          // would give its bar a shorter band than its neighbours, and a chart
          // whose bars are drawn to different scales says something false.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final labelBand = _labelBandHeight(
                context,
                labelStyle,
                _columnWidth(constraints.maxWidth),
              );
              final barBand = math.max<double>(
                0,
                bandHeight - labelBand - labelGap,
              );

              return Row(
                // THE PIN. Not the ambient direction: see the class doc.
                textDirection: TextDirection.ltr,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  for (final (index, bar) in bars.indexed) ...<Widget>[
                    if (index > 0) const SizedBox(width: barGap),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(
                            height: labelBand,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Text(
                                bar.label,
                                // The LABEL is a number and reads left to
                                // right in every language, like every other
                                // number in the app.
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.center,
                                maxLines: labelMaxLines,
                                style: labelStyle,
                              ),
                            ),
                          ),
                          const SizedBox(height: labelGap),
                          SizedBox(
                            height: barBand * bar.ratio.clamp(0, 1),
                            child: RepaintBoundary(
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: BarPainter(
                                  bar.isBest ? best : ordinary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// How wide one column is inside [available].
  double _columnWidth(double available) =>
      bars.isEmpty ? 0 : (available - barGap * (bars.length - 1)) / bars.length;

  /// The height the tallest label needs at [width], for the style in use.
  ///
  /// A real measurement rather than `fontSize * height`: a `TextStyle` may
  /// carry a null height, the resolved Arabic face has its own line box, and
  /// the label wraps at seven columns wide before anyone touches the text
  /// scale. It runs once per chart build, not once per frame.
  double _labelBandHeight(
    BuildContext context,
    TextStyle style,
    double width,
  ) {
    final scaler = MediaQuery.textScalerOf(context);
    var tallest = 0.0;

    for (final bar in bars) {
      final painter = TextPainter(
        text: TextSpan(text: bar.label, style: style),
        maxLines: labelMaxLines,
        textScaler: scaler,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: math.max<double>(0, width));

      tallest = math.max(tallest, painter.height);
      painter.dispose();
    }

    return tallest;
  }
}
