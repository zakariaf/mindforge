import 'package:flutter/foundation.dart';
import 'package:mindforge/shared/feedback/haptic_verb.dart';
import 'package:mindforge/shared/feedback/sound_cue.dart';
import 'package:mindforge/shared/motion/motion_axis.dart';
import 'package:mindforge/shared/motion/motion_role.dart';

/// Which channel a moment's **non-motion residue** uses.
///
/// The residue is what is left when a player has sound off, haptics off and
/// reduce motion on — which is a real configuration, not a corner case. Every
/// moment must still say what happened through at least one of these.
enum ResidueChannel {
  /// A colour change.
  fill,

  /// A change of depth or elevation.
  shape,

  /// A ring or halo appearing.
  ring,

  /// An edge changing weight or colour.
  border,

  /// A printed word or number changing.
  word,
}

/// Everything one moment does, as data.
///
/// The catalog is a table rather than a switch statement so the design's
/// invariants — one heavy impact in the whole app, nothing above the celebrate
/// ceiling, every moment survivable in silence — are asserted by tests instead
/// of by review.
@immutable
final class MomentSpec {
  /// Describes one moment.
  const MomentSpec({
    required this.duration,
    required this.axis,
    required this.residue,
    required this.residueNote,
    this.curve,
    this.cycles = 1,
    this.haptic,
    this.sound,
    this.latch,
  }) : assert(cycles >= 1, 'a moment happens at least once');

  // There is deliberately NO `assert(residue.isNotEmpty)` here. Dart's const
  // evaluator cannot read a property off a collection, so the assert would not
  // compile in a const constructor — and a const catalog is what makes the
  // table a compile-time artefact rather than something built at startup. The
  // invariant is asserted over every row in moment_catalog_test.dart instead.

  /// How long it takes, by role.
  final MotionRole duration;

  /// How it eases, if it moves at all.
  final CurveRole? curve;

  /// Which physical axis it travels along, and therefore whether it mirrors.
  ///
  /// **A derived column.** The reference table does not carry an axis; each
  /// entry's comment names the sentence of the "what moves" column it was
  /// derived from.
  final MotionAxis axis;

  /// How many times it repeats. Never unbounded.
  final int cycles;

  /// What the device does, if anything.
  final HapticVerb? haptic;

  /// What the app plays, if anything.
  final SoundCue? sound;

  /// Which channels carry the moment when everything else is off.
  final Set<ResidueChannel> residue;

  /// A developer note describing that residue.
  ///
  /// **Not a UI string.** It carries no ARB key and is never rendered; a policy
  /// test asserts it never reaches a `Text`.
  final String residueNote;

  /// The state key that stops this moment firing twice for one event.
  ///
  /// A boundary moment — the clock crossing five seconds, a streak crossing a
  /// multiple of five — is true on every frame after it happens, so something
  /// has to remember it already fired. The name is a state-machine key and
  /// never a user-facing string, which is why it is asserted to be plain
  /// letters: a latch that moved with the locale would make a seeded run
  /// diverge between languages.
  final String? latch;
}
