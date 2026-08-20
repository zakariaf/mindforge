import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/features/play/domain/run_phase.dart';

void main() {
  /// The seven legal edges, written out in the test rather than derived.
  ///
  /// Derived from the implementation it would be a tautology. Written out, it
  /// is a second statement of the machine that has to agree with the first.
  const legal = <(RunPhase, RunPhase)>{
    (RunPhase.idle, RunPhase.countdown),
    (RunPhase.countdown, RunPhase.playing),
    (RunPhase.countdown, RunPhase.idle),
    (RunPhase.playing, RunPhase.paused),
    (RunPhase.playing, RunPhase.over),
    (RunPhase.paused, RunPhase.countdown),
    (RunPhase.paused, RunPhase.over),
  };

  group('the transition table', () {
    test('answers all twenty-five cells, and only seven are legal', () {
      var checked = 0;

      for (final from in RunPhase.values) {
        for (final to in RunPhase.values) {
          checked++;

          expect(
            from.canTransitionTo(to),
            legal.contains((from, to)),
            reason: '${from.name} -> ${to.name}',
          );
        }
      }

      expect(checked, 25);
      expect(legal, hasLength(7));
    });

    test('over is terminal', () {
      for (final to in RunPhase.values) {
        expect(
          RunPhase.over.canTransitionTo(to),
          isFalse,
          reason: 'over -> ${to.name}',
        );
      }
    });

    test('and no phase transitions to itself', () {
      // A self-transition is either a no-op dressed as a state change, which
      // wakes every listener for nothing, or a restart wearing the wrong name.
      for (final phase in RunPhase.values) {
        expect(phase.canTransitionTo(phase), isFalse, reason: phase.name);
      }
    });
  });

  group('the edges that matter to the shell', () {
    test('a run can back out of its own countdown', () {
      // The player who taps back during 3-2-1 has not started a run, so no row
      // is written and no streak is touched.
      expect(RunPhase.countdown.canTransitionTo(RunPhase.idle), isTrue);
    });

    test('and resuming from pause goes through a countdown, never straight to '
        'playing', () {
      // Dropping a player back into a live board with their finger still on
      // the pause button is how a Blitz run is lost to the UI.
      expect(RunPhase.paused.canTransitionTo(RunPhase.countdown), isTrue);
      expect(RunPhase.paused.canTransitionTo(RunPhase.playing), isFalse);
    });

    test('and a paused run can be abandoned without resuming', () {
      expect(RunPhase.paused.canTransitionTo(RunPhase.over), isTrue);
    });
  });
}
