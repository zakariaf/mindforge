import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/failure.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_failure.dart';

import '../policy/support/source_text.dart';

/// The run's own failure family, and the rule that keeps it translatable.
///
/// E08 renders a failure by switching on the sealed variant and reading an ARB
/// key. A `message` field would make that switch unnecessary and the message
/// untranslatable in the same stroke, so the tests below are mostly about what
/// a `RunFailure` is not allowed to hold.
void main() {
  /// Every variant, written out.
  ///
  /// A const list rather than reflection: `dart:mirrors` does not exist on this
  /// target, and a hand-written list that someone forgets to extend is caught
  /// by the exhaustiveness test below.
  final failures = <RunFailure>[
    UnknownGame(GameId('nback')),
    UnsupportedDifficulty(GameId('schulte_grid'), Difficulty.blitz),
  ];

  group('every variant', () {
    test('is a Failure, so it flows through the one Result spine', () {
      // Not a second error hierarchy. E02 owns Result and Failure; this family
      // extends them and adds no parallel vocabulary.
      for (final failure in failures) {
        expect(failure, isA<Failure>());
      }
    });

    test('exposes a stable, namespaced code', () {
      for (final failure in failures) {
        expect(
          RegExp(r'^[a-z]+\.[a-z_]+$').hasMatch(failure.code),
          isTrue,
          reason: '${failure.runtimeType} -> ${failure.code}',
        );
        expect(failure.code, startsWith('run.'));
      }
    });

    test('and its code is pure ASCII', () {
      // A code is compared, logged, and eventually mapped to an ARB entry. An
      // Eastern Arabic digit or an RTL mark in one is unmatchable and invisible
      // in a diff.
      for (final failure in failures) {
        for (final rune in failure.code.runes) {
          expect(rune, lessThan(0x80), reason: failure.code);
        }
      }
    });

    test('is value-equal, so two reports of one problem are one problem', () {
      expect(UnknownGame(GameId('nback')), UnknownGame(GameId('nback')));
      expect(
        UnsupportedDifficulty(GameId('schulte_grid'), Difficulty.blitz),
        UnsupportedDifficulty(GameId('schulte_grid'), Difficulty.blitz),
      );
      expect(
        UnknownGame(GameId('nback')),
        isNot(UnknownGame(GameId('reaction'))),
      );
    });
  });

  group('what a failure may never carry', () {
    final source = withoutDartComments(
      File('lib/core/run_failure.dart').readAsStringSync(),
    );

    test('no prose field, so the message stays in the ARB', () {
      for (final banned in <String>[
        'message',
        'label',
        'title',
        'description',
      ]) {
        expect(
          source,
          isNot(contains(banned)),
          reason:
              'E08 switches on the variant and reads an ARB key. A sentence '
              'here is a sentence four locales cannot change',
        );
      }
    });

    test('and no string field holds anything but an identifier', () {
      // Ids and codes pass; prose does not.
      for (final failure in failures) {
        for (final value in failure.identifiers) {
          expect(
            RegExp(r'^[a-zA-Z0-9_.:-]*$').hasMatch(value),
            isTrue,
            reason: '${failure.runtimeType} carries "$value"',
          );
        }
      }
    });

    test('and no bidi isolate character reaches one', () {
      // i18n-rtl-l10n rule 8: isolate marks are a view-layer wrapper. A failure
      // code is compared, logged and exported, and all three break on one.
      for (final failure in failures) {
        for (final value in <String>[failure.code, ...failure.identifiers]) {
          for (final rune in value.runes) {
            expect(
              rune >= 0x2066 && rune <= 0x2069,
              isFalse,
              reason:
                  '${failure.runtimeType} carries U+${rune.toRadixString(16)}',
            );
          }
        }
      }
    });
  });

  group('the family is sealed', () {
    test('so E08 can switch it exhaustively with no wildcard', () {
      // The value of this test is that adding a variant breaks the build here,
      // which is the same moment it would break the screen that renders it.
      for (final failure in failures) {
        final key = switch (failure) {
          UnknownGame() => 'errorUnknownGame',
          UnsupportedDifficulty() => 'errorUnsupportedDifficulty',
        };

        expect(key, startsWith('error'));
      }
    });
  });

  group('persistence failures are NOT mirrored here', () {
    test('the family names only what the repository does not own', () {
      // A run that failed to save is a DataFailure, surfaced through
      // RunState.saveFailure. Mirroring it would give the results screen two
      // ways to say "the save did not land", which is one way too many.
      final source = File('lib/core/run_failure.dart').readAsStringSync();

      for (final banned in <String>[
        'StoreUnavailable',
        'ConstraintViolated',
        'RunAlreadyRecorded',
        'NotFound',
        'CorruptRow',
      ]) {
        expect(source, isNot(contains(banned)), reason: banned);
      }
    });
  });
}
