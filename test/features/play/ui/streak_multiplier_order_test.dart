import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/bidi_text.dart';
import 'package:mindforge/l10n/locale_numbers.dart';

import '../../../support/load_app_fonts.dart';

/// Which side of the digit the multiplication sign lands on.
///
/// **Measured, not asserted about the string.** The logical order is `×` then
/// the digit in every locale — that is one ARB message — and what differs is
/// where the bidi algorithm PUTS them. A test that compared strings would pass
/// in both directions while the screen drew the wrong one, which is exactly
/// what happened: the code carried a comment claiming an FSI isolate yields
/// `۷×` in Persian, no test checked, and the simulator drew `×۱`.
///
/// FSI resolves to the direction of the first STRONG character, and `×7` has
/// none — so it falls back to LTR and pins the sign to the left in every
/// locale. Inheriting the paragraph is what the reference screens draw.
void main() {
  setUpAll(loadAppFonts);

  /// The left edge of [part] as laid out in [locale].
  double leftEdgeOf(String text, String part, SupportedLocale locale) {
    final direction = locale.isRightToLeft
        ? TextDirection.rtl
        : TextDirection.ltr;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 22),
      ),
      textDirection: direction,
    )..layout();

    final start = text.indexOf(part);
    final boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: start + part.length),
    );

    painter.dispose();

    return boxes.first.left;
  }

  for (final locale in SupportedLocale.values) {
    test('the sign sits on the reading-start side in ${locale.tag}', () async {
      final l10n = await AppLocalizations.delegate.load(Locale(locale.tag));
      final numbers = LocaleNumbers(locale);
      final formatted = numbers.count(7);
      final text = l10n.streakMultiplier(7, formatted);

      final signLeft = leftEdgeOf(text, '×', locale);
      final digitLeft = leftEdgeOf(text, formatted, locale);

      if (locale.isRightToLeft) {
        // `۷×` — the digit is drawn to the LEFT of the sign, which is what
        // screens/rtl/04-stroop-rush.png shows in the streak pill.
        expect(
          digitLeft,
          lessThan(signLeft),
          reason: '${locale.tag} drew the sign before the digit',
        );
      } else {
        // `×7`.
        expect(
          signLeft,
          lessThan(digitLeft),
          reason: '${locale.tag} drew the digit before the sign',
        );
      }
    });
  }

  test('and an FSI isolate is what would break it', () async {
    // The negative half, so nobody re-adds the wrapper to "be safe about
    // bidi". `BidiText.isolate` is the right tool for a run with a strong
    // character that must not reorder its neighbours — a game title beside a
    // score. `×7` has no strong character at all, so the isolate resolves LTR
    // and pins the sign to the left in Persian too.
    const locale = SupportedLocale.fa;
    final l10n = await AppLocalizations.delegate.load(Locale(locale.tag));
    final formatted = const LocaleNumbers(locale).count(7);
    final isolated = BidiText.isolate(l10n.streakMultiplier(7, formatted));

    expect(
      leftEdgeOf(isolated, formatted, locale),
      greaterThan(leftEdgeOf(isolated, '×', locale)),
      reason: 'the isolate no longer reorders — re-check why it was dropped',
    );
  });
}
