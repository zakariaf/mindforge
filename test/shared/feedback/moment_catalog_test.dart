import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/shared/feedback/haptic_verb.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/feedback/moment_catalog.dart';
import 'package:mindforge/shared/feedback/moment_spec.dart';
import 'package:mindforge/shared/feedback/sound_cue.dart';
import 'package:mindforge/shared/motion/motion_axis.dart';
import 'package:mindforge/shared/motion/motion_role.dart';
import 'package:mindforge/theme/sunburst_motion.dart';

/// The design's invariants, asserted rather than reviewed.
///
/// A catalog held as a table instead of a switch statement is what makes this
/// possible: "one heavy impact in the whole app" is a question you can ask a
/// `Map`, and not one you can ask eighteen scattered call sites.
void main() {
  const motion = SunburstMotion.sunburstPop;

  Set<Moment> momentsWhere(bool Function(MomentSpec spec) test) =>
      kMomentCatalog.entries
          .where((entry) => test(entry.value))
          .map((entry) => entry.key)
          .toSet();

  group('coverage', () {
    test('every moment has exactly one row', () {
      expect(kMomentCatalog.keys.toSet(), Moment.values.toSet());
      expect(kMomentCatalog, hasLength(18));
    });
  });

  group('the invariants', () {
    test('every moment survives sound off, haptics off and reduce motion', () {
      // A real configuration, not a corner case. If a moment's only expression
      // is its animation, a player with reduce motion on is told nothing.
      for (final entry in kMomentCatalog.entries) {
        expect(
          entry.value.residue,
          isNotEmpty,
          reason: '${entry.key} has no non-motion residue',
        );
        expect(entry.value.residueNote, isNotEmpty, reason: '${entry.key}');
      }
    });

    test('heavyImpact is spent exactly once, on personalBest', () {
      // A heavy knock that fires often stops meaning anything.
      expect(
        momentsWhere((spec) => spec.haptic == HapticVerb.heavyImpact),
        <Moment>{Moment.personalBest},
      );
    });

    test('answerWrong is never above lightImpact', () {
      // A heavy knock for a wrong answer punishes rather than informs.
      expect(
        kMomentCatalog[Moment.answerWrong]!.haptic,
        HapticVerb.lightImpact,
      );
    });

    test('silence is declared, not omitted', () {
      // Every one of these has a ROW with a null haptic, rather than no row: a
      // missing entry is an oversight and an explicit null is a decision.
      const silent = <Moment>{
        Moment.buttonPress,
        Moment.homeCardEnter,
        Moment.tileNextCue,
        Moment.resultsReveal,
        Moment.sheetTransition,
        Moment.routeTransition,
      };

      for (final moment in silent) {
        expect(kMomentCatalog.containsKey(moment), isTrue, reason: '$moment');
        expect(kMomentCatalog[moment]!.haptic, isNull, reason: '$moment');
      }
    });

    test('nothing exceeds the celebrate ceiling', () {
      for (final entry in kMomentCatalog.entries) {
        expect(
          motion.durationFor(entry.value.duration),
          lessThanOrEqualTo(motion.durCelebrate),
          reason: '${entry.key}',
        );
      }
    });

    test('nothing repeats without a stop condition', () {
      for (final entry in kMomentCatalog.entries) {
        expect(entry.value.cycles, greaterThanOrEqualTo(1));
        expect(
          entry.value.cycles,
          lessThanOrEqualTo(2),
          reason: '${entry.key} repeats more than twice',
        );
      }

      expect(
        momentsWhere((spec) => spec.cycles > 1),
        <Moment>{Moment.answerWrong},
      );
    });

    test('every boundary moment declares a latch, and only those', () {
      // A boundary condition is true on every frame AFTER it happens — the
      // clock is still under five seconds a second later — so something has to
      // remember the moment already fired.
      const expected = <Moment, String>{
        Moment.timerAlarm: 'hasAlarmed',
        Moment.streakMilestone: 'lastMilestone',
        Moment.personalBest: 'hasPlayed',
        Moment.countdownBeat: 'beatIndex',
        Moment.answerWrong: 'wrongKeyId',
      };

      expect(momentsWhere((spec) => spec.latch != null), expected.keys.toSet());

      for (final entry in expected.entries) {
        expect(kMomentCatalog[entry.key]!.latch, entry.value);
      }
    });

    test('there are exactly nine sound slots', () {
      expect(SoundCue.values, hasLength(9));
    });

    test('easePop drives no colour or opacity cross', () {
      // easePop overshoots above 1.0, which is meaningful on a transform and
      // meaningless — or wrong — on a colour.
      const crosses = <Moment>{
        Moment.answerCorrect,
        Moment.difficultySelect,
        Moment.tileFound,
        Moment.tileNextCue,
        Moment.timerAlarm,
        Moment.runStart,
        Moment.sheetTransition,
        Moment.routeTransition,
      };

      for (final moment in crosses) {
        expect(
          kMomentCatalog[moment]!.curve,
          isNot(CurveRole.pop),
          reason: '$moment is a cross-fade and must not overshoot',
        );
      }
    });
  });

  group('the axis partition', () {
    test('exactly three moments move along the reading axis', () {
      expect(momentsWhere((spec) => spec.axis == MotionAxis.inline), <Moment>{
        Moment.answerWrong,
        Moment.toggleFlip,
        Moment.routeTransition,
      });
    });

    test('exactly three move vertically', () {
      expect(momentsWhere((spec) => spec.axis == MotionAxis.vertical), <Moment>{
        Moment.homeCardEnter,
        Moment.resultsReveal,
        Moment.sheetTransition,
      });
    });

    test('the five light-source moments never mirror', () {
      // THE HARD OFFSET SHADOW IS A LIGHT-SOURCE CONSTANT, NOT A
      // READING-DIRECTION PROPERTY. Each of these travels toward or away from
      // its own shadow, so a press in Persian travels down and to the right
      // exactly as it does in English. A build whose buttons pressed up and to
      // the left would be a bug, not a localization.
      final fixed = momentsWhere((spec) => spec.axis == MotionAxis.fixed);

      expect(fixed, <Moment>{
        Moment.buttonPress,
        Moment.buttonCommit,
        Moment.difficultySelect,
        Moment.answerCorrect,
        Moment.tileFound,
      });

      for (final moment in fixed) {
        expect(
          kMomentCatalog[moment]!.axis.mirrorsUnderRtl,
          isFalse,
          reason: '$moment',
        );
      }
    });

    test('and the remaining seven translate nothing', () {
      expect(
        momentsWhere((spec) => spec.axis == MotionAxis.none),
        hasLength(7),
      );
    });
  });

  group('the catalog is locale-independent', () {
    // The import ban itself lives in motion_policy_test, which scans every file
    // under shared/feedback and shared/motion rather than this one. What is
    // left here is the assertion only this file can make.
    test(
      'and every latch is a state-machine key, not a string anyone reads',
      () {
        // A latch that moved with the locale would make a seeded run diverge
        // between languages.
        for (final entry in kMomentCatalog.entries) {
          final latch = entry.value.latch;
          if (latch == null) continue;

          expect(
            RegExp(r'^[a-zA-Z]+$').hasMatch(latch),
            isTrue,
            reason: '${entry.key} latches on "$latch"',
          );
        }
      },
    );
  });
}
