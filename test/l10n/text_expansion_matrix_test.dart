import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/theme/sunburst_type.dart';

import '../support/harness.dart';
import '../support/l10n_strings.dart';
import '../support/load_app_fonts.dart';
import '../support/locale_cases.dart';
import '../support/pseudo_locale.dart';

/// The locale x text-scale x width matrix: 4 x 3 x 4 = 48 cases, plus a
/// pseudo-locale lane at the same four widths.
///
/// **One `testWidgets` per tuple, never one loop inside one test.** Each case
/// reports every string that does not fit, and a single test spanning tuples
/// would stop at the first one.
///
/// **It renders with the real bundled faces, not Ahem.** That is a deliberate
/// departure from the default lane. Ahem's advance is 1.0 em for every glyph,
/// roughly double a real Latin face, so an Ahem fit-matrix fails on strings
/// that fit comfortably and says nothing about the ones that do not — it is a
/// character-count test wearing a layout test's clothes. Loading fonts here is
/// a `setUpAll` in one suite, which is a different thing from the global
/// `flutter_test_config.dart` hook the golden discipline forbids.
///
/// **What it proves and does not.** It proves the *strings* fit their *type
/// steps* in the line budget the design gives them, at the width the narrowest
/// supported phone leaves for content. It is not a screen: E08's layouts are
/// tested against E08's screens. It is the closest thing to one that exists at
/// this point in the sequence, and it is honest about that.
void main() {
  setUpAll(loadAppFonts);

  group('every string fits its type step', () {
    for (final localeCase in LocaleCase.all) {
      for (final scale in kTextScales) {
        for (final device in Device.all) {
          testWidgets('${localeCase.tag} at ${scale}x on ${device.name}', (
            tester,
          ) async {
            useDevice(tester, device);

            final overflowing = await _measure(
              tester,
              localeCase: localeCase,
              device: device,
              scale: scale,
            );

            expect(
              tester.takeException(),
              isNull,
              reason: 'the specimen itself failed to lay out',
            );
            expect(
              overflowing,
              isEmpty,
              reason:
                  'these strings need more lines than their slot allows under '
                  '${localeCase.tag} at ${scale}x on ${device.name}. The fix '
                  'is a smaller base type step for the slot, or a slot that '
                  'genuinely allows another line — never a FittedBox, never a '
                  'clamped textScaler, never an ellipsis on a value',
            );
          });
        }
      }
    }
  });

  group('the pseudo-locale lane', () {
    // Not an ARB and never shipped: an app_en_XA.arb would fail
    // check_arb_parity.sh and put a fake language into supportedLocales. It
    // runs as a fifth locale here and catches a truncation German has not
    // reached yet.
    for (final device in Device.all) {
      testWidgets('expanded English fits on ${device.name}', (tester) async {
        useDevice(tester, device);

        final overflowing = await _measure(
          tester,
          localeCase: LocaleCase.all.first,
          device: device,
          scale: 1,
          pseudo: true,
        );

        expect(tester.takeException(), isNull);
        expect(
          overflowing,
          isEmpty,
          reason:
              'English expanded ${PseudoLocale.expansionFactor}x does not fit '
              'on ${device.name}. A real translation reaches this length '
              'before a reviewer does',
        );
      });
    }
  });

  group('the slot table covers the strings', () {
    test('every ARB key has a declared type step and line budget', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final keys = renderAllStrings(l10n, SupportedLocale.en).keys.toSet();

      expect(
        keys.difference(kTypeSlots.keys.toSet()),
        isEmpty,
        reason:
            'an ARB key with no slot would be silently unmeasured, which is '
            'the failure this matrix exists to prevent',
      );
      expect(
        kTypeSlots.keys.toSet().difference(keys),
        isEmpty,
        reason: 'a slot for a key that no longer exists',
      );
    });
  });

  group('a mixed-script run is taller than its Latin line box', () {
    // MEASURED, and recorded here because E05 builds the rows it breaks. The
    // language list shows every language in its own name, so under `en` the
    // Sorani row is an Arabic-script string rendered at a Latin step: the
    // fallback face's ascent and descent exceed Nunito's fontSize * height,
    // and the line is taller than the step declares.
    //
    // This is not a defect in the type scale — forcing the strut would clip
    // the very glyphs the fallback exists to draw. It is a constraint on
    // LAYOUT: a row carrying a language name sizes to its content and never to
    // a fixed height.
    testWidgets('so E05 must not give such a row a fixed height', (
      tester,
    ) async {
      late SunburstType type;

      await tester.pumpLocalized(
        Builder(
          builder: (context) {
            type = SunburstType.of(context);
            return const SizedBox.shrink();
          },
        ),
        LocaleCase.all.first,
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final latinBox = type.body.fontSize! * type.body.height!;

      double heightOf(String text) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: type.body),
          textDirection: TextDirection.ltr,
        )..layout();
        final height = painter.height;
        painter.dispose();
        return height;
      }

      expect(heightOf(l10n.languageNameEn), lessThanOrEqualTo(latinBox + 1));
      expect(
        heightOf(l10n.languageNameCkb),
        greaterThan(latinBox),
        reason:
            'if this ever stops being true the fallback stopped being used, '
            'which means the Sorani row is rendering tofu',
      );
    });
  });

  group('the longest string per type step', () {
    testWidgets('is measured and recorded for E05', (tester) async {
      // A DERIVED ARTIFACT, not an assertion: build/ is not tracked. E05 reads
      // it when a label stops fitting, because D8's rule is that the slot takes
      // a smaller base type step rather than shrinking its text.
      final rows = <({String step, String locale, String key, double width})>[];

      for (final localeCase in LocaleCase.all) {
        final l10n = await AppLocalizations.delegate.load(
          localeCase.flutterLocale,
        );
        final strings = renderAllStrings(l10n, localeCase.locale);
        final type = await _typeFor(tester, localeCase);

        for (final entry in strings.entries) {
          final painter = TextPainter(
            text: TextSpan(
              text: entry.value,
              style: styleForStep(type, kTypeSlots[entry.key]!.step),
            ),
            textDirection: localeCase.direction,
          )..layout();

          rows.add((
            step: kTypeSlots[entry.key]!.step,
            locale: localeCase.tag,
            key: entry.key,
            width: painter.width,
          ));
          painter.dispose();
        }
      }

      File(
        'build/longest_strings_by_step.txt',
      ).writeAsStringSync(_report(rows));

      expect(rows, hasLength(LocaleCase.all.length * kTypeSlots.length));
    });
  });
}

