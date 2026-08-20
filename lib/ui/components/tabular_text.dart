import 'package:flutter/widgets.dart';
import 'package:mindforge/l10n/bidi_text.dart';

/// Renders a changing number without the layout moving under it.
///
/// **`FontFeature.tabularFigures()` is a request, not a guarantee.** It asks the
/// font for the `tnum` feature; a font that does not ship one ignores it
/// silently. Measured on the bundled variable Fredoka at 22pt: `0:23` renders
/// 40.4 points wide and `0:11` renders 32.2 — an eight-point jump every time a
/// running clock ticks past a 1. The feature is still declared on the type
/// step, because it costs nothing and a future font may honour it; this widget
/// is what makes the behaviour true regardless.
///
/// It measures the widest digit **for the style and scale actually in use**,
/// then gives every digit a box of that width. Non-digits keep their natural
/// width, so a colon or a decimal separator stays where the typographer put it.
/// Nothing is scaled, clipped or ellipsised: the box grows to the widest digit
/// rather than the glyph shrinking to the box.
///
/// The digits measured are the ones **being rendered** — Eastern Arabic under
/// `fa` and `ckb`, Latin under `en` and `de` — because the widest digit is not
/// the same character in every script.
class TabularText extends StatelessWidget {
  /// Renders [value] with its digits on a fixed pitch.
  const TabularText(this.value, {required this.style, super.key});

  /// The already-localized value.
  final String value;

  /// The style to render in.
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    // STRIPPED BEFORE SPLITTING. A bidi isolate mark is a control, not a
    // character to put in a box: each box below is its own paragraph, so an
    // isolate cannot do its job here anyway — and this widget already pins the
    // row LTR, which is exactly what the isolate was for. Boxing one fed a
    // negative width into an `IntrinsicHeight` three cells wide, and the
    // results screen after a Schulte run drew its header and then nothing at
    // all: no score, no stats, no buttons.
    //
    // The ANNOUNCEMENT keeps the original: `Semantics(label:)` takes a string,
    // not a layout, and the marks are harmless there.
    final drawn = BidiText.strip(value);

    // WORDS ARE LAID OUT AS TEXT; only a NUMBER gets the per-character
    // treatment. Every box below is its own paragraph and the row that holds
    // them cannot wrap, which breaks a multi-word value two different ways:
    //
    //  - in Arabic script, catastrophically — each letter is shaped in
    //    ISOLATED form, the joins that make the script readable are gone, and
    //    the LTR row reverses the words on top of it. Stats' Persian "time
    //    trained" drew as an unreadable smear.
    //  - in Latin, quietly — `0 Std. 0 Min.` at 2.0x measured 275pt of content
    //    in a 141pt viewport, so a German player saw it cut off mid-word with
    //    no wrap, no ellipsis and no scroll affordance. That is the same
    //    "a truncated value reads as a plausible one" that `a11y_bans_test`
    //    bans an ellipsis for, just without the visible edge.
    //
    // The first version of this guard tested for a JOINING script and rescued
    // only the first case. A LETTER is the right question: a value with words
    // in it is prose, and prose wraps.
    if (_hasLetters(drawn)) {
      return Text(value, style: style, textAlign: TextAlign.center);
    }

    final pitch = _widestDigit(drawn, style, scaler, direction);

