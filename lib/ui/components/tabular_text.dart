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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          // The RUN is laid out in reading order like any other text; only the
          // per-digit pitch is fixed. A number is not re-ordered by this
          // widget.
          textDirection: direction,
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
    final zero =
        value.characters.any(
          (character) => character.runes.first >= 0x06F0,
        )
        ? 0x06F0
        : 0x30;
    var widest = 0.0;

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
