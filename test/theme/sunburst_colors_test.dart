import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/sunburst_colors.dart';

import '../support/design_source.dart';
import '../support/harness.dart';

const _colorsFile = 'lib/theme/sunburst_colors.dart';

/// Reads one slot off a palette. Paired with [_setters] below, this is what
/// lets the coverage tests derive their expectations from the source instead of
/// hardcoding a count that silently stops growing.
typedef _Accessor = Color Function(SunburstColors);

/// Replaces one slot on a palette.
typedef _Setter = SunburstColors Function(SunburstColors, Color);

const Map<String, _Accessor> _accessors = <String, _Accessor>{
  'surface': _surface,
  'surfaceSunk': _surfaceSunk,
  'surfaceRaised': _surfaceRaised,
  'surfaceInvert': _surfaceInvert,
  'textPrimary': _textPrimary,
  'textSecondary': _textSecondary,
  'textDisabled': _textDisabled,
  'textInvert': _textInvert,
  'border': _border,
  'borderDisabled': _borderDisabled,
  'divider': _divider,
  'dotPattern': _dotPattern,
  'accent': _accent,
  'accentDeep': _accentDeep,
  'headerRay': _headerRay,
  'headerDots': _headerDots,
  'accentAlt': _accentAlt,
  'success': _success,
  'successDeep': _successDeep,
  'warning': _warning,
  'danger': _danger,
  'focusRing': _focusRing,
  'gameStroop': _gameStroop,
  'gameStroopDeep': _gameStroopDeep,
  'gameSchulte': _gameSchulte,
  'gameSchulteDeep': _gameSchulteDeep,
  'playRed': _playRed,
  'playBlue': _playBlue,
  'playGreen': _playGreen,
  'playYellow': _playYellow,
  'playPurple': _playPurple,
  'playOrange': _playOrange,
  'cbBlue': _cbBlue,
  'cbYellow': _cbYellow,
  'cbOrange': _cbOrange,
  'cbPink': _cbPink,
};

Color _surface(SunburstColors c) => c.surface;
Color _surfaceSunk(SunburstColors c) => c.surfaceSunk;
Color _surfaceRaised(SunburstColors c) => c.surfaceRaised;
Color _surfaceInvert(SunburstColors c) => c.surfaceInvert;
Color _textPrimary(SunburstColors c) => c.textPrimary;
Color _textSecondary(SunburstColors c) => c.textSecondary;
Color _textDisabled(SunburstColors c) => c.textDisabled;
Color _textInvert(SunburstColors c) => c.textInvert;
Color _border(SunburstColors c) => c.border;
Color _borderDisabled(SunburstColors c) => c.borderDisabled;
Color _divider(SunburstColors c) => c.divider;
Color _dotPattern(SunburstColors c) => c.dotPattern;
Color _accent(SunburstColors c) => c.accent;
Color _accentDeep(SunburstColors c) => c.accentDeep;
Color _headerRay(SunburstColors c) => c.headerRay;
Color _headerDots(SunburstColors c) => c.headerDots;
Color _accentAlt(SunburstColors c) => c.accentAlt;
Color _success(SunburstColors c) => c.success;
Color _successDeep(SunburstColors c) => c.successDeep;
Color _warning(SunburstColors c) => c.warning;
Color _danger(SunburstColors c) => c.danger;
Color _focusRing(SunburstColors c) => c.focusRing;
Color _gameStroop(SunburstColors c) => c.gameStroop;
Color _gameStroopDeep(SunburstColors c) => c.gameStroopDeep;
Color _gameSchulte(SunburstColors c) => c.gameSchulte;
Color _gameSchulteDeep(SunburstColors c) => c.gameSchulteDeep;
Color _playRed(SunburstColors c) => c.playRed;
Color _playBlue(SunburstColors c) => c.playBlue;
Color _playGreen(SunburstColors c) => c.playGreen;
Color _playYellow(SunburstColors c) => c.playYellow;
Color _playPurple(SunburstColors c) => c.playPurple;
Color _playOrange(SunburstColors c) => c.playOrange;
Color _cbBlue(SunburstColors c) => c.cbBlue;
Color _cbYellow(SunburstColors c) => c.cbYellow;
Color _cbOrange(SunburstColors c) => c.cbOrange;
Color _cbPink(SunburstColors c) => c.cbPink;

