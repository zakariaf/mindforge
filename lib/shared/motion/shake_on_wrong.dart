import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/feedback/moment_catalog.dart';
import 'package:mindforge/shared/motion/motion_role.dart';
import 'package:mindforge/theme/sunburst_motion.dart';

/// A bounded horizontal shake, played once on a wrong answer.
///
/// **`MotionAxis.inline`, and it still reads no `Directionality`.** The sweep is
/// symmetric about zero — `0 -> -4 -> +4 -> 0` — so it travels equally far each
/// way and lands back where it started. Mirroring it would change only which
/// side it jerks to FIRST, and a wrong answer carries no directional meaning
/// for that to contradict. It is the one inline moment in the catalog that
/// needs no direction, and that is a property of THIS sweep rather than of
/// shakes in general.
///
/// The argument rests entirely on the two amplitudes being equal, so
/// `shake_on_wrong_test.dart` asserts that directly. A locale matrix cannot:
/// an asymmetric sweep is equally asymmetric in every locale.
///
/// **Two cycles, and the stop condition is that there is no third.** No
/// `repeat`, no loop, no `while` — two `forward` passes, and a `mounted` guard
/// between them because the board can be torn down mid-sweep by a run ending.
///
/// **Created here and nowhere else.** Both games need it — the answer key in
/// Stroop Rush and the tile in Schulte Grid — so it is shared by construction
/// rather than by a later refactor. A copy under `lib/games/**` is a review
/// reject, and `single_press_implementation_test` has the sibling gate.
class ShakeOnWrong extends StatefulWidget {
  /// Shakes [child] on each false-to-true edge of [isWrong].
  const ShakeOnWrong({
    required this.isWrong,
    required this.child,
    super.key,
  });

  /// Whether the wrapped thing is currently wrong.
  ///
  /// The **edge** is what plays, not the value. A board that rebuilds every
  /// frame while a wrong key is still highlighted must not shake every frame.
  final bool isWrong;

  /// What shakes.
  final Widget child;

  @override
  State<ShakeOnWrong> createState() => _ShakeOnWrongState();
}

class _ShakeOnWrongState extends State<ShakeOnWrong>
    with SingleTickerProviderStateMixin {
  /// Rests at 0, which is also the sweep's start and end.
  late final AnimationController _controller = AnimationController(vsync: this);

  /// The sweep, transcribed keyframe for keyframe.
  ///
  /// `system.html`: `0%,100%{translateX(0)} 25%{translateX(-4px)}
  /// 75%{translateX(4px)}` — hence the 25/50/25 weights. The curve is chained
  /// onto each SEGMENT, which is also what CSS does: a timing function applies
  /// between each pair of keyframes, not once across the whole animation.
  /// The sweep, transcribed keyframe for keyframe.
  ///
  /// `system.html`: `0%,100%{translateX(0)} 25%{translateX(-4px)}
  /// 75%{translateX(4px)}` — hence the 25/50/25 weights. The curve is chained
  /// onto each SEGMENT, which is also what CSS does: a timing function applies
  /// between each pair of keyframes, not once across the whole animation.
  late final Animation<double> _dx = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: -_amplitude).chain(_ease),
        weight: 25,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -_amplitude, end: _amplitude).chain(_ease),
        weight: 50,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: _amplitude, end: 0).chain(_ease),
        weight: 25,
      ),
    ],
  ).animate(_controller);

  late final Animatable<double> _ease = CurveTween(
    curve: SunburstMotion.of(
      context,
    ).curveFor(kMomentCatalog[Moment.answerWrong]?.curve ?? CurveRole.out),
  );

  /// How far the sweep travels to each side.
  late final double _amplitude = SunburstMotion.of(context).shakeAmplitude;

  @override
  void didUpdateWidget(ShakeOnWrong oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isWrong && !oldWidget.isWrong) unawaited(_play());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    final motion = SunburstMotion.of(context);
    final duration = motion.resolve(
      context,
      motion.durationFor(
        kMomentCatalog[Moment.answerWrong]?.duration ?? MotionRole.celebrate,
      ),
    );

    // Reduce motion means STOP, not "faster". The caller's residue carries the
    // wrong answer: the depth drop and the ink strike bar are state, and they
    // are what a player with motion off sees.
    if (duration == Duration.zero) return;

    _controller.duration = duration;

    await _controller.forward(from: 0);
    // The guard, not a courtesy: a run can end and take the board down between
    // the two passes, and resuming on a disposed controller throws.
    if (!mounted) return;
    await _controller.forward(from: 0);

    // AND THERE IS NO THIRD LINE. That absence is the stop condition — the
    // catalog declares cycles: 2 for answerWrong, and a shake that keeps going
    // stops reading as feedback and starts reading as a fault.
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _dx,
    // Built once and passed through: the child does not depend on the sweep.
    child: widget.child,
    builder: (context, child) =>
        Transform.translate(offset: Offset(_dx.value, 0), child: child),
  );
}
