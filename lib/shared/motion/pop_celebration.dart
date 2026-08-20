import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/shared/feedback/feedback_service.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/motion/moment_drive.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

/// A single bounded scale pop, played once when the thing it wraps arrives.
///
/// The pop has no reading direction to have, so this file reads no
/// `Directionality` and negates no sign, in any locale.
///
/// The stop condition is that there is no loop: `MomentDrive` plays the number
/// of passes the catalog row declares, and `personalBest` declares one. The
/// latch is set before any early return, so a celebration that declined to
/// animate has still been played and will not play later.
///
/// It wraps rather than paints, and it **blocks nothing** — no `AbsorbPointer`,
/// no `IgnorePointer`, no barrier. A celebration that swallowed input would eat
/// the "play again" tap for the length of its own pop.
///
/// **It carries no tilt.** The `-2.5deg` of `.badge.new` is the badge's own
/// resting geometry and `PopBadge` applies it from `SunburstShape`. A
/// `restingTiltDegrees` inlet here would be a raw-degrees number any call site
/// could pass a literal to, which is exactly what the token exists to prevent.
class PopCelebration extends ConsumerStatefulWidget {
  /// Celebrates [moment] over [child].
  const PopCelebration({
    required this.moment,
    required this.child,
    super.key,
  });

  /// The moment being celebrated. Its haptic, sound, curve, duration and pass
  /// count all come from its catalog row.
  final Moment moment;

  /// What is being celebrated.
  final Widget child;

  @override
  ConsumerState<PopCelebration> createState() => _PopCelebrationState();
}

class _PopCelebrationState extends ConsumerState<PopCelebration>
    with SingleTickerProviderStateMixin, MomentDrive<PopCelebration> {
  @override
  Moment get moment => widget.moment;

  /// The pop, as a value shape rather than a timing.
  ///
  /// `system.html`: scale `celebrationScaleFrom` -> `celebrationScalePeak` ->
  /// 1.0, never looping. The curve is chained onto each segment by
  /// [MomentDrive.curved]; measured, the peak lands at 1.0753 rather than the
  /// nominal 1.06, because a curve chained onto a tween sequence produces the
  /// numbers neither one names alone.
  late final Animation<double> _scale = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: SunburstShape.of(context).celebrationScaleFrom,
          end: SunburstShape.of(context).celebrationScalePeak,
        ).chain(curved),
        weight: 60,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: SunburstShape.of(context).celebrationScalePeak,
          end: 1,
        ).chain(curved),
        weight: 40,
      ),
    ],
  ).animate(controller);

  /// Whether this celebration has already happened.
  ///
  /// Set **before** every early return. A celebration that declined to animate
  /// still happened, and setting the latch afterwards would replay it the next
  /// time the theme, the locale or a parent's state moved.
  bool _hasPlayed = false;

  @override
  void initState() {
    super.initState();
    // Rests at its END state, so a celebration that never plays — reduce
    // motion, an off-route mount, disposal mid-flight — is already finished
    // rather than shrunken.
    controller.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _playOnce();
  }

  void _playOnce() {
    if (_hasPlayed) return;
    _hasPlayed = true;

    // FIRST, ABOVE EVERY STOP CONDITION. Reduce motion changes what the moment
    // looks like and an off-route mount changes whether it is worth drawing;
    // neither changes whether it HAPPENED. An early return placed above this
    // line is the bug the ordering exists to prevent.
    ref.read(feedbackServiceProvider).fire(widget.moment);

    // Nobody is looking at a screen under a sheet or behind a pushed route.
    if (ModalRoute.of(context)?.isCurrent == false) return;

    playUnawaited();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    // A RepaintBoundary as the passed-through child: ScaleTransition pushes a
    // transform layer but still REPAINTS the child inside it every frame, so a
    // badge with text, an ink border and a hard shadow re-rasterizes for the
    // whole celebration. With the boundary it is one rasterization and a layer
    // transform.
    child: RepaintBoundary(child: widget.child),
  );
}
