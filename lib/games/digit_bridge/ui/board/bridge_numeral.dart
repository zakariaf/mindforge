import 'package:flutter/widgets.dart';

/// One numeral run, in its own direction.
///
/// **The only place in Digit Bridge that pins a direction, and every numeral on
/// the board goes through it.** The target, the six chips and the detail
/// screen's legend all render a run of digits, and all three had a
/// `Directionality` of their own before this widget existed — three islands
/// with one reason between them, which is three places for the reasoning to
/// drift out of date.
///
/// **Why a numeral has its own direction at all.** A number's most significant
/// digit is on the left in BOTH systems this game bridges: Eastern Arabic
/// numerals are written left to right even inside a right-to-left line, which
/// is why Unicode gives them a strong left-to-right bidi class of their own. So
/// a numeral is a coordinate space rather than a text flow — position zero is
/// the leading digit in every locale — and letting it inherit the page's
/// direction makes it reorder at the boundary with Persian chrome and read
/// backwards.
///
/// The chrome around it still mirrors. This is an island around ONE RUN, never
/// a root: the chip grid, the insets and the traversal order all follow the
/// locale, and `bridge_board_rtl_test.dart` is what proves the difference.
class BridgeNumeral extends StatelessWidget {
  /// Renders [label] left to right, whatever the page direction is.
  const BridgeNumeral({
    required this.label,
    required this.style,
    super.key,
  });

  /// The numeral, already rendered in this side's script.
  final String label;

  /// The step it draws at.
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Text(label, textAlign: TextAlign.center, maxLines: 1, style: style),
  );
}
