import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/shared/feedback/moment.dart';

/// The eighteen rows of `references/moment-catalog.md`, in its order.
///
/// E05 transcribed the enum; this is the first thing that holds it to the
/// reference table row for row. A nineteenth moment is a design decision, and
/// it should fail here before it reaches an exhaustive switch somewhere else.
const kCatalogRows = <String>[
  'buttonPress',
  'buttonCommit',
  'homeCardEnter',
  'difficultySelect',
  'countdownBeat',
  'runStart',
  'answerCorrect',
  'answerWrong',
  'tileFound',
  'tileNextCue',
  'streakMilestone',
  'timerAlarm',
  'runEnd',
  'resultsReveal',
  'personalBest',
  'toggleFlip',
  'sheetTransition',
  'routeTransition',
];

void main() {
  group('Moment', () {
    test('has exactly eighteen values', () {
      expect(Moment.values, hasLength(18));
    });

    test('and its names match the catalog row for row, in order', () {
      expect(Moment.values.map((moment) => moment.name).toList(), kCatalogRows);
    });
  });
}
