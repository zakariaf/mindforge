import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/hud_tone.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/run_outcome.dart';

void main() {
  const slot = HudSlot(
    labelKey: 'hudScore',
    canonicalValue: 1480,
    format: StatFormat.points,
  );
  const hud = GameHud(leading: slot, middle: slot);

  group('a snapshot', () {
    test('with no outcome is a live run', () {
      // The shell reads a null outcome as "keep going". A board never ends its
      // own run; it reports and the shell decides.
      expect(const BoardSnapshot(hud: hud).outcome, isNull);
    });

    test('accepts a progress ratio inside 0..1, or none at all', () {
      for (final progress in <double?>[null, 0, 0.5, 1]) {
        expect(
          BoardSnapshot(hud: hud, progress: progress).progress,
          progress,
        );
      }
    });

    test('and rejects one outside it', () {
      // A count belongs in a HUD slot. A ratio that can exceed one is a ratio
      // of something else.
      for (final progress in <double>[-0.1, 1.1]) {
        expect(
          () => BoardSnapshot(hud: hud, progress: progress),
          throwsAssertionError,
          reason: '$progress',
        );
      }
    });

    test('is value-equal, because Riverpod diffs by value', () {
      expect(const BoardSnapshot(hud: hud), const BoardSnapshot(hud: hud));
      expect(
        const BoardSnapshot(hud: hud, progress: 0.5),
        isNot(const BoardSnapshot(hud: hud)),
      );
      expect(
        const BoardSnapshot(hud: hud, outcome: RunOutcome.abandoned()),
        isNot(const BoardSnapshot(hud: hud)),
      );
    });
  });

  group('GameHud', () {
    test('holds exactly three slots, and a fourth is unrepresentable', () {
      // Named fields rather than a list. The play band is a three-column strip;
      // a list would let a game push a fourth and discover the overflow on a
      // 320pt phone in German.
      expect(const GameHud(leading: slot, middle: slot).slots, hasLength(2));
      expect(
        const GameHud(leading: slot, middle: slot, trailing: slot).slots,
        hasLength(3),
      );
    });

    test('and the trailing slot is optional, because Schulte has two', () {
      expect(const GameHud(leading: slot, middle: slot).trailing, isNull);
    });
  });

  group('HudSlot', () {
    test('defaults to the neutral tone, so a game never sets alarm', () {
      // Whether time is running out is the SHELL's judgement, made against the
      // run limit the shell owns. A board reaching for alarm is a board that
      // has opinions about the clock.
      expect(slot.tone, HudTone.neutral);
    });

    test('carries a label key and a canonical integer, never a string', () {
      expect(
        RegExp(r'^[a-z][a-zA-Z0-9_]*$').hasMatch(slot.labelKey),
        isTrue,
        reason: slot.labelKey,
      );
      expect(slot.canonicalValue, isA<int>());
    });

    test('and is value-equal', () {
      expect(
        slot,
        const HudSlot(
          labelKey: 'hudScore',
          canonicalValue: 1480,
          format: StatFormat.points,
        ),
      );
      expect(
        slot,
        isNot(
          const HudSlot(
            labelKey: 'hudScore',
            canonicalValue: 1480,
            format: StatFormat.points,
            tone: HudTone.alarm,
          ),
        ),
      );
    });
  });
}
