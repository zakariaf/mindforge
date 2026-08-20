import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

/// A countdown drawn as a ring, with the remaining time in the middle.
///
/// **The sweep does not mirror.** It is a clock: it runs from twelve, clockwise,
/// in every locale. A ring that ran anticlockwise in Persian would be a
/// different instrument, not a translated one — the same reasoning that keeps
/// the `motion` glyph, which is also a clock, unflipped.
class TimerRing extends StatelessWidget {
  /// Creates a ring [progress] of the way through its run.
  const TimerRing({
    required this.progress,
    required this.label,
    required this.semanticLabel,
    this.size = 96,
    this.alarming = false,
    super.key,
  });

  /// How much of the run has elapsed, from 0 to 1.
  final double progress;

  /// The already-localized time in the middle.
  final String label;

  /// The already-localized label a screen reader announces.
  final String semanticLabel;

  /// The ring's diameter.
  final double size;

  /// Whether the run is nearly over.
  final bool alarming;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    return Semantics(
      label: semanticLabel,
      value: label,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress.clamp(0.0, 1.0),
                track: colours.surfaceSunk,
                sweep: alarming ? colours.danger : colours.accent,
                ink: colours.border,
                width: shape.borderWidth,
              ),
              child: Center(
                child: Text(
                  label,
                  style: type.numericHud.copyWith(
                    color: alarming ? colours.danger : colours.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.sweep,
    required this.ink,
    required this.width,
  }) : _trackPaint = Paint()
         ..color = track
         ..style = PaintingStyle.stroke
         ..strokeWidth = width * 3,
       _sweepPaint = Paint()
         ..color = sweep
         ..style = PaintingStyle.stroke
         ..strokeWidth = width * 3
         ..strokeCap = StrokeCap.round,
       _inkPaint = Paint()
         ..color = ink
         ..style = PaintingStyle.stroke
         ..strokeWidth = width;

  final double progress;
  final Color track;
  final Color sweep;
  final Color ink;
  final double width;

  final Paint _trackPaint;
  final Paint _sweepPaint;
  final Paint _inkPaint;

  /// Twelve o'clock, in radians from the positive x axis.
  static const double _twelve = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2 - width * 2;
    final box = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: radius,
    );

    canvas
      ..drawArc(box, 0, math.pi * 2, false, _trackPaint)
      // Always clockwise from twelve. No direction is read anywhere in this
      // painter, which is what makes that true rather than merely intended.
      ..drawArc(box, _twelve, math.pi * 2 * progress, false, _sweepPaint)
      ..drawCircle(box.center, radius + width * 1.5, _inkPaint)
      ..drawCircle(box.center, radius - width * 1.5, _inkPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.sweep != sweep ||
      old.ink != ink ||
      old.width != width;
}