final Map<String, _Setter> _setters = <String, _Setter>{
  'surface': (c, v) => c.copyWith(surface: v),
  'surfaceSunk': (c, v) => c.copyWith(surfaceSunk: v),
  'surfaceRaised': (c, v) => c.copyWith(surfaceRaised: v),
  'surfaceInvert': (c, v) => c.copyWith(surfaceInvert: v),
  'textPrimary': (c, v) => c.copyWith(textPrimary: v),
  'textSecondary': (c, v) => c.copyWith(textSecondary: v),
  'textDisabled': (c, v) => c.copyWith(textDisabled: v),
  'textInvert': (c, v) => c.copyWith(textInvert: v),
  'border': (c, v) => c.copyWith(border: v),
  'borderDisabled': (c, v) => c.copyWith(borderDisabled: v),
  'divider': (c, v) => c.copyWith(divider: v),
  'dotPattern': (c, v) => c.copyWith(dotPattern: v),
  'accent': (c, v) => c.copyWith(accent: v),
  'accentDeep': (c, v) => c.copyWith(accentDeep: v),
  'headerRay': (c, v) => c.copyWith(headerRay: v),
  'headerDots': (c, v) => c.copyWith(headerDots: v),
  'accentAlt': (c, v) => c.copyWith(accentAlt: v),
  'success': (c, v) => c.copyWith(success: v),
  'successDeep': (c, v) => c.copyWith(successDeep: v),
  'warning': (c, v) => c.copyWith(warning: v),
  'danger': (c, v) => c.copyWith(danger: v),
  'focusRing': (c, v) => c.copyWith(focusRing: v),
  'gameStroop': (c, v) => c.copyWith(gameStroop: v),
  'gameStroopDeep': (c, v) => c.copyWith(gameStroopDeep: v),
  'gameSchulte': (c, v) => c.copyWith(gameSchulte: v),
  'gameSchulteDeep': (c, v) => c.copyWith(gameSchulteDeep: v),
  'playRed': (c, v) => c.copyWith(playRed: v),
  'playBlue': (c, v) => c.copyWith(playBlue: v),
  'playGreen': (c, v) => c.copyWith(playGreen: v),
  'playYellow': (c, v) => c.copyWith(playYellow: v),
  'playPurple': (c, v) => c.copyWith(playPurple: v),
  'playOrange': (c, v) => c.copyWith(playOrange: v),
  'cbBlue': (c, v) => c.copyWith(cbBlue: v),
  'cbYellow': (c, v) => c.copyWith(cbYellow: v),
  'cbOrange': (c, v) => c.copyWith(cbOrange: v),
  'cbPink': (c, v) => c.copyWith(cbPink: v),
};

