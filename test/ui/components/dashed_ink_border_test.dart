import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/dashed_ink_border.dart';

void main() {
  const shape = SunburstShape.sunburstPop;
  const colours = SunburstColors.sunburstPop;

  DashedInkBorder border({double dashOn = 9, Color? colour}) => DashedInkBorder(
    radius: BorderRadius.all(shape.radiusLg),
    colour: colour ?? colours.border,
    strokeWidth: shape.borderWidth,
    dashOn: dashOn,
    dashOff: shape.dashOff,
  );

  group('DashedInkBorder', () {
    test('shouldRepaint is a single value compare', () {
      expect(border().shouldRepaint(border()), isFalse);
      expect(border().shouldRepaint(border(dashOn: 10)), isTrue);
      expect(
        border().shouldRepaint(border(colour: colours.borderDisabled)),
        isTrue,
      );
    });

    test('draws at the pitch the shape scale declares', () {
      expect(shape.dashOn, 9);
      expect(shape.dashOff, 7);
    });
  });
}
