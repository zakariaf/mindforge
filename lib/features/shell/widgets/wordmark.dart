import 'package:flutter/material.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

/// The MindForge lockup: a chunky coral tile and the product name.
///
/// **The name is pinned left-to-right inside an RTL page.** "MindForge" is a
/// Latin brand string, and a Latin run inside an RTL paragraph is reordered by
/// the bidi algorithm unless it is isolated — which is how a wordmark ends up
/// rendering as "orgeMindF" beside a Persian sentence. Here it is its own
/// widget with its own direction; where it appears INSIDE a sentence, it goes
/// through an ARB placeholder and `BidiText.isolate`, never spliced.
///
/// It is labelled but is **not a header**: a screen has one h1 and this is not
/// it, so a screen reader's heading list stays useful.
class Wordmark extends StatelessWidget {
  /// Creates the lockup.
  const Wordmark({super.key});

  /// The product name. Never translated, never cased in Dart.
  static const String name = 'MindForge';

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    return Semantics(
      label: name,
      header: false,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // 26x26, r9, coral, with an 8x8 cream square centred.
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: colours.gameStroop,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: colours.border,
                  width: shape.borderWidth,
                ),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colours.surface,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              // THE PIN. Not the ambient direction: a Latin run in an RTL
              // paragraph is reordered without it.
              textDirection: TextDirection.ltr,
              style: type.titleBar.copyWith(color: colours.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
