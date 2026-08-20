import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/game_id.dart';

/// A game id is a route segment, a database key and a filename fragment.
///
/// All three of those are places localized text is unrepresentable, so the type
/// refuses it at construction rather than discovering it at a join.
void main() {
  group('as a value', () {
    test('two ids with the same token are the same key', () {
      final a = GameId('stroop_rush');
      final b = GameId('stroop_rush');

      expect(a, b);
      expect(a.hashCode, b.hashCode);

      // The property that matters: a registry, a provider family and a
      // snapshot map are all keyed by this.
      final byId = <GameId, int>{a: 1};
      expect(byId[b], 1);
    });

    test('and a different token is a different key', () {
      expect(GameId('stroop_rush'), isNot(GameId('schulte_grid')));
    });

    test('it prints as its token, so a log line is greppable', () {
      expect(GameId('stroop_rush').toString(), 'stroop_rush');
    });
  });

  group('what it refuses', () {
    test('an empty id', () {
      expect(() => GameId(''), throwsAssertionError);
    });

    test('anything but lower snake case', () {
      for (final bad in <String>[
        'StroopRush',
        'stroop-rush',
        'stroop rush',
        'stroop.rush',
        '_stroop',
        'stroop_',
        '1stroop',
      ]) {
        expect(() => GameId(bad), throwsAssertionError, reason: bad);
      }
    });

    test('and anything outside ASCII', () {
      // A localized id is unsearchable, unroutable and invisible in a diff.
      // The Eastern Arabic digit is the one that would otherwise survive a
      // careless snake-case check.
      for (final bad in <String>['بازی', 'run_۱', 'jeu_privé']) {
        expect(() => GameId(bad), throwsAssertionError, reason: bad);
      }
    });
  });

  group('what it accepts', () {
    test('the two ids this project will ship', () {
      expect(GameId('stroop_rush').value, 'stroop_rush');
      expect(GameId('schulte_grid').value, 'schulte_grid');
    });

    test('and a single unsegmented word', () {
      expect(GameId('reaction').value, 'reaction');
    });
  });
}