    // ONE semantic node carrying the whole value. Without it a screen reader
    // walks the per-character boxes below and reads "one, comma, four, eight,
    // zero" — a fixed layout is worth nothing if it costs the announcement.
    return Semantics(
      label: value,
      child: ExcludeSemantics(
        // IT PANS RATHER THAN SHRINKING OR CLIPPING. A value's length is not
        // something the shell controls — a four-digit score at 76pt, a run
        // count in German, any of them at text scale 2.0 — and of the three
        // ways a too-wide number can behave, two are wrong: scaling the glyphs
        // down makes the number SMALLER for exactly the player who asked for
        // bigger text, and clipping turns a wrong number into a plausible one.
        //
        // It lives here rather than at each call site so every value in the
        // app behaves the same way, and so a new one cannot forget. The scroll
        // view sits INSIDE the ExcludeSemantics, so it adds no semantics
        // boundary and a caller can still merge the label and the value into
        // one stop.
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            // ALWAYS LTR, whatever the page reads. A number is displayed left to
            // right in every language — Unicode lays a numeric run out that way
            // inside an RTL paragraph — and splitting one into a box per
            // character destroys that rule, because each character becomes its
            // own paragraph and this Row does the ordering instead.
            //
            // Inheriting the ambient direction painted 1,480 as 0,841 reversed
            // on the canonical simulator under fa and ckb. The RTL golden lane
            // could not see it: it renders plain Text, where the bidi algorithm
            // still applies. The comment that used to sit here claimed "a number
            // is not re-ordered by this widget", which was the opposite of what
            // it did.
            //
            // Only the run's INTERNAL order is fixed. Where the run sits on the
            // screen is still the parent's decision, and the parent mirrors.
            textDirection: TextDirection.ltr,
            children: [
              for (final character in drawn.characters)
                if (_isDigit(character))
                  SizedBox(
                    width: pitch,
                    child: Text(
                      character,
                      style: style,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Text(character, style: style),
            ],
          ),
        ),
      ),
    );
  }

  /// Whether [value] contains a letter, in any script.
  ///
  /// **A unit is not a letter for this purpose, and that is the subtlety.**
  /// `18.6s`, `640ms` and `0 Std. 0 Min.` all contain letters, and only the
  /// last is prose — but the first two are STATIC values that never animate,
  /// so nothing is lost by laying them out as text, while the third is what
  /// gets clipped. Every value whose digits actually move under the player's
  /// eye — the clock `0:00`, a score `1,480`, a streak `×1`, a percentage
  /// `100%` — carries no letter at all and still gets its fixed pitch.
  ///
  /// Uses the Unicode letter property rather than a block list: an earlier
  /// version tested only for Arabic script and left German clipped.
  static bool _hasLetters(String value) =>
      RegExp(r'\p{L}', unicode: true).hasMatch(value);

  /// Whether [character] is a digit in any script this app renders.
  static bool _isDigit(String character) {
    final rune = character.runes.first;

    return (rune >= 0x30 && rune <= 0x39) || // ASCII
        (rune >= 0x06F0 && rune <= 0x06F9); // Eastern Arabic
  }

  /// The width of the widest digit appearing in [value]'s own script.
  ///
  /// Measured from the digits actually present rather than from a hardcoded
  /// zero-to-nine run: a value with no digits needs no pitch at all, and a
  /// Persian value must not be measured against Latin glyphs.
  static double _widestDigit(
    String value,
    TextStyle style,
    TextScaler scaler,
    TextDirection direction,
  ) {
    // `_isDigit &&`, not a bare codepoint comparison. The old test caught an
    // en dash, a curly apostrophe, and — the one that mattered here — the
    // FSI/PDI isolate marks the bidi helper inserts, all of which sit above
    // U+06F0. An isolated Latin clock like `\u2068` + "12:34" was then
    // measured against Eastern Arabic digits that Fredoka does not cover, so
    // the pitch came from the fallback face while the glyph came from Fredoka
    // and the number was mis-spaced — the exact jitter this widget removes.
    final digits = value.characters.where(_isDigit).toList();
    if (digits.isEmpty) return 0;

    final zero = digits.any((character) => character.runes.first >= 0x06F0)
        ? 0x06F0
        : 0x30;
    var widest = 0.0;

    // Only the digits actually present, which is what the doc above says and
    // what the ten-layouts-per-build version did not do.
    for (var i = 0; i < 10; i++) {
      final painter = TextPainter(
        text: TextSpan(text: String.fromCharCode(zero + i), style: style),
        textDirection: direction,
        textScaler: scaler,
      )..layout();

      if (painter.width > widest) widest = painter.width;
      painter.dispose();
    }

    return widest;
  }
}
