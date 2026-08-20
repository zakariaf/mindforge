import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/shared/feedback/feedback_service.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/feedback/moment_catalog.dart';
import 'package:mindforge/shared/motion/motion_role.dart';
import 'package:mindforge/theme/sunburst_motion.dart';

/// A single bounded scale pop, played once when the thing it wraps arrives.
///
/// **`MotionAxis.none`.** A scale has no reading direction to have, and the
/// resting tilt is a shape constant of the badge — the same class of decision
/// as the hard offset shadow, and for the same reason. So this file reads no
/// `Directionality` and negates no sign, in any locale.
///
/// The stop condition is that there is no loop: one `forward`, no `repeat`, no
/// re-entry. The latch is set before any early return, so a celebration that
/// declined to animate has still been played and will not play later.
///
/// It wraps rather than paints, and it **blocks nothing** — no `AbsorbPointer`,
/// no `IgnorePointer`, no barrier. A celebration that swallowed input would eat
/// the "play again" tap for the length of its own pop.
class PopCelebration extends ConsumerStatefulWidget {
  /// Celebrates [moment] over [child].
  const PopCelebration({
    required this.moment,
    required this.child,
    this.restingTiltDegrees = 0,
    super.key,
  });

  /// The moment being celebrated. Its haptic and sound come from the catalog.
  final Moment moment;

  /// What is being celebrated.
  final Widget child;

  /// A fixed angle the child sits at, in degrees.
  ///
  /// Applied **outside** the animation, because it is a state rather than a
  /// motion: it survives reduce motion, and it is still there long after the
  /// pop has finished.
  final double restingTiltDegrees;

  @override
  ConsumerState<PopCelebration> createState() => _PopCelebrationState();
}

class _PopCelebrationState extends ConsumerState<PopCelebration>
    with SingleTickerProviderStateMixin {
  /// Rests at 1, so a celebration that never plays is already at its end state.
  ///
  /// Every interruption — reduce motion, an off-route mount, disposal
  /// mid-flight — therefore lands on the finished frame rather than on a
  /// shrunken one.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1,
  );

  /// The pop, as a value shape rather than a timing.
  ///
  /// `system.html` section 10: scale 0.86 -> 1.06 -> 1.0, never looping.
  ///
  /// The curve is chained onto each SEGMENT, and the controller runs linearly.
  /// `AnimationController` clamps its own value to `[0, 1]` and `easePop` is
  /// named for overshooting past 1, so driving the controller with it throws
  /// the spring away and arrives early — the same trap `PressPhysics`
  /// documents. `TweenSequence` also expects its input in `[0, 1]` and
  /// extrapolates outside it, so an overshooting curve in FRONT of the sequence
  /// would push the tail below 1.0 and leave the badge smaller than it started.
  /// Inside a segment the overshoot lands where it belongs: measured, the peak
  /// is 1.075 rather than the nominal 1.06.
  late final Animation<double> _scale = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.86, end: 1.06).chain(_pop),
        weight: 60,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.06, end: 1).chain(_pop),
        weight: 40,
      ),
    ],
  ).animate(_controller);

  /// The moment's own curve, read off the catalog.
  late final Animatable<double> _pop = CurveTween(
    curve: SunburstMotion.of(
      context,
    ).curveFor(kMomentCatalog[widget.moment]?.curve ?? CurveRole.pop),
  );

  /// Whether this celebration has already happened.
  ///
  /// Set **before** every early return. A celebration that declined to animate
  /// still happened, and setting the latch afterwards would replay it the next
  /// time the theme, the locale or a parent's state moved.
  bool _hasPlayed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _playOnce();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playOnce() {
    if (_hasPlayed) return;
    _hasPlayed = true;

    // FIRST, ABOVE EVERY STOP CONDITION. Reduce motion changes what the moment
    // looks like and an off-route mount changes whether it is worth drawing;
    // neither changes whether it HAPPENED. An early return placed above this
    // line is the bug the ordering exists to prevent.
    ref.read(feedbackServiceProvider).fire(widget.moment);

    if (MediaQuery.disableAnimationsOf(context)) return;

    // Nobody is looking at a screen under a sheet or behind a pushed route.
    if (ModalRoute.of(context)?.isCurrent == false) return;

    final motion = SunburstMotion.of(context);
    final spec = kMomentCatalog[widget.moment];

    _controller.duration = motion.durationFor(
      spec?.duration ?? MotionRole.celebrate,
    );

    // forward(from: 0), not animateTo from the resting 1: animateTo(1) from 1
    // is a no-op, and resetting the value afterwards cancels the run it was
    // supposed to start. The controller runs LINEARLY; the curve lives in the
    // tween sequence above.
    unawaited(_controller.forward(from: 0));
  }

  @override
  Widget build(BuildContext context) {
    // The tilt sits OUTSIDE the animated scale: a resting transform is a state
    // and survives reduce motion, while the pop is motion and does not.
    return Transform.rotate(
      angle: widget.restingTiltDegrees * math.pi / 180,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
