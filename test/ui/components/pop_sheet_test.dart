import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/ui/components/pop_button.dart';
import 'package:mindforge/ui/components/pop_sheet.dart';

import '../../support/component_harness.dart';

/// The bottom sheet, when it holds more choices than the screen has room for.
void main() {
  group('a sheet with more actions than fit', () {
    testWidgets('scrolls its actions rather than overflowing', (tester) async {
      // THE LANGUAGE SHEET. Five options — System, English, Deutsch, Persian,
      // Sorani — plus a title and the handle exceed the height a modal bottom
      // sheet is given, and in `fa` the last row was cut off under a
      // 14-pixel overflow stripe. A sheet is a list of choices; the LIST is
      // what gives way, not the viewport, and not the choice at the end of it.
      await tester.pumpPopComponent(
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 240,
            child: PopSheet(
              title: 'Language',
              actions: <Widget>[
                for (var i = 0; i < 5; i++)
                  PopButton(
                    label: 'Option $i',
                    size: PopButtonSize.large,
                    expand: true,
                    onPressed: () {},
                  ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(PopSheet),
          matching: find.byType(Scrollable),
        ),
        findsOneWidget,
      );
    });

    testWidgets('and a sheet that fits still wraps its content', (
      tester,
    ) async {
      // The two-action pause sheet must not become a full-height scroll view
      // just because a scroller is now available to it.
      await tester.pumpPopComponent(
        Align(
          alignment: Alignment.bottomCenter,
          child: PopSheet(
            title: 'Paused',
            actions: <Widget>[
              PopButton(label: 'Keep playing', onPressed: () {}),
              PopButton(label: 'Quit', onPressed: () {}),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(PopSheet)).height, lessThan(400));
    });
  });
}
