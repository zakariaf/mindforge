// lib/shared/motion/press_physics.dart
//
// The one press interaction in MindForge. `PopSurface` (owned by
// `sunburst-components`) composes this and paints the chrome; nothing else in
// the app drives a press controller of its own.
//
// It owns four things and nothing else:
//   - the geometry, DERIVED from the resting shadow (travel = offset - 1)
//   - one interruptible AnimationController at the themed durTap (120ms)
//   - the state-vs-animation split under reduce-motion
//   - firing the commit moment's haptic exactly once, via FeedbackService
//
// It does NOT paint the fill, the 3px ink border, the shadow, the radius or the
// focus ring: it hands a PressGeometry to `builder` and lets the chrome layer
// paint. That seam is why this file has no opinion about PopSurface's API.
//
// It also declares NO elevation enum. `PopElevation` (flat, e1…e4) is declared
// once, by `sunburst-components` in `lib/ui/components/pop_surface.dart`, and is
// the app-wide vocabulary for how high a surface sits. A second enum here would
// be a rival name for the same concept *and* an upward ui -> shared import, so
// this widget takes the geometry already resolved: PopSurface reads
// `elevation.restOffset(shape)`, `shape.pressTranslate(rest)` and
// `elevation.pressScale(shape)` and hands the four numbers down.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/shared/feedback/feedback_service.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/theme/sunburst_motion.dart';

/// What the chrome layer needs in order to paint one frame of a press.
///
/// [shadow] is a live value, not a token read: it interpolates between the
/// elevation's resting offset and its pressed offset.
@immutable
class PressGeometry {
  const PressGeometry({
    required this.t,
    required this.shadow,
    required this.isDown,
  });

  /// 0 at rest, 1 fully pressed. Drives the chrome's fill cross.
  final double t;

  /// The hard offset shadow for this frame, on both axes.
  final Offset shadow;

  /// True from pointer-down until the release tween starts. Chrome uses this to
  /// pick the deep fill; it is a state, so it survives reduce-motion.
  final bool isDown;
}

typedef PressBuilder = Widget Function(
  BuildContext context,
  PressGeometry press,
  Widget? child,
);

/// Wraps [child] in the Sunburst Pop press interaction.
///
/// [onPressed] null renders the surface inert: `system.html` draws disabled as
/// `transform: none`, so the controller is never driven.
class PressPhysics extends ConsumerStatefulWidget {
  const PressPhysics({
    required this.restShadow,
    required this.pressedShadow,
    required this.travel,
    required this.scale,
    required this.builder,
    required this.commitMoment,
    this.child,
    this.onPressed,
    this.minTarget = 0,
    super.key,
  });

  /// Hard offset shadow at rest — `elevation.restOffset(shape)`, or `Offset.zero`
  /// for a surface that carries none (the ghost button, a found tile).
  final Offset restShadow;

  /// What is left behind while held down — `SunburstShape.pressedShadow` (1,1)
  /// at every step, or `Offset.zero` where there was no shadow to collapse.
  final Offset pressedShadow;

  /// How far the surface travels on both axes. Always `shape.pressTranslate(rest).dx`
  /// except on the ghost button, where `system.html` states 2px outright because
  /// there is no shadow to derive it from (`.btn--ghost:active`).
  final double travel;

  /// `shape.pressScale` 0.98 above e1, `shape.pressScaleSmall` 0.97 at e1. Both
  /// are transcribed tokens; `PopElevation.pressScale(shape)` picks between them.
  final double scale;

  /// The ≥48px house floor, owned by `sunburst-components`. It is passed in
  /// rather than applied by the caller because the constraint has to sit BETWEEN
  /// the gesture and the transform: outside it the target shrinks to the artwork,
  /// inside it the target travels with the press and eats the tap.
  final double minTarget;

  /// Paints the chrome for one frame. `PopSurface` passes its own painter here.
  final PressBuilder builder;

  /// Fired once, on the frame [onPressed] runs. Usually [Moment.buttonCommit];
  /// a game board passes its own row, e.g. [Moment.tileFound].
  final Moment commitMoment;

  /// The part of the subtree that does not depend on the press, rebuilt once.
  final Widget? child;

  final VoidCallback? onPressed;

  @override
  ConsumerState<PressPhysics> createState() => _PressPhysicsState();
}

class _PressPhysicsState extends ConsumerState<PressPhysics>
    with SingleTickerProviderStateMixin {
  // No duration here: durTap is a themed value and the theme needs a context.
  // It is set in didChangeDependencies and passed explicitly on every drive.
  late final AnimationController _press = AnimationController(vsync: this);

  late SunburstMotion _motion;
  bool _isDown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = SunburstMotion.of(context);
    _press.duration = _motion.durTap;
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null;

  /// animateTo, never forward/reverse from a reset controller: a fast player
  /// releases before the press-down finishes and the tween must resume from
  /// wherever the controller currently sits.
  void _drive(double target) {
    final duration = _motion.resolve(context, _motion.durTap);
    if (duration == Duration.zero) {
      _press.value = target;
      return;
    }
    _press.animateTo(target, duration: duration, curve: _motion.easePop);
  }

  void _onTapDown(TapDownDetails _) {
    if (!_enabled) return;
    setState(() => _isDown = true);
    _drive(1);
  }

  void _onTapCancel() {
    if (!_enabled) return;
    // A steal by the scroller: no haptic, no commit, no state change.
    setState(() => _isDown = false);
    _drive(0);
  }

  void _onTap() {
    if (!_enabled) return;
    // Commit, then the haptic on the same frame, then release. Exactly once —
    // never in the controller's listener, never in onEnd.
    widget.onPressed!.call();
    ref.read(feedbackServiceProvider).fire(widget.commitMoment);
    setState(() => _isDown = false);
    _drive(0);
  }

  @override
  Widget build(BuildContext context) {
    // Reduce motion drops the TRANSFORM only. The shadow collapse and the fill
    // cross are state and still apply, at zero duration (system.html §09).
    final dropTransform = MediaQuery.disableAnimationsOf(context);

    // No Semantics here on purpose: PopSurface wraps this in the button
    // semantics and the label, so a Semantics node here would nest a second
    // one. `accessibility-as-code` owns that contract.
    //
    // The GestureDetector is opaque and sits OUTSIDE both the ConstrainedBox and
    // the Transform, so the tap target never travels with the paint.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: widget.minTarget,
          minHeight: widget.minTarget,
        ),
        child: AnimatedBuilder(
          animation: _press,
          builder: (context, child) {
            final t = _enabled ? _press.value : 0.0;
            final shadow =
                Offset.lerp(widget.restShadow, widget.pressedShadow, t)!;
            final travel = dropTransform ? 0.0 : t * widget.travel;
            final scale = dropTransform ? 1.0 : 1 - t * (1 - widget.scale);

            return Transform.translate(
              offset: Offset(travel, travel),
              child: Transform.scale(
                scale: scale,
                child: widget.builder(
                  context,
                  PressGeometry(t: t, shadow: shadow, isDown: _isDown),
                  child,
                ),
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
