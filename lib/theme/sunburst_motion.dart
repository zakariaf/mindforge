import 'package:flutter/material.dart';

/// Four durations and three curves. Nothing in Sunburst Pop runs past 240ms.
/// `sunburst-motion-and-haptics` owns which moment spends which token; this
/// class owns the numbers.
@immutable
class SunburstMotion extends ThemeExtension<SunburstMotion> {
  /// Creates a motion scale.
  const SunburstMotion({
    required this.durTap,
    required this.durState,
    required this.durMove,
    required this.durCelebrate,
    required this.easePop,
    required this.easeOut,
    required this.easeInOut,
    required this.timerPulse,
    required this.alarmThreshold,
    required this.countdownInterval,
  });

  /// Press down / release.
  final Duration durTap;

  /// Toggles, selection, HUD value swaps — every colour transition.
  final Duration durState;

  /// Sheets and page transitions.
  final Duration durMove;

  /// Personal-best badge, streak bump. The ceiling: nothing may exceed it.
  final Duration durCelebrate;

  /// Overshooting spring. Legal on transform and scale ONLY — it returns values
  /// above 1.0, and a colour or opacity tween driven past its endpoint is not a
  /// meaningful value.
  final Curve easePop;

  /// Decelerating. The default for anything entering or settling.
  final Curve easeOut;

  /// Accelerate then decelerate. For something that both leaves and arrives.
  final Curve easeInOut;

  /// How often a running run timer repaints.
  ///
  /// 10 Hz, from `sunburst-motion-and-haptics` rule 6: fast enough that a
  /// tenths display never visibly stutters, slow enough that the timer is not a
  /// per-frame rebuild of the whole play band. `RunTicker` is handed this
  /// rather than declaring it, so the engine takes its timing instead of
  /// knowing it.
  ///
  /// **Not collapsed by reduce motion.** It is a sampling rate, not an
  /// animation, and collapsing it would stop the clock.
  final Duration timerPulse;

  /// How much time left counts as "running out".
  ///
  /// The `timerAlarm` moment's boundary. `RunState.isTimerAlarmAt` takes it as
  /// an argument, because that type is Flutter-free and may not reach here.
  final Duration alarmThreshold;

  /// How long each 3-2-1 beat is held.
  ///
  /// One second, which is what a countdown means. It is here for the same
  /// reason `timerPulse` is: every `Duration` literal in the app lives in this
  /// file, three gates enforce that, and the countdown screen takes its cadence
  /// rather than knowing it.
  ///
  /// **Not collapsed by reduce motion.** The beat is the countdown, not an
  /// animation of one — collapsing it would start the run instantly.
  final Duration countdownInterval;

  /// The single place a widget asks "should I animate?".
  ///
  /// Reduced motion means **stop**, not "gentler": [full] collapses to
  /// `Duration.zero`, never to something shorter. Every moment in the catalog
  /// carries a non-motion residue — the pressed colour and shadow still apply
  /// instantly — so the acknowledgement survives with zero duration.
  ///
  /// It reads the flag from `MediaQuery`, not from app state, because that is
  /// where the OS accessibility setting lives.
  Duration resolve(BuildContext context, Duration full) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : full;

  /// The motion scale attached to [context]'s theme.
  static SunburstMotion of(BuildContext context) {
    final extension = Theme.of(context).extension<SunburstMotion>();
    assert(
      extension != null,
      'SunburstMotion is missing from the theme. Build it with '
      'buildSunburstTheme().',
    );
    return extension!;
  }

  List<Object?> get _props => <Object?>[
    durTap,
    durState,
    durMove,
    durCelebrate,
    easePop,
    easeOut,
    easeInOut,
    timerPulse,
    alarmThreshold,
    countdownInterval,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SunburstMotion &&
          runtimeType == other.runtimeType &&
          _sameProps(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);

  static bool _sameProps(List<Object?> a, List<Object?> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  SunburstMotion copyWith({
    Duration? durTap,
    Duration? durState,
    Duration? durMove,
    Duration? durCelebrate,
    Curve? easePop,
    Curve? easeOut,
    Curve? easeInOut,
    Duration? timerPulse,
    Duration? alarmThreshold,
    Duration? countdownInterval,
  }) => SunburstMotion(
    durTap: durTap ?? this.durTap,
    durState: durState ?? this.durState,
    durMove: durMove ?? this.durMove,
    durCelebrate: durCelebrate ?? this.durCelebrate,
    easePop: easePop ?? this.easePop,
    easeOut: easeOut ?? this.easeOut,
    easeInOut: easeInOut ?? this.easeInOut,
    timerPulse: timerPulse ?? this.timerPulse,
    alarmThreshold: alarmThreshold ?? this.alarmThreshold,
    countdownInterval: countdownInterval ?? this.countdownInterval,
  );

  /// Deliberate step, not an unfinished implementation. Durations and curves
  /// are not meaningfully interpolable mid-transition, and MindForge has exactly
  /// one theme, so this snaps at the midpoint and lands on the correct endpoint
  /// at both ends. Do not "fix" this into a per-field interpolation.
  @override
  SunburstMotion lerp(covariant SunburstMotion? other, double t) =>
      t < 0.5 ? this : (other ?? this);

  /// The one motion scale, transcribed from `system.html`.
  static const SunburstMotion sunburstPop = SunburstMotion(
    durTap: Duration(milliseconds: 120),
    durState: Duration(milliseconds: 160),
    durMove: Duration(milliseconds: 180),
    durCelebrate: Duration(milliseconds: 240),
    easePop: Cubic(0.2, 1.5, 0.4, 1),
    easeOut: Cubic(0.2, 0.8, 0.2, 1),
    easeInOut: Cubic(0.6, 0, 0.3, 1),
    timerPulse: Duration(milliseconds: 100),
    alarmThreshold: Duration(seconds: 5),
    countdownInterval: Duration(seconds: 1),
  );
}
