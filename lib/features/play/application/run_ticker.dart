import 'dart:async';

import 'package:clock/clock.dart';

/// The engine's one clock.
///
/// **The tick is a repaint cue; the clock is the measurement.** Elapsed time is
/// computed from `clock.now()` on every pulse rather than accumulated by
/// counting ticks, so a janked frame or a backgrounded app loses none of it — a
/// dropped tick costs one repaint, not one tenth of a second off the player's
/// run.
///
/// 10 Hz, which is `sunburst-motion-and-haptics` rule 6's stated run-timer rate:
/// fast enough that a tenths display never visibly stutters, slow enough that
/// the timer is not a per-frame rebuild of the whole play band.
///
/// **One ticker, owned by the shell.** Without it every game grows a
/// `Stopwatch`, and pause stops none of them.
final class RunTicker {
  /// Creates a ticker that calls [onTick] while running.
  RunTicker({required this.clock, required this.onTick});

  /// Where "now" comes from. Injected, so a test drives it with fake time and
  /// a sixty-second run takes no wall time at all.
  final Clock clock;

  /// Called on every pulse while running.
  final void Function() onTick;

  /// The rate a running timer repaints at.
  static const Duration pulse = Duration(milliseconds: 100);

  Timer? _timer;
  DateTime? _segmentStart;
  Duration _banked = Duration.zero;

  /// Whether the ticker is currently advancing.
  bool get isRunning => _segmentStart != null;

  /// How long the run has been live, excluding every paused interval.
  Duration get elapsed {
    final start = _segmentStart;
    if (start == null) return _banked;

    return _banked + clock.now().difference(start);
  }

  /// Starts, or resumes after a [stop].
  ///
  /// Resuming opens a NEW segment rather than extending the old one, which is
  /// why a paused interval is never credited: the time between `stop` and
  /// `start` belongs to no segment at all.
  void start() {
    if (isRunning) return;

    _segmentStart = clock.now();
    _timer = Timer.periodic(pulse, (_) => onTick());
  }

  /// Freezes [elapsed] and stops the pulse.
  void stop() {
    final start = _segmentStart;
    if (start == null) return;

    _banked += clock.now().difference(start);
    _segmentStart = null;
    _timer?.cancel();
    _timer = null;
  }

  /// Stops and releases the timer.
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _segmentStart = null;
  }
}
