import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_motion.dart';

/// Where a pressed surface goes, as a pure value.
///
/// **The travel has no direction component and never will.** A press moves the
/// object *toward its own shadow*, and the shadow is a light-source constant —
/// one imaginary light for the whole app, fixed at the top-start of the page,
/// not a property of reading order. So the travel is `(+dx, +dy)` in every
/// locale, and this class holds no `TextDirection` to derive a sign from.
///
/// Pure, so the press law is a unit test rather than a widget test.
@immutable
final class PressGeometry {
  /// Creates the geometry for a surface resting at [restOffset].
  const PressGeometry({required this.restOffset, required this.pressScale});

  /// The surface's hard-shadow offset at rest, or `null` when it is flat.
  final Offset? restOffset;

  /// How far the surface shrinks while held.
  final double pressScale;

  /// How far the surface moves while held.
  ///
  /// One logical pixel short of the resting offset on both axes, so the surface
  /// arrives just above the page rather than flat against it — the shadow it
  /// keeps is what says it is still a raised thing being held down.
  Offset get travel {
    final rest = restOffset;
    if (rest == null) return Offset.zero;

    return Offset(rest.dx - 1, rest.dy - 1);
  }

  /// The offset a surface is at, given how far into the press it is.
  Offset offsetAt(double t) => Offset.lerp(Offset.zero, travel, t)!;

  /// The scale a surface is at, given how far into the press it is.
  double scaleAt(double t) => 1 - (1 - pressScale) * t;

  @override
  bool operator ==(Object other) =>
      other is PressGeometry &&
      other.restOffset == restOffset &&
      other.pressScale == pressScale;

  @override
  int get hashCode => Object.hash(restOffset, pressScale);
}

/// Builds a subtree from how far into a press it is.
typedef PressBuilder =
    Widget Function(BuildContext context, double t, Widget? child);

/// The one press controller in the app.
///
/// It owns exactly three things: an interruptible `AnimationController` at the
/// motion scale's tap duration, the reduce-motion split, and the rule that the
/// **hit area does not move**. The travel is applied to a `Transform` *inside*
/// the sized box the gesture listens on, so a finger that pressed the edge of a
/// button is still on the button when it lifts. A `Transform` wrapped around
/// the gesture detector moves the target out from under the finger and eats the
/// tap, which is the single most common way this effect is built wrong.
///
/// **It owns no haptic.** `PopSurface` fires the commit moment through
/// `FeedbackService`, so the acknowledgement is decided by the catalog and this
/// widget only decides where the surface goes.
class PressPhysics extends StatefulWidget {
  /// Creates a press controller over [builder].
  const PressPhysics({
    required this.geometry,
    required this.builder,
    this.enabled = true,
    this.child,
    super.key,
  });

  /// Where the press travels to.
  final PressGeometry geometry;

  /// Builds the pressable subtree from the current press progress.
  final PressBuilder builder;

  /// Whether the surface responds to a pointer at all.
  final bool enabled;

  /// A subtree that does not depend on the press, rebuilt once.
  final Widget? child;

  @override
  State<PressPhysics> createState() => PressPhysicsState();
}

/// The state of a [PressPhysics], public so a test can drive it directly.
class PressPhysicsState extends State<PressPhysics>
    with SingleTickerProviderStateMixin {
  /// Constructed with **no** duration on purpose.
  ///
  /// Every drive passes its own, resolved from the motion scale at the moment
  /// it runs — because reduce motion can be switched on while the app is open,
  /// and a duration captured at construction would keep animating after it. It
  /// also means there is no raw `Duration` in this file, which is what
  /// `check_motion_tokens.sh` is checking for.
  ///
  /// Created in [initState], **not** as a `late final` initialiser. A disabled
  /// surface never reaches the branch that touches it, so a lazy field would
  /// still be uninitialised at `dispose()` — and `dispose()` touching it
  /// CREATES it, mid-unmount, where `AnimationController` looks up `TickerMode`
  /// on a deactivated element and throws "Looking up a deactivated widget's
  /// ancestor is unsafe". Measured, on the first disabled-surface test.
  late final AnimationController _controller;

  /// The curved value the surface is actually drawn from.
  ///
  /// The controller runs LINEARLY and the curve is applied here, because
  /// `AnimationController` clamps its own value to `[lowerBound, upperBound]`.
  /// `easePop` peaks near 1.09 — the overshoot it is named for — so driving the
  /// controller with the curve threw the spring away and, worse, arrived early:
  /// measured, the travel reached its end at 30ms of a 120ms press and then sat
  /// still for 90ms.
  ///
  /// A `CurveTween` chained onto the controller, not a `CurvedAnimation`. A
  /// `CurvedAnimation` registers a status listener on its parent and has to be
  /// disposed; one built per drive is two per tap, never released until the
  /// controller is, so a player who taps two hundred times in a run leaves four
  /// hundred live listeners on it. A chained `Animatable` registers nothing.
  late Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _curved = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Drives the press toward [target], honouring reduce motion.
  ///
  /// `animateTo`, never `forward`: a second tap arriving mid-release has to
  /// pick up from where the surface actually is, not restart from rest. That is
  /// the difference between a control that feels solid and one that jumps.
  void _driveTo(double target) {
    // GestureBinding caches the hit-test path for a live pointer, so the UP
    // event is still delivered to a Listener whose element has been unmounted
    // — a sheet that auto-closes or a route that pops under a held finger.
    // Reading context there throws.
    if (!mounted) return;

    final motion = SunburstMotion.of(context);
    final duration = motion.resolve(context, motion.durTap);

    if (duration == Duration.zero) {
      // Reduce motion means STOP, not "faster". The transform is dropped
      // entirely and the surface's other press residue — the deeper fill, the
      // (1,1) shadow — still applies, on the same frame.
      _controller.value = target;
      return;
    }

    // The CURVE is applied to the controller's output, not passed to
    // animateTo: passing it makes the controller clamp the overshoot away.
    _curved = _controller.drive(CurveTween(curve: motion.easePop));

    // unawaited: the returned TickerFuture completes when the animation
    // finishes or is cancelled by the next press, and neither is something a
    // caller waits on.
    unawaited(_controller.animateTo(target, duration: duration));
  }

  void _onPointerDown() => _driveTo(1);
  void _onPointerUp() => _driveTo(0);

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.builder(context, 0, widget.child);
    }

    return Listener(
      onPointerDown: (_) => _onPointerDown(),
      onPointerUp: (_) => _onPointerUp(),
      onPointerCancel: (_) => _onPointerUp(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) =>
            widget.builder(context, _curved.value, child),
        child: widget.child,
      ),
    );
  }
}
