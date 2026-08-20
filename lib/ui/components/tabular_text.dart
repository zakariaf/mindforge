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

    // A JOINED SCRIPT IS SHAPED AS ONE RUN OR IT IS NOT SHAPED AT ALL. Every
    // box below is its own paragraph, so an Arabic-script letter inside one is
    // rendered in ISOLATED form and the joins that make the script readable
    // are gone — and the LTR row then reverses the words on top of it. Stats'
    // "time trained" is a whole Persian sentence, and it drew as an unreadable
    // smear that overflowed its box.
    //
    // Latin never showed it, because Latin letters do not join: `0h 0m` split
    // into boxes still reads. So the guard is about the SCRIPT, not about
    // whether letters are present.
    if (_hasJoiningScript(drawn)) {
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

  /// Whether [value] contains a letter from a script whose glyphs join.
  ///
  /// Arabic script only, which is every joining script this app ships.
  ///
  /// The block holds more than letters, and the exclusions are the whole
  /// subtlety: both DIGIT ranges live in it, and so do the numeric marks a
  /// Persian number is built from — `٪` U+066A, `٫` U+066B and `٬` U+066C. A
  /// guard that took the whole block sent `۱٬۴۸۰` down the plain-text path and
  /// took its fixed pitch away, which is the one thing this widget is for.
  static bool _hasJoiningScript(String value) => value.runes.any((rune) {
    if (rune < 0x0600 || rune > 0x06FF) return false;
    if (rune >= 0x0660 && rune <= 0x0669) return false;
    if (rune >= 0x06F0 && rune <= 0x06F9) return false;
    if (rune >= 0x066A && rune <= 0x066C) return false;

    return true;
  });

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