void main() {
  const palette = SunburstColors.sunburstPop;
  final declaredFields = DesignSource.dartFieldNames(
    _colorsFile,
    'SunburstColors',
  );

  group('slot bindings', () {
    test('every slot resolves to the primitive the palette table names', () {
      final bindings = DesignSource.dartSlotBindings();
      final hexes = DesignSource.dartPrimitiveHexes();

      expect(bindings, hasLength(declaredFields.length));

      bindings.forEach((slot, primitive) {
        final expected = hexes[primitive];
        expect(expected, isNotNull, reason: '_P.$primitive does not exist');
        expect(
          // The full ARGB, alpha included. The comparison used to drop the
          // alpha byte, so a slot bound to a half-transparent primitive would
          // have matched its opaque twin.
          _accessors[slot]!(
            palette,
          ).toARGB32().toRadixString(16).padLeft(8, '0'),
          expected!.toLowerCase(),
          reason: '$slot should be _P.$primitive',
        );
      });
    });
  });

  group('the extension contract', () {
    testWidgets('of(context) returns the attached extension', (tester) async {
      late SunburstColors resolved;

      await tester.pumpApp(
        Builder(
          builder: (context) {
            resolved = SunburstColors.of(context);
            return const SizedBox.shrink();
          },
        ),
        theme: ThemeData(extensions: const <SunburstColors>[palette]),
      );

      expect(identical(resolved, palette), isTrue);
    });

    testWidgets('of(context) asserts when the extension is missing', (
      tester,
    ) async {
      Object? error;

      await tester.pumpApp(
        Builder(
          builder: (context) {
            try {
              SunburstColors.of(context);
            } on Object catch (caught) {
              error = caught;
            }
            return const SizedBox.shrink();
          },
        ),
        theme: ThemeData(),
      );

      expect(
        error,
        isA<AssertionError>(),
        reason:
            'there is no ?? fallback. A fallback palette is one no golden '
            'has ever rendered',
      );
    });

    testWidgets('the palette is identical under every locale', (tester) async {
      // Colour is not a localized property. This exists so nobody ever adds a
      // per-locale palette branch, and so E04's RTL screenshots stay diffable
      // against the LTR ones on hue.
      for (final tag in <String>['en', 'de', 'fa', 'ckb']) {
        late SunburstColors resolved;

        await tester.pumpApp(
          Builder(
            builder: (context) {
              resolved = SunburstColors.of(context);
              return const SizedBox.shrink();
            },
          ),
          theme: ThemeData(extensions: const <SunburstColors>[palette]),
          locale: Locale(tag),
        );
        if (tag != 'en') tester.takeException();

        expect(resolved, palette, reason: 'the palette moved under $tag');
      }
    });
  });

  group('coverage of every declared field', () {
    const sentinel = Color(0xFF010203);

    test('the accessor and setter tables cover the declared fields', () {
      // Derived from the SOURCE, never a literal count: a hardcoded number is
      // how a new slot gets forgotten in copyWith while the test still passes.
      expect(_accessors.keys.toSet(), declaredFields.toSet());
      expect(_setters.keys.toSet(), declaredFields.toSet());
    });

    test('copyWith lands on exactly one field', () {
      for (final field in declaredFields) {
        final changed = _setters[field]!(palette, sentinel);

        expect(_accessors[field]!(changed), sentinel, reason: field);
        for (final other in declaredFields.where((f) => f != field)) {
          expect(
            _accessors[other]!(changed),
            _accessors[other]!(palette),
            reason: 'copyWith($field:) also moved $other',
          );
        }
      }
    });

    test('lerp moves every field', () {
      var other = palette;
      for (var i = 0; i < declaredFields.length; i++) {
        other = _setters[declaredFields[i]]!(other, Color(0xFF000000 + i + 1));
      }

      final halfway = palette.lerp(other, 0.5);

      for (final field in declaredFields) {
        expect(
          _accessors[field]!(halfway),
          isNot(_accessors[field]!(palette)),
          reason: '$field is missing from lerp, so it returned its own value',
        );
      }

      expect(palette.lerp(other, 0), palette);
      expect(palette.lerp(other, 1), other);
      expect(palette.lerp(null, 0.5), palette);
    });

    test('equality covers every declared field', () {
      for (final field in declaredFields) {
        final changed = _setters[field]!(palette, sentinel);

        expect(
          changed,
          isNot(palette),
          reason: '$field is missing from _props',
        );
        expect(changed.hashCode, isNot(palette.hashCode), reason: field);
      }
    });
  });

  group('the answer palette', () {
    test('maps each answer to its default hue', () {
      expect(palette.answerColour(PlayAnswer.red), palette.playRed);
      expect(palette.answerColour(PlayAnswer.blue), palette.playBlue);
      expect(palette.answerColour(PlayAnswer.green), palette.playGreen);
      expect(palette.answerColour(PlayAnswer.yellow), palette.playYellow);
      expect(palette.answerColour(PlayAnswer.purple), palette.playPurple);
      expect(palette.answerColour(PlayAnswer.orange), palette.playOrange);
    });

    test(
      'the colour-blind swap re-points exactly red, green, blue and yellow',
      () {
        Color cb(PlayAnswer a) => palette.answerColour(a, colourBlind: true);

        expect(cb(PlayAnswer.red), palette.cbPink);
        expect(cb(PlayAnswer.green), palette.cbOrange);
        expect(cb(PlayAnswer.blue), palette.cbBlue);
        expect(cb(PlayAnswer.yellow), palette.cbYellow);

        expect(cb(PlayAnswer.purple), palette.answerColour(PlayAnswer.purple));
        expect(cb(PlayAnswer.orange), palette.answerColour(PlayAnswer.orange));
      },
    );

    test('answerLabel is ink on yellow and paper everywhere else', () {
      for (final answer in PlayAnswer.values) {
        expect(
          palette.answerLabel(answer),
          answer == PlayAnswer.yellow
              ? palette.textPrimary
              : palette.surfaceRaised,
          reason: '$answer',
        );
      }
    });

    test('each answer is permanently bound to a fill', () {
      expect(PlayAnswer.red.fill, PlayFill.stripe);
      expect(PlayAnswer.blue.fill, PlayFill.solid);
      expect(PlayAnswer.green.fill, PlayFill.dot);
      expect(PlayAnswer.yellow.fill, PlayFill.ring);
      expect(PlayAnswer.purple.fill, PlayFill.solid);
      expect(PlayAnswer.orange.fill, PlayFill.stripe);
    });

    test('PlayAnswer carries no display string', () {
      expect(
        DesignSource.dartFieldNames(_colorsFile, 'PlayAnswer'),
        <String>['fill'],
        reason:
            'the colour WORD is an ARB key resolved in E04 and rendered by '
            'E09. A String here would hardcode English into the theme layer '
            'and make the Stroop stimulus untranslatable',
      );
    });
  });

  group('the tier tripwire', () {
    test('chrome slots are wired to primitives, not to gameplay slots', () {
      // A grep gate cannot see tier; this can. The colour-blind palette
      // re-points cbBlue/cbYellow/cbOrange/cbPink, so a chrome slot sharing a
      // primitive with one of those would move when a player flips the setting.
      final bindings = DesignSource.dartSlotBindings();

      expect(
        bindings['danger'],
        'playRed',
        reason: 'the PRIMITIVE, not the playRed slot',
      );
      expect(bindings['accentAlt'], 'grape');

      const colourBlindSlots = <String>{
        'cbBlue',
        'cbYellow',
        'cbOrange',
        'cbPink',
      };
      final swappable = colourBlindSlots
          .map((slot) => bindings[slot])
          .whereType<String>()
          .toSet();

      const chromeSlots = <String>{
        'surface',
        'surfaceSunk',
        'surfaceRaised',
        'surfaceInvert',
        'textPrimary',
        'textSecondary',
        'textDisabled',
        'textInvert',
        'border',
        'borderDisabled',
        'divider',
        'dotPattern',
        'accent',
        'accentDeep',
        'accentAlt',
        'success',
        'successDeep',
        'warning',
        'focusRing',
        'gameStroop',
        'gameStroopDeep',
        'gameSchulte',
        'gameSchulteDeep',
      };

      for (final slot in chromeSlots) {
        expect(
          swappable.contains(bindings[slot]),
          isFalse,
          reason:
              '$slot binds to ${bindings[slot]}, which the colour-blind '
              'palette also uses — so flipping that setting would move chrome',
        );
      }
    });
  });
}
