import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/source_text.dart';

/// There is one press in this repository.
///
/// Every scan here reads CODE, through E04's shared `withoutDartComments`. The
/// first two hits this gate ever produced were sentences explaining why the
/// machinery is NOT there — PressGeometry's doc saying it holds no
/// `TextDirection` to derive a sign from, and PopSurface's note that a press
/// allocates a controller. Rewording accurate prose to satisfy a substring
/// match makes the comments worse and the gate no stronger. The shared helper
/// is also quote-aware and skips generated files, which the copy this replaced
/// was not and did not.
///
/// Not "one per component that got it right". A second press path is how a
/// catalog ends up with two travel distances, two durations, one surface that
/// forgot the reduce-motion branch and one whose hit area moves out from under
/// the finger — and none of it is visible until someone compares two buttons
/// side by side.
void main() {
  /// The one file allowed to own a press.
  const owner = 'lib/shared/motion/press_physics.dart';

  /// What owning a press looks like in source.
  const machinery = <String>[
    'AnimationController',
    'onPointerDown',
    'onPointerUp',
    'onTapDown',
    'onTapCancel',
  ];

  test('no component drives its own press', () {
    final offenders = <String>[];

    for (final file in dartFilesUnderLib().where(
      (f) => f.path.startsWith('lib/ui'),
    )) {
      final source = withoutDartComments(file.readAsStringSync());

      for (final token in machinery) {
        if (source.contains(token)) {
          offenders.add('${file.path}: $token');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'press machinery belongs in $owner and is reached through '
          'PopSurface, which every component in the catalog is built on',
    );
  });

  test('and neither does a game board', () {
    // lib/games is empty until E09, so this passes vacuously today and is the
    // reason it is written today: the first board must inherit the press
    // rather than reinvent it, and a gate added after the fact is a gate
    // written around the code that broke it.
    final games = Directory('lib/games');
    if (!games.existsSync()) return;

    for (final file in dartFilesUnderLib().where(
      (f) => f.path.startsWith('lib/games'),
    )) {
      final source = withoutDartComments(file.readAsStringSync());

      for (final token in machinery) {
        expect(source, isNot(contains(token)), reason: file.path);
      }
    }
  });

  test('the owner exists and holds exactly one controller', () {
    // One, not "at least one": two controllers in the same file is the same
    // divergence one directory further down.
    final source = withoutDartComments(File(owner).readAsStringSync());

    expect(
      'AnimationController('.allMatches(source),
      hasLength(1),
      reason: 'one press controller, constructed once',
    );
  });

  test('and it never asks which way the page reads', () {
    // A press is MotionAxis.fixed: it travels toward the surface's own hard
    // offset shadow, which is a light-source constant. A TextDirection in this
    // file is the beginning of a mirrored press.
    final source = withoutDartComments(File(owner).readAsStringSync());

    expect(source, isNot(contains('TextDirection')));
    expect(source, isNot(contains('Directionality')));
  });
}
