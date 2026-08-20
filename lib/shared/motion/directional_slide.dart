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
  DirectionalSlide({
    required this.t,
    required this.beginStart,
    required this.axis,
    required this.moment,
    required this.child,
    super.key,
  }) : assert(
         axis != MotionAxis.fixed,
         'A fixed-axis motion travels toward the light source and never '
         'mirrors. The press is the one that does that, and it belongs in '
         'PressPhysics — routing it here would mirror it.',
       ),
       assert(
         axis != MotionAxis.none,
         'A none-axis moment translates nothing. There is no slide to build.',
       ),
       assert(
         axis != MotionAxis.inline || beginStart.dx != 0,
         'An inline slide with no dx is a vertical motion that was declared '
         'inline. Say vertical, and it stops asking for a direction it does '
         'not use.',
       );

  /// How far into the slide it is.
  final Animation<double> t;

  /// Where the child starts, in start-edge terms.
  final Offset beginStart;

  /// Which axis this motion travels along.
  final MotionAxis axis;

  /// The moment this slide belongs to. Its timing comes from the catalog.
  final Moment moment;

  /// What slides.
  final Widget child;

  /// The duration this slide runs at, already resolved for reduce motion.
  Duration durationIn(BuildContext context) {
    final motion = SunburstMotion.of(context);

    return motion.resolve(
      context,
      motion.durationFor(kMomentCatalog[moment]?.duration ?? MotionRole.move),
    );
  }

  /// The curve this slide runs on.
  Curve curveIn(BuildContext context) => SunburstMotion.of(
    context,
  ).curveFor(kMomentCatalog[moment]?.curve ?? CurveRole.inOut);

  @override
  Widget build(BuildContext context) => SlideTransition(
    position: Tween<Offset>(begin: beginStart, end: Offset.zero).animate(
      CurvedAnimation(parent: t, curve: curveIn(context)),
    ),
    // THE WHOLE MIRRORING MECHANISM. A direction here makes SlideTransition
    // read the x offset in reading order; null makes it read canvas
    // coordinates. Vertical motion gets null, because up is up in every
    // language and handing it a direction would be a claim it does not make.
    textDirection: axis.mirrorsUnderRtl ? Directionality.of(context) : null,
    child: child,
  );
}
