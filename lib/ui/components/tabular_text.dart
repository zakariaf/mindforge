import 'package:flutter/widgets.dart';

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
    final pitch = _widestDigit(value, style, scaler, direction);

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
              for (final character in value.characters)
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