/// The three text scales the matrix runs at.
///
/// 1.0 is the design size, 1.3 a common accessibility setting, and 2.0 the
/// ceiling `accessibility-as-code` requires the app to survive. Nothing clamps
/// them: the app either fits at 2.0 or the step is wrong.
const List<double> kTextScales = <double>[1, 1.3, 2];

/// The horizontal inset the reference screens leave for a card's content: 20pt
/// of page margin plus 16pt of card padding, on both sides.
const double _kContentInset = 72;

/// Renders the specimen and returns every key needing more lines than its slot
/// allows, as `key: needed of allowed`.
///
/// The budget scales with the text scaler: `(lines * scale).ceil()`. That is
/// the design rule, not a tolerance — `accessibility-as-code` rules 4 and 5 say
/// nothing shrinks to fit, so a slot given twice the type size is given twice
/// the room, and the question stays whether the string wants *disproportionately*
/// more.
Future<List<String>> _measure(
  WidgetTester tester, {
  required LocaleCase localeCase,
  required Device device,
  required double scale,
  bool pseudo = false,
}) async {
  await tester.pumpLocalized(
    _TypeSpecimen(pseudo: pseudo),
    localeCase,
    textScaler: TextScaler.linear(scale),
  );

  final type = await _typeFor(tester, localeCase, scale: scale);
  final l10n = await AppLocalizations.delegate.load(localeCase.flutterLocale);
  final strings = renderAllStrings(l10n, localeCase.locale);
  final available = device.logicalSize.width - _kContentInset;
  final overflowing = <String>[];

  for (final entry in strings.entries) {
    final slot = kTypeSlots[entry.key]!;
    final painter = TextPainter(
      text: TextSpan(
        text: pseudo ? PseudoLocale.expand(entry.value) : entry.value,
        style: styleForStep(type, slot.step),
      ),
      textDirection: localeCase.direction,
      textScaler: TextScaler.linear(scale),
    )..layout(maxWidth: available);

    final needed = painter.computeLineMetrics().length;
    final allowed = (slot.lines * scale).ceil();
    if (needed > allowed) {
      overflowing.add('${entry.key} (${slot.step}) $needed of $allowed');
    }
    painter.dispose();
  }

  return overflowing;
}

