import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/features/play/application/run_ticker.dart';
import 'package:mindforge/theme/sunburst_motion.dart';

/// Every test here runs inside `fakeAsync`, so a sixty-second run costs no wall
/// time. That is the point: a suite that sleeps is a suite nobody runs.
void main() {
  /// Runs [body] with a fake clock the test controls.
  void withFakeClock(
    void Function(FakeAsync async, RunTicker ticker, List<int> ticks) body,
  ) {
    fakeAsync((async) {
      withClock(async.getClock(DateTime.utc(2026)), () {
        final ticks = <int>[];
        final ticker = RunTicker(
          clock: clock,
          onTick: () => ticks.add(ticks.length),
          // The rate the theme carries, read here rather than retyped, so this
          // test moves if the design does.
          pulse: SunburstMotion.sunburstPop.timerPulse,
        );
        addTearDown(ticker.dispose);

        body(async, ticker, ticks);
      });
    });
  }

  group('while running', () {
    test('elapsed advances with the clock', () {
      withFakeClock((async, ticker, ticks) {
        ticker.start();
        async.elapse(const Duration(milliseconds: 2500));

        expect(ticker.elapsed, const Duration(milliseconds: 2500));
      });
    });

    test('and it pulses at 10 Hz', () {
      withFakeClock((async, ticker, ticks) {
        ticker.start();
        async.elapse(const Duration(seconds: 1));

        expect(ticks, hasLength(10));
      });
    });

    test('and elapsed comes from the clock, not from the tick count', () {
      // One jump of a full second delivers one tick, and elapsed is still a
      // full second. A janked frame costs a repaint, never the player's time.
      withFakeClock((async, ticker, ticks) {
        ticker.start();
        async.elapse(const Duration(seconds: 1));

        expect(ticker.elapsed, const Duration(seconds: 1));
        expect(ticks.length, lessThanOrEqualTo(10));
      });
    });
  });

  group('stopping', () {
    test('freezes elapsed', () {
      withFakeClock((async, ticker, ticks) {
        ticker.start();
        async.elapse(const Duration(seconds: 1));
        ticker.stop();

        async.elapse(const Duration(seconds: 5));

        expect(ticker.elapsed, const Duration(seconds: 1));
      });
    });

    test('and stops the pulse', () {
      withFakeClock((async, ticker, ticks) {
        ticker.start();
        async.elapse(const Duration(seconds: 1));
        ticker.stop();
        final atStop = ticks.length;

        async.elapse(const Duration(seconds: 5));

        expect(ticks, hasLength(atStop));
      });
    });

    test('and resuming does not credit the paused interval', () {
      // THE WHOLE REASON THE SHELL OWNS THE CLOCK. A player who pauses for five
      // seconds has played for two, and a game running its own Stopwatch would
      // say seven.
      withFakeClock((async, ticker, ticks) {
        ticker.start();
        async.elapse(const Duration(seconds: 1));
        ticker.stop();

        async.elapse(const Duration(seconds: 5));

        ticker.start();
        async.elapse(const Duration(seconds: 1));

        expect(ticker.elapsed, const Duration(seconds: 2));
      });
    });
  });

  group('dispose', () {
    test('cancels the timer', () {
      withFakeClock((async, ticker, ticks) {
        ticker.start();
        async.elapse(const Duration(milliseconds: 500));
        final atDispose = ticks.length;

        ticker.dispose();
        async.elapse(const Duration(seconds: 5));

        expect(ticks, hasLength(atDispose));
      });
    });
  });

  group('a full run', () {
    test('completes in fake time', () {
      withFakeClock((async, ticker, ticks) {
        ticker.start();
        async.elapse(const Duration(seconds: 60));

        expect(ticker.elapsed, const Duration(seconds: 60));
        expect(ticks, hasLength(600));
      });
    });
  });
}
