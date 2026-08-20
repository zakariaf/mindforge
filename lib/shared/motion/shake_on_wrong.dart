import 'package:flutter/widgets.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/motion/moment_drive.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

/// A bounded horizontal shake, played on each false-to-true edge of [isWrong].
///
/// **It moves along the reading axis and still reads no `Directionality`.** The
/// sweep is symmetric about zero — `0 -> -a -> +a -> 0` — so it travels equally
/// far each way and lands back where it started. Mirroring it would change only
/// which side it jerks to FIRST, and a wrong answer carries no directional
/// meaning for that to contradict. It is the one inline moment in the catalog
/// that needs no direction, and that is a property of THIS sweep rather than of
/// shakes in general.
///
/// The argument rests entirely on the two amplitudes being equal, so
/// `shake_on_wrong_test.dart` asserts that directly. A locale matrix cannot: an
/// asymmetric sweep is equally asymmetric in every locale.
///
/// **The number of passes is `cycles` on the catalog row**, not a second
/// hardcoded call with a comment beside it. `answerWrong` declares two, and
/// editing the table changes the behaviour — which is the claim a table makes
/// over a switch statement, and it was not true while the loop was unrolled.
///
/// **Created here and nowhere else.** Both games need it — the answer key in
/// Stroop Rush and the tile in Schulte Grid — so it is shared by construction
/// rather than by a later refactor. A copy under `lib/games/**` is a review
/// reject, and `motion_policy_test.dart` has the gate.
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
    with SingleTickerProviderStateMixin, MomentDrive<ShakeOnWrong> {
  @override
  Moment get moment => Moment.answerWrong;

  /// The sweep, transcribed keyframe for keyframe.
  ///
  /// `system.html`: `0%,100%{translateX(0)} 25%{translateX(-4px)}
  /// 75%{translateX(4px)}` — hence the 25/50/25 weights. The curve is chained
  /// onto each SEGMENT by [MomentDrive.curved], which is also what CSS does: a
  /// timing function applies between each pair of keyframes, not once across
  /// the whole animation.
  late final Animation<double> _dx = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: -_amplitude).chain(curved),
        weight: 25,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -_amplitude, end: _amplitude).chain(curved),
        weight: 50,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: _amplitude, end: 0).chain(curved),
        weight: 25,
      ),
    ],
  ).animate(controller);

  /// How far the sweep travels to each side.
  late final double _amplitude = SunburstShape.of(context).shakeAmplitude;

  @override
  void didUpdateWidget(ShakeOnWrong oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reduce motion means STOP, not "faster", and play() reports that by
    // returning false. The caller's residue carries the wrong answer: the depth
    // drop and the ink strike bar are state, and they are what a player with
    // motion off sees.
    if (widget.isWrong && !oldWidget.isWrong) playUnawaited();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _dx,
    // A RepaintBoundary as the passed-through child. A bare Transform.translate
    // takes RenderTransform's fast path, which repaints the child INTO THE
    // PARENT'S LAYER on every frame — and in a Schulte grid the parent layer is
    // the whole board, for forty-odd frames.
    child: RepaintBoundary(child: widget.child),
    builder: (context, child) =>
        Transform.translate(offset: Offset(_dx.value, 0), child: child),
  );
}