Future<SunburstType> _typeFor(
  WidgetTester tester,
  LocaleCase localeCase, {
  double scale = 1,
}) async {
  late SunburstType type;

  await tester.pumpLocalized(
    Builder(
      builder: (context) {
        type = SunburstType.of(context);
        return const SizedBox.shrink();
      },
    ),
    localeCase,
    textScaler: TextScaler.linear(scale),
  );

  return type;
}

String _report(
  List<({String step, String locale, String key, double width})> rows,
) {
  final byStep = <String, List<({String locale, String key, double width})>>{};
  for (final row in rows) {
    (byStep[row.step] ??= []).add((
      locale: row.locale,
      key: row.key,
      width: row.width,
    ));
  }

  final buffer = StringBuffer()
    ..writeln('# Longest string per type step, per locale')
    ..writeln('#')
    ..writeln('# GENERATED by test/l10n/text_expansion_matrix_test.dart.')
    ..writeln('# Widths are logical points at textScaler 1.0, measured with')
    ..writeln('# the bundled faces through TextPainter.')
    ..writeln('#')
    ..writeln('# E05 reads this when a label stops fitting: the slot takes a')
    ..writeln('# SMALLER BASE TYPE STEP. Never a FittedBox, never a clamped')
    ..writeln('# textScaler, never an ellipsis on a value.')
    ..writeln();

  for (final step in byStep.keys.toList()..sort()) {
    buffer.writeln(step);
    for (final tag in LocaleCase.all.map((c) => c.tag)) {
      final worst = byStep[step]!
          .where((e) => e.locale == tag)
          .reduce((a, b) => a.width >= b.width ? a : b);
      buffer.writeln(
        '  ${tag.padRight(4)}${worst.width.toStringAsFixed(1).padLeft(7)}pt  '
        '${worst.key}',
      );
    }
    buffer.writeln();
  }

  return buffer.toString();
}

/// Every ARB string, at the step its slot declares.
///
/// The slots size to their content — nothing here is a fixed height. The fit
/// question is asked by measuring line counts in [_measure], not by provoking a
/// `RenderFlex` overflow: an overflow reports once per `RenderObject` per frame
/// and names pixels, while a measurement names every offending key. What this
/// widget adds is the real pipeline — the delegate list, the resolved script,
/// the fallback cascade — so a string that cannot be laid out at all fails
/// here.
class _TypeSpecimen extends StatelessWidget {
  const _TypeSpecimen({this.pseudo = false});

  /// Whether to expand every string through [PseudoLocale] first.
  final bool pseudo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = SunburstType.of(context);
    final tag = Localizations.localeOf(context).languageCode;
    final locale = SupportedLocale.tryParse(tag) ?? SupportedLocale.en;
    final strings = renderAllStrings(l10n, locale);

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: _kContentInset / 2,
      ),
      child: ListView(
        children: [
          for (final entry in strings.entries)
            Text(
              pseudo ? PseudoLocale.expand(entry.value) : entry.value,
              style: styleForStep(type, kTypeSlots[entry.key]!.step),
            ),
        ],
      ),
    );
  }
}
