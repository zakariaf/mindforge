import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

/// The app's mark, at any size.
///
/// The same construction as the wordmark's tile — a coral square with the ink
/// edge and a cream square inside it — scaled to fill whatever box it is given.
/// It lives in `lib/ui/` rather than in `tool/` so it reads the shipped tokens:
/// an icon exported by hand drifts from the palette the moment a token moves,
/// and nothing notices until the icon on the home screen is a coral the app no
/// longer uses.
///
/// **Everything is a fraction of the side**, so one widget renders every size
/// iOS asks for. The proportions come from the wordmark's own 26/9/8/3.
class AppIconMark extends StatelessWidget {
  /// Creates the mark.
  const AppIconMark({super.key});

  /// The wordmark's tile is 26 with a 9 radius, an 8 dot and a 3 edge.
  static const double _tile = 26;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final scale = side / _tile;

        return DecoratedBox(
          // OPAQUE, and drawn rather than inherited. iOS rejects an app icon
          // with an alpha channel, and that rejection arrives at upload rather
          // than at build — so the ground is painted here instead of relying
          // on whatever happens to be behind the widget.
          decoration: BoxDecoration(color: colours.accentWarm),
          child: Center(
            child: SizedBox.square(
              // The cream square, at the wordmark's own proportion. The ink
              // edge the wordmark draws is deliberately absent: iOS rounds and
              // masks the icon itself, so a border would be clipped unevenly
              // on the corners it survives.
              dimension: shape.wordmarkDot * scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colours.surface,
                  borderRadius: BorderRadius.all(
                    Radius.circular(shape.wordmarkDotRadius.x * scale),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
