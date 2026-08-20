import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/feedback/moment_catalog.dart';
import 'package:mindforge/shared/feedback/moment_spec.dart';
import 'package:mindforge/shared/motion/motion_role.dart';
import 'package:mindforge/theme/sunburst_motion.dart';

/// The one way a `Moment` is played as an animation.
///
/// `PopCelebration` and `ShakeOnWrong` were the same widget with different
/// tweens: a durationless controller, a tween sequence whose curve is chained
/// onto each segment, a resolved duration, an early return under reduce motion,
/// a bounded number of passes, and a dispose. Both re-derived the same lesson
/// in prose. E08 has at least three more animating moments — `countdownBeat`,
/// `homeCardEnter`, `resultsReveal` — which is where a fourth copy would have
/// come from.
///
/// **It never hands out a curved controller**, which is what makes the trap
/// both of them documented separately unwritable here. `AnimationController`
/// clamps its own value to `[0, 1]`, and the pop curves overshoot past 1 — so
/// driving the controller with the curve throws the spring away and, worse,
/// arrives early. Measured on the celebration before this existed: a 240ms pass
/// finished in about 50. The controller runs LINEARLY and the curve belongs to
/// the value, via [curved].
///
/// **The pass count comes from the catalog row**, so `cycles: 2` on `answerWrong` is
/// the stop condition rather than a comment beside a second hardcoded call.
/// Editing the table changes the behaviour, which is the whole claim a table
/// makes over a switch statement.
///
/// The motion axis is deliberately not consulted here: whether a motion mirrors is
/// a property of the *offsets* a subclass builds, and the two users of this
/// mixin build offsets that do not mirror at all.
mixin MomentDrive<W extends StatefulWidget> on State<W>
    implements TickerProvider {
  /// The moment this widget plays.
  Moment get moment;

  /// Constructed with **no** duration, on purpose.
  ///
  /// Every pass resolves its own from the motion scale at the moment it runs,
  /// because reduce motion can be switched on while the app is open and a
  /// duration captured at construction would keep animating after it. It also
  /// means no raw `Duration` appears in any file using this mixin.
  late final AnimationController controller = AnimationController(vsync: this);

  /// The catalog row for [moment].
  MomentSpec get spec => specFor(moment);

  /// The moment's curve, as an `Animatable` to chain onto a tween.
  ///
  /// A `CurveTween` rather than a `CurvedAnimation`: it is a pure value
  /// transform with no listeners and nothing to dispose, and it can be chained
  /// onto each SEGMENT of a `TweenSequence`. A curve in front of the whole
  /// sequence is wrong twice over — `TweenSequence` extrapolates outside
  /// `[0, 1]`, so an overshooting curve pushes the tail past the sequence's
  /// final value.
  Animatable<double> get curved => CurveTween(
    curve: SunburstMotion.of(context).curveFor(spec.curve ?? CurveRole.pop),
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Which run is current.
  ///
  /// Two overlapping calls share one controller, and `forward(from: 0)` cancels
  /// whatever was running — but a cancelled `TickerFuture` completes its
  /// primary future NORMALLY, so the older loop wakes up and starts a pass of
  /// its own. Measured, the two happen to net out to a correct restart at
  /// today's cycle counts, which is a property of the arithmetic rather than of
  /// the code. The counter makes it structural: a superseded run stops at its
  /// next pass boundary, so the number of passes after the last trigger is the
  /// number the catalog declares and nothing else.
  int _generation = 0;

  /// Plays the moment's declared number of passes, or nothing.
  ///
  /// Returns `false` when reduce motion collapsed the duration to zero, so a
  /// caller can tell "did not animate" from "animated". Reduce motion means
  /// STOP rather than "faster"; the caller's non-motion residue carries the
  /// moment instead.
  Future<bool> play() async {
    final motion = SunburstMotion.of(context);
    final duration = motion.resolvedDurationFor(context, spec.duration);

    if (duration == Duration.zero) return false;

    final generation = ++_generation;
    controller.duration = duration;

    for (var pass = 0; pass < spec.cycles; pass++) {
      // Two guards, neither a courtesy. A run can end and take the board down
      // between two passes, and resuming on a disposed controller throws. And a
      // newer trigger supersedes this one, which is what keeps the pass count
      // tied to the catalog row rather than to how many times the player was
      // wrong in the last half second.
      if (!mounted || generation != _generation) return true;
      await controller.forward(from: 0);
    }

    return true;
  }

  /// [play] for a caller that is not awaiting it.
  void playUnawaited() => unawaited(play());
}
