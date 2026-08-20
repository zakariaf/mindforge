import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_motion.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

/// How much of a run is left, as a striped ink bar.
///
/// **The fill mirrors.** It grows from the start edge, which is the left in
/// English and the right in Persian — a progress bar is a reading-order thing,
/// unlike the shadow it casts.
///
/// The stripe is the non-colour channel: the bar still says how full it is with
/// every colour removed, which is what makes it legible to a player with a
/// colour vision deficiency and in a greyscale screenshot.
///
/// **An advancing fill tweens; it does not jump.** The bar still renders the
/// value it is GIVEN — there is no controller of its own and nothing repeating,
/// so a backgrounded run costs nothing — but a change in that value eases over
/// `durState`, and collapses to the same end value on the same frame under
/// reduce motion.
class PopProgressBar extends StatelessWidget {
  /// Creates a bar filled to [value], a ratio in `[0, 1]`.
  const PopProgressBar({
    required this.value,
    required this.semanticLabel,
    this.semanticValue,
    this.fill,
    super.key,
  });

  /// How full the bar is, from 0 to 1.
  final double value;

  /// The already-localized label a screen reader announces.
  final String semanticLabel;

  /// The already-localized progress a screen reader announces, e.g. `۴۵٪`.
  ///
  /// Passed in, not built here. This was the one component in the catalog that
  /// formatted a number — `'${(value * 100).round()}%'` — and it emitted ASCII
  /// digits and an ASCII percent sign under `fa` and `ckb`, where the rest of
  /// the screen renders `۴۵٪`. No component formats a number; the shell owns
  /// `LocaleNumbers`.
  final String? semanticValue;

  /// The stripe colour. Defaults to the accent.
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final motion = SunburstMotion.of(context);

    return Semantics(
      label: semanticLabel,
      value: semanticValue,
      child: ExcludeSemantics(
        child: PopSurface(
          fill: colours.surfaceSunk,
          radius: BorderRadiusDirectional.all(shape.radiusPill),
          elevation: PopElevation.flat,
          nested: true,
          minTarget: 0,
          // The stripe is clipped INSIDE the painter rather than by a clip
          // widget around it: one of those costs a save layer on every frame
          // of a running timer, and lib/ui/ bans them for that reason.
          child: SizedBox(
            height: 14,
            child: Align(
              // AlignmentDirectional: the fill grows from the START edge, so
              // it grows leftward in an RTL layout without a second code path.
              alignment: AlignmentDirectional.centerStart,
              // TweenAnimationBuilder, not a controller: the bar owns no
              // ticker, holds no state and animates only when the value it is
              // handed actually changes. resolve() collapses the duration to
              // zero under reduce motion, and TweenAnimationBuilder lands on
              // the end value on the same frame when it does.
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: value.clamp(0.0, 1.0),
                  end: value.clamp(0.0, 1.0),
                ),
                duration: motion.resolve(context, motion.durState),
                curve: motion.easeOut,
                // Built once and passed through: the stripe does not depend on
                // how far along the tween is, only on how wide it is drawn.
                child: RepaintBoundary(
                  child: CustomPaint(
                    // size: Size.infinite, because a CustomPaint with no child
                    // and no size measures ZERO and paints nothing — the bar
                    // rendered as an empty track, which the contact sheet
                    // caught and no unit test would have.
                    size: Size.infinite,
                    painter: _StripePainter(
                      colour: fill ?? colours.accent,
                      ink: colours.accentDeep,
                      pitch: shape.stripePitch,
                      angle: shape.stripeAngle,
                      radius: shape.radiusPill,
                    ),
                  ),
                ),
                builder: (context, widthFactor, child) => FractionallySizedBox(
                  widthFactor: widthFactor,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the diagonal stripe that carries the bar's non-colour channel.
class _StripePainter extends CustomPainter {
  _StripePainter({
    required this.colour,
    required this.ink,
    required this.pitch,
    required this.angle,
    required this.radius,
  }) : _base = Paint()..color = colour,
       _stripe = Paint()
         ..color = ink
         ..style = PaintingStyle.stroke
         ..strokeWidth = pitch / 2;

  final Color colour;
  final Color ink;
  final double pitch;
  final double angle;
  final Radius radius;

  final Paint _base;
  final Paint _stripe;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..clipRRect(
        RRect.fromRectAndRadius(Offset.zero & size, radius),
      )
      ..drawRect(Offset.zero & size, _base);

    // The stripes run at a fixed angle in PAGE space, not in reading space:
    // they are texture, and a texture that flipped per locale would be a
    // different drawing for no reason a reader could name.
    final radians = angle * math.pi / 180;
    final step = pitch / math.cos(radians);
    final reach = size.width + size.height;

    for (var x = -size.height; x < reach; x += step) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height * math.tan(radians), 0),
        _stripe,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_StripePainter old) =>
      old.colour != colour ||
      old.ink != ink ||
      old.pitch != pitch ||
      old.angle != angle ||
      old.radius != radius;
}
