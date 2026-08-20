import 'package:flutter/material.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/components/tabular_text.dart';

/// Which fill a [StatBox] takes.
///
/// A tone, not a `Color`: the label colour has to change with the fill to stay
/// above 4.5:1, and a widget handed a bare colour cannot know which it got.
enum StatBoxTone {
  /// The default white box.
  paper,

  /// The sunshine box, used for the one number the screen is about.
  accent,
}

/// A caption over a number, in a raised box.
///
/// **It formats nothing.** The value arrives already localized — `1,480`,
/// `1.480`, `۱٬۴۸۰` — from the shell, which owns `LocaleNumbers`. That is what
/// keeps the numeral system one decision instead of one per screen.
///
/// It reads as a single semantic stop. Two stops for a caption and a number is
/// how a stats screen becomes a dozen unrelated announcements.
class StatBox extends StatelessWidget {
  /// Creates a box showing [value] under [label].
  const StatBox({
    required this.label,
    required this.value,
    this.tone = StatBoxTone.paper,
    super.key,
  });

  /// The already-localized caption.
  final String label;

  /// The already-localized value.
  final String value;

  /// Which fill.
  final StatBoxTone tone;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    // app.html says it on the rule: "ink-2 is for paper and cream only — on a
    // saturated fill the label goes ink". textSecondary on sunshine is 3.1:1.
    final labelColour = switch (tone) {
      StatBoxTone.paper => colours.textSecondary,
      StatBoxTone.accent => colours.textPrimary,
    };

    return MergeSemantics(
      child: PopSurface(
        fill: switch (tone) {
          StatBoxTone.paper => colours.surfaceRaised,
          StatBoxTone.accent => colours.accent,
        },
        radius: BorderRadiusDirectional.all(shape.radiusLg),
        elevation: PopElevation.e1,
        minTarget: 0,
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(label, style: type.label.copyWith(color: labelColour)),
            const SizedBox(height: 3),
            // TabularText, not Text: the bundled Fredoka does not honour the
            // tnum feature statValue declares, and a stats screen is a column
            // of numbers whose digits have to line up.
            TabularText(
              value,
              style: type.statValue.copyWith(color: colours.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
