import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/games/false_light/domain/light_difficulty_profile.dart';
import 'package:mindforge/games/false_light/domain/light_field.dart';
import 'package:mindforge/games/false_light/domain/light_field_generator.dart';
import 'package:mindforge/games/false_light/domain/tile_depth.dart';

/// Every field a sweep of [seeds] deals at [difficulty].
Iterable<LightField> sweep(Difficulty difficulty, {int seeds = 200}) sync* {
  for (var seed = 0; seed < seeds; seed++) {
    yield* generateLightFields(seed: seed, difficulty: difficulty);
  }
}

void main() {
  group('determinism', () {
    test('the same seed deals the same run, every time', () {
      final first = generateLightFields(
        seed: 7,
        difficulty: Difficulty.classic,
      );

      for (var i = 0; i < 1000; i++) {
        expect(
          generateLightFields(seed: 7, difficulty: Difficulty.classic),
          first,
        );
      }
    });

    test('and a different seed deals a different one', () {
      expect(
        generateLightFields(seed: 8, difficulty: Difficulty.classic),
        isNot(generateLightFields(seed: 7, difficulty: Difficulty.classic)),
      );
    });

    test('and the difficulty is part of the seed, not just the grid', () {
      // Without the mode salt, blitz would be chill on a bigger board dealt
      // off the same stream -- the same opening pattern of targets, which a
      // returning player notices before any test does.
      final chill = generateLightFields(
        seed: 3,
        difficulty: Difficulty.chill,
      ).first;
      final classic = generateLightFields(
        seed: 3,
        difficulty: Difficulty.classic,
      ).first;

      expect(
        chill.tiles.take(16),
        isNot(classic.tiles.take(16)),
        reason: 'the two runs share an opening pattern',
      );
    });

    test('and the generator version is pinned alongside the feature salt', () {
      // Both are frozen constants. A test that reads them is the tripwire for
      // an edit made without reading what it re-deals.
      expect(kFalseLightFeatureSalt, 0x4C49474854);
      expect(kFalseLightGeneratorVersion, 1);
    });
  });

  group('every field is playable', () {
    test('it holds at least one pressed tile', () {
      // A field with no target can never be completed, and completion is this
      // game's only end condition -- so the run would stall on it forever.
      for (final difficulty in Difficulty.values) {
        for (final field in sweep(difficulty)) {
          expect(field.pressedCount, greaterThanOrEqualTo(1));
        }
      }
    });

    test('and at least one raised tile', () {
      // A field with no distractor is not a game: there is nothing to tell the
      // target apart FROM.
      for (final difficulty in Difficulty.values) {
        for (final field in sweep(difficulty)) {
          expect(field.pressedCount, lessThan(field.tileCount));
          expect(field.tiles, contains(TileDepth.raised));
        }
      }
    });

    test('and its pressed count sits inside the profile share band', () {
      for (final difficulty in Difficulty.values) {
        final profile = profileFor(difficulty);
        final low = profile.tileCount * profile.pressedShareLow;
        final high = profile.tileCount * profile.pressedShareHigh;

        for (final field in sweep(difficulty)) {
          // Rounded to whole tiles at both ends, so the tolerance below is the
          // rounding and nothing else.
          expect(field.pressedCount, greaterThanOrEqualTo(low.round()));
          expect(field.pressedCount, lessThanOrEqualTo(high.round()));
        }
      }
    });

    test('and both ends of that band actually come up', () {
      // A band whose ends never get drawn is a constant with extra steps, and
      // the player would learn the count instead of reading the board.
      for (final difficulty in Difficulty.values) {
        final counts = sweep(difficulty).map((f) => f.pressedCount).toSet();

        expect(
          counts.length,
          greaterThan(1),
          reason: '$difficulty deals exactly $counts targets, every field',
        );
      }
    });
  });

  group('the grid', () {
    test('matches the profile and is fully described by tiles', () {
      for (final difficulty in Difficulty.values) {
        final profile = profileFor(difficulty);

        for (final field in sweep(difficulty, seeds: 50)) {
          expect(field.columns, profile.columns);
          expect(field.rows, profile.rows);
          expect(field.tiles, hasLength(profile.tileCount));
          expect(field.tileCount, profile.tileCount);
        }
      }
    });

    test('and depthAt reads the same row-major list the tiles do', () {
      // The board hit-tests in grid coordinates. An off-by-one here paints a
      // pressed tile in one place and answers for it in another, which is
      // invisible in a screenshot and unplayable in the hand.
      for (final field in sweep(Difficulty.blitz, seeds: 20)) {
        for (var row = 0; row < field.rows; row++) {
          for (var column = 0; column < field.columns; column++) {
            expect(
              field.depthAt(column, row),
              field.tiles[row * field.columns + column],
            );
          }
        }
      }
    });

    test('and every position is pressed somewhere in a sweep', () {
      // A partial Fisher-Yates that walked the wrong way would still deal the
      // right COUNT while never touching the head of the index list, so the
      // top-left corner of the board would be raised in every field ever
      // dealt -- and every property above would still pass.
      for (final difficulty in Difficulty.values) {
        final profile = profileFor(difficulty);
        final everPressed = <int>{};

        for (final field in sweep(difficulty, seeds: 50)) {
          for (var i = 0; i < field.tileCount; i++) {
            if (field.tiles[i] == TileDepth.pressed) everPressed.add(i);
          }
        }

        expect(
          everPressed,
          hasLength(profile.tileCount),
          reason: '$difficulty never presses some position',
        );
      }
    });
  });

  group('the run', () {
    test('holds the profile field count, indexed from zero and in order', () {
      for (final difficulty in Difficulty.values) {
        final profile = profileFor(difficulty);
        final fields = generateLightFields(seed: 11, difficulty: difficulty);

        expect(fields, hasLength(profile.fieldCount));
        expect(
          fields.map((field) => field.index),
          List<int>.generate(profile.fieldCount, (i) => i),
        );
      }
    });

    test('and gets harder by scarcity, not by shrinking the tile', () {
      // The ramp this game is built on, asserted rather than described: the
      // grid grows a little, the pressed SHARE falls a lot.
      final chill = profileFor(Difficulty.chill);
      final classic = profileFor(Difficulty.classic);
      final blitz = profileFor(Difficulty.blitz);

      expect(chill.tileCount, lessThan(classic.tileCount));
      expect(classic.tileCount, lessThan(blitz.tileCount));
      expect(classic.pressedShareHigh, lessThan(chill.pressedShareHigh));
      expect(blitz.pressedShareHigh, lessThan(classic.pressedShareHigh));
      expect(
        blitz.columns,
        lessThanOrEqualTo(5),
        reason:
            'six columns is 36.7pt inside the 280pt board a 320pt device gives, '
            'which is under the 48pt tap floor. It clears the floor at 390 -- '
            'the narrow device is what caps this, not the reference one',
      );
    });

    test('and every profile band is orderable, so the draw cannot spin', () {
      // `nextInt` asserts a positive bound. An inverted band would trip it at
      // runtime rather than here, which is the wrong place to find out.
      for (final difficulty in Difficulty.values) {
        final profile = profileFor(difficulty);

        expect(
          profile.pressedShareHigh,
          greaterThanOrEqualTo(profile.pressedShareLow),
          reason: difficulty.name,
        );
        expect(profile.pressedShareLow, greaterThan(0));
        expect(profile.pressedShareHigh, lessThan(1));
      }
    });
  });

  group('the field carries no text and no colour', () {
    test('its canonical form is ASCII digits and separators, nothing else', () {
      // Depth is the only channel. The moment something renderable lands on
      // this value type, the vectors start moving with the locale.
      for (final field in sweep(Difficulty.classic, seeds: 5)) {
        expect(field.canonical(), matches(RegExp(r'^[0-9:,]+$')));
      }
    });

    test('and a tile depth is one of exactly two payload-free cases', () {
      expect(TileDepth.values, <TileDepth>[
        TileDepth.raised,
        TileDepth.pressed,
      ]);
    });
  });

  group('LightField equality', () {
    test('two identically dealt fields compare equal, and hash equal', () {
      final a = generateLightFields(seed: 5, difficulty: Difficulty.chill);
      final b = generateLightFields(seed: 5, difficulty: Difficulty.chill);

      expect(a.first, b.first);
      expect(a.first.hashCode, b.first.hashCode);
    });

    test('and one flipped tile is a different field', () {
      final field = generateLightFields(
        seed: 5,
        difficulty: Difficulty.chill,
      ).first;
      final flipped = LightField(
        index: field.index,
        columns: field.columns,
        rows: field.rows,
        tiles: <TileDepth>[
          if (field.tiles.first == TileDepth.pressed)
            TileDepth.raised
          else
            TileDepth.pressed,
          ...field.tiles.skip(1),
        ],
      );

      expect(flipped, isNot(field));
    });
  });
}
