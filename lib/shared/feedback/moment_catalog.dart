import 'package:mindforge/shared/feedback/haptic_verb.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/feedback/moment_spec.dart';
import 'package:mindforge/shared/feedback/sound_cue.dart';
import 'package:mindforge/shared/motion/motion_axis.dart';
import 'package:mindforge/shared/motion/motion_role.dart';

/// The eighteen moments, as data.
///
/// Transcribed row for row from `sunburst-motion-and-haptics`'
/// `references/moment-catalog.md`, with one **derived column**: `axis`. The
/// reference names what moves; which physical axis it moves along — and
/// therefore whether it mirrors under RTL — is derived here, and every non-`none`
/// entry says which sentence it was derived from.
///
/// A table rather than a switch statement, so the design's invariants are
/// asserted by `moment_catalog_test.dart` instead of by review:
///
/// * every moment survives sound off, haptics off and reduce motion on;
/// * `heavyImpact` is spent exactly once in the whole app;
/// * nothing exceeds the celebrate ceiling;
/// * nothing repeats without a stop condition;
/// * every boundary moment declares a latch.
const Map<Moment, MomentSpec> kMomentCatalog = <Moment, MomentSpec>{
  // Travel down the surface's own hard offset shadow. DERIVED axis: fixed —
  // "travel (off-1), shrink, shadow to (1,1)" is movement along the light
  // source, not along the reading direction.
  Moment.buttonPress: MomentSpec(
    duration: MotionRole.tap,
    curve: CurveRole.pop,
    axis: MotionAxis.fixed,
    residue: <ResidueChannel>{ResidueChannel.shape, ResidueChannel.fill},
    residueNote: 'shadow (1,1) and the deep fill, both at 0ms',
  ),
  // DERIVED axis: fixed — "release back to rest" is the same travel reversed.
  Moment.buttonCommit: MomentSpec(
    duration: MotionRole.tap,
    curve: CurveRole.pop,
    axis: MotionAxis.fixed,
    haptic: HapticVerb.lightImpact,
    sound: SoundCue.pop,
    residue: <ResidueChannel>{ResidueChannel.shape},
    residueNote: 'the rest state, at 0ms',
  ),
  // DERIVED axis: vertical — "card dy 12 to 0" is a vertical offset, and up is
  // up in every language.
  Moment.homeCardEnter: MomentSpec(
    duration: MotionRole.move,
    curve: CurveRole.pop,
    axis: MotionAxis.vertical,
    residue: <ResidueChannel>{ResidueChannel.shape},
    residueNote: 'the cards already in place',
  ),
  // DERIVED axis: fixed — "selected lifts to (-1,-1) with a (2,2) shadow" moves
  // along the light source, away from the page.
  Moment.difficultySelect: MomentSpec(
    duration: MotionRole.state,
    curve: CurveRole.out,
    axis: MotionAxis.fixed,
    haptic: HapticVerb.selectionClick,
    sound: SoundCue.tick,
    residue: <ResidueChannel>{ResidueChannel.shape, ResidueChannel.fill},
    residueNote: 'the lift and the sunshine fill as state, at 0ms',
  ),
  // A scale pop and a dot filling: nothing translates. DERIVED axis: none.
  Moment.countdownBeat: MomentSpec(
    duration: MotionRole.celebrate,
    curve: CurveRole.pop,
    axis: MotionAxis.none,
    haptic: HapticVerb.selectionClick,
    sound: SoundCue.tick,
    residue: <ResidueChannel>{ResidueChannel.word, ResidueChannel.fill},
    residueNote: 'the numeral swaps and the next dot fills',
    latch: 'beatIndex',
  ),
  // A cross-fade. DERIVED axis: none — nothing translates.
  Moment.runStart: MomentSpec(
    duration: MotionRole.move,
    curve: CurveRole.inOut,
    axis: MotionAxis.none,
    haptic: HapticVerb.mediumImpact,
    sound: SoundCue.go,
    residue: <ResidueChannel>{ResidueChannel.fill},
    residueNote: 'the board appears',
  ),
  // DERIVED axis: fixed — "key lifts e2 to e3 and holds" is a step along the
  // light source. The key KEEPS ITS OWN HUE, which is why the residue is shape
  // and word rather than fill.
  Moment.answerCorrect: MomentSpec(
    duration: MotionRole.state,
    curve: CurveRole.out,
    axis: MotionAxis.fixed,
    haptic: HapticVerb.lightImpact,
    sound: SoundCue.pop,
    residue: <ResidueChannel>{ResidueChannel.shape, ResidueChannel.word},
    residueNote: 'the key at e3, the new stimulus and the new score',
  ),
  // DERIVED axis: inline — the shake is horizontal, along the reading axis.
  // Two cycles, bounded. The haptic is deliberately NOT above lightImpact: a
  // heavy knock for a wrong answer punishes rather than informs.
  Moment.answerWrong: MomentSpec(
    duration: MotionRole.celebrate,
    curve: CurveRole.out,
    axis: MotionAxis.inline,
    cycles: 2,
    haptic: HapticVerb.lightImpact,
    sound: SoundCue.thud,
    residue: <ResidueChannel>{ResidueChannel.shape, ResidueChannel.border},
    residueNote: 'the depth drop and the ink strike bar; no shake',
    latch: 'wrongKeyId',
  ),
  // DERIVED axis: fixed — "held at (2,2)" is a sunk position along the light
  // source, permanently.
  Moment.tileFound: MomentSpec(
    duration: MotionRole.state,
    curve: CurveRole.out,
    axis: MotionAxis.fixed,
    haptic: HapticVerb.selectionClick,
    sound: SoundCue.click,
    residue: <ResidueChannel>{ResidueChannel.fill, ResidueChannel.shape},
    residueNote: 'the deep fill, flat and sunk, at 0ms',
  ),
  // A ring and a fill appearing. DERIVED axis: none.
  Moment.tileNextCue: MomentSpec(
    duration: MotionRole.state,
    curve: CurveRole.out,
    axis: MotionAxis.none,
    residue: <ResidueChannel>{ResidueChannel.ring, ResidueChannel.fill},
    residueNote: 'the ring and the fill as state, at 0ms',
  ),
  // A scale bump. DERIVED axis: none.
  Moment.streakMilestone: MomentSpec(
    duration: MotionRole.celebrate,
    curve: CurveRole.pop,
    axis: MotionAxis.none,
    haptic: HapticVerb.mediumImpact,
    sound: SoundCue.chime,
    residue: <ResidueChannel>{ResidueChannel.word},
    residueNote: "the pill's new value",
    latch: 'lastMilestone',
  ),
  // A colour inversion. DERIVED axis: none.
  Moment.timerAlarm: MomentSpec(
    duration: MotionRole.state,
    curve: CurveRole.out,
    axis: MotionAxis.none,
    haptic: HapticVerb.selectionClick,
    sound: SoundCue.alert,
    residue: <ResidueChannel>{ResidueChannel.fill, ResidueChannel.word},
    residueNote: 'the inverted pill and the counting numerals',
    latch: 'hasAlarmed',
  ),
  // Nothing moves at all — the board freezes. DERIVED axis: none.
  Moment.runEnd: MomentSpec(
    duration: MotionRole.none,
    axis: MotionAxis.none,
    haptic: HapticVerb.mediumImpact,
    sound: SoundCue.end,
    residue: <ResidueChannel>{ResidueChannel.shape},
    residueNote: 'the frozen board',
  ),
  // DERIVED axis: vertical — "cards dy 12 to 0", the same rise as home.
  Moment.resultsReveal: MomentSpec(
    duration: MotionRole.move,
    curve: CurveRole.pop,
    axis: MotionAxis.vertical,
    residue: <ResidueChannel>{ResidueChannel.shape},
    residueNote: 'the cards already in place',
  ),
  // A scale bump over a fixed tilt. DERIVED axis: none.
  //
  // The ONE heavyImpact in the whole app. A heavy knock that fires often stops
  // meaning anything, and the catalog test asserts this is the only row.
  Moment.personalBest: MomentSpec(
    duration: MotionRole.celebrate,
    curve: CurveRole.pop,
    axis: MotionAxis.none,
    haptic: HapticVerb.heavyImpact,
    sound: SoundCue.fanfare,
    residue: <ResidueChannel>{ResidueChannel.shape, ResidueChannel.word},
    residueNote: 'the badge present, tilted and static',
    latch: 'hasPlayed',
  ),
  // DERIVED axis: inline — "the knob travels 32px" along the track, which is
  // the reading axis, so it swaps ends under RTL. The printed ON/OFF word
  // swapping side is the same mirror.
  Moment.toggleFlip: MomentSpec(
    duration: MotionRole.move,
    curve: CurveRole.pop,
    axis: MotionAxis.inline,
    haptic: HapticVerb.selectionClick,
    sound: SoundCue.tick,
    residue: <ResidueChannel>{ResidueChannel.fill, ResidueChannel.word},
    residueNote: 'the knob, the track and the word in final position, at 0ms',
  ),
  // DERIVED axis: vertical — "from/to the bottom edge".
  Moment.sheetTransition: MomentSpec(
    duration: MotionRole.move,
    curve: CurveRole.inOut,
    axis: MotionAxis.vertical,
    residue: <ResidueChannel>{ResidueChannel.shape},
    residueNote: 'the sheet present or absent',
  ),
  // DERIVED axis: inline — "a directional slide following Directionality" is
  // the one motion in the catalog whose reference row says outright that it
  // follows the reading direction.
  Moment.routeTransition: MomentSpec(
    duration: MotionRole.move,
    curve: CurveRole.inOut,
    axis: MotionAxis.inline,
    residue: <ResidueChannel>{ResidueChannel.fill},
    residueNote: 'a cross-fade',
  ),
};
