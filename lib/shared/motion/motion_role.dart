import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_motion.dart';

/// How long a moment takes, named by its role rather than by a number.
///
/// A catalog row says `MotionRole.tap`; it never holds a `Duration`. That is
/// what lets the motion scale be retuned in one place, and what keeps a raw
/// duration out of every file that describes a moment.
enum MotionRole {
  /// The shortest acknowledgement: a press, a release.
  tap,

  /// A change of state that should read as deliberate.
  state,

  /// Something travelling from one place to another.
  move,

  /// The longest, reserved for a moment worth noticing.
  celebrate,

  /// No motion at all.
  ///
  /// Not "very fast": a moment whose whole expression is a state change
  /// arriving instantly.
  none,
}

/// Which easing a moment uses.
enum CurveRole {
  /// The signature curve: overshoots slightly, like something physical.
  pop,

  /// Decelerating. For a state settling.
  out,

  /// Symmetric. For something travelling across the screen.
  inOut,
}

/// Resolves a role against the motion scale.
extension MotionRoleResolution on SunburstMotion {
  /// The full duration [role] names.
  Duration durationFor(MotionRole role) => switch (role) {
    MotionRole.tap => durTap,
    MotionRole.state => durState,
    MotionRole.move => durMove,
    MotionRole.celebrate => durCelebrate,
    MotionRole.none => Duration.zero,
  };

  /// The curve [role] names.
  Curve curveFor(CurveRole role) => switch (role) {
    CurveRole.pop => easePop,
    CurveRole.out => easeOut,
    CurveRole.inOut => easeInOut,
  };

  /// The duration [role] names, **after** the reduce-motion fold.
  ///
  /// Reduce motion collapses every role to `Duration.zero` — never to
  /// something shorter. Each moment carries a non-motion residue, so the
  /// acknowledgement survives at zero duration.
  Duration resolvedDurationFor(BuildContext context, MotionRole role) =>
      resolve(context, durationFor(role));
}
