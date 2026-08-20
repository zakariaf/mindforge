import 'package:flutter/widgets.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/feedback/moment_catalog.dart';
import 'package:mindforge/shared/motion/motion_axis.dart';
import 'package:mindforge/shared/motion/motion_role.dart';
import 'package:mindforge/theme/sunburst_motion.dart';

/// The one place in the app a start-edge offset becomes a physical one.
///
/// Everything that travels along the reading axis goes through here — the route
/// transition today, and any sheet or affordance that ever slides sideways.
/// Everything else does not, and `directional_slide_test.dart` asserts that
/// nothing outside this file builds a `SlideTransition`.
///
/// **No `dx` is negated anywhere.** `SlideTransition` takes a `textDirection`
/// of its own: given one it applies the x offset in reading order, and given
/// `null` it applies it in canvas coordinates. Passing the ambient direction
/// for an inline axis and `null` for a vertical one is the entire mirroring
/// mechanism, and it is why hand-inverting a sign — the thing
/// `i18n-rtl-l10n` names outright — is never needed.
///
/// Duration and curve are read off `kMomentCatalog`, so a slide cannot pick a
/// timing the catalog did not declare for its moment.
///
/// **MindForge has no horizontal swipe affordance today.** Nothing in
/// `app.html` drags sideways and the pause sheet rises from the bottom. If one
/// ever lands it takes this widget with `MotionAxis.inline`, and its gesture
/// reads `Directionality.of(context)` at the same seam. Written down here so the
/// answer exists before the feature does.
class DirectionalSlide extends StatelessWidget {
  /// Slides [child] in from [beginStart], expressed in **start-edge** terms.
  ///
  /// `Offset(1, 0)` means "one width toward the end edge" — physically right in
  /// English and physically left in Persian.
  const DirectionalSlide({
    required this.t,
    required this.beginStart,
    required this.moment,
    required this.child,
    super.key,
  });

  /// How far into the slide it is.
  final Animation<double> t;

  /// Where the child starts, in start-edge terms.
  final Offset beginStart;

  /// The moment this slide belongs to.
  ///
  /// **Its axis, duration and curve all come from the catalog row.** The axis
  /// used to be a second required parameter beside it, which meant
  /// `DirectionalSlide(moment: routeTransition, axis: vertical)` compiled, passed
  /// every assert, and silently stopped the route transition mirroring under
  /// Persian — the exact defect the axis column was invented to make
  /// impossible. A widget cannot both read a table and let its caller
  /// contradict it.
  final Moment moment;

  /// Which axis this motion travels along, per the catalog.
  MotionAxis get axis => specFor(moment).axis;

  /// What slides.
  final Widget child;

  /// The duration this slide runs at, already resolved for reduce motion.
  ///
  /// `resolvedDurationFor` rather than the composition written out: it is the
  /// one helper whose job is to never forget the reduce-motion fold, and it had
  /// no callers while two sites re-derived it by hand.
  Duration durationIn(BuildContext context) => SunburstMotion.of(
    context,
  ).resolvedDurationFor(context, specFor(moment).duration);

  /// The curve this slide runs on.
  Curve curveIn(BuildContext context) => SunburstMotion.of(
    context,
  ).curveFor(specFor(moment).curve ?? CurveRole.inOut);

  @override
  Widget build(BuildContext context) {
    assert(
      axis != MotionAxis.fixed && axis != MotionAxis.none,
      '${moment.name} is ${axis.name}: it does not slide. A fixed-axis motion '
      'travels toward the light source and belongs in PressPhysics; a '
      'none-axis moment translates nothing at all.',
    );
    assert(
      axis != MotionAxis.inline || beginStart.dx != 0,
      'An inline slide with no dx is a vertical motion wearing an inline '
      "moment's row. Check the offset, not the axis.",
    );

    return SlideTransition(
      // .chain(CurveTween(...)), not CurvedAnimation: a CurvedAnimation
      // registers a status listener on `t` and has to be disposed, and one
      // built in build() is allocated on every rebuild and never disposed —
      // a listener leak on the route's own animation. A chained Animatable is
      // a pure value transform with nothing to register and nothing to free.
      position: Tween<Offset>(
        begin: beginStart,
        end: Offset.zero,
      ).chain(CurveTween(curve: curveIn(context))).animate(t),
      // THE WHOLE MIRRORING MECHANISM. A direction here makes SlideTransition
      // read the x offset in reading order; null makes it read canvas
      // coordinates. Vertical motion gets null, because up is up in every
      // language and handing it a direction would be a claim it does not make.
      textDirection: axis.mirrorsUnderRtl ? Directionality.of(context) : null,
      child: child,
    );
  }
}
