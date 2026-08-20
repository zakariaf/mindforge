import 'package:flutter/material.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/components/tabular_text.dart';

/// Which fill one results cell takes.
///
/// The trio is turquoise, paper, coral, in that order. `app.html`:
/// `.tri:nth-child(1){background:var(--turquoise)}` and `:nth-child(3)` coral.
enum ResultStatTone {
  /// The leading cell.
  cool,

  /// The middle cell.
  paper,

  /// The trailing cell.
  warm,
}

/// One of the three cells under the results score.
///
/// **A separate widget from `StatBox`, not a density flag on it.** The two
/// differ in radius, padding, alignment, both type steps and their tone sets —
/// which is everything except "a caption over a value in a raised box". A flag
/// would have made one widget that is two widgets with a switch inside.
///
/// Its content is centred rather than start-aligned, so the trio reads as one
/// row instead of three narrow left-hand columns — and that is true in all four
/// locales, because centred has no start edge to mirror.
class ResultStatCell extends StatelessWidget {
  /// Creates a cell showing [value] under [label].
  const ResultStatCell({
    required this.label,
    required this.value,
    this.tone = ResultStatTone.paper,
    super.key,
  });

  /// The already-localized caption.
  final String label;

  /// The already-localized value.
  final String value;

  /// Which fill.
  final ResultStatTone tone;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    // app.html says it on the rule: "on a saturated fill the label is ink —
    // ink-2 drops to 2.8:1 on coral".
    final labelColour = switch (tone) {
      ResultStatTone.paper => colours.textSecondary,
      ResultStatTone.cool || ResultStatTone.warm => colours.textPrimary,
    };

    // ONE stop, stated rather than merged, for the same reason as ScoreSlab:
    // the value sits inside a scroll view and a Scrollable is a semantics
    // boundary MergeSemantics cannot reach across.
    return Semantics(
      label: '$label. $value',
      child: ExcludeSemantics(
        child: PopSurface(
          fill: switch (tone) {
            ResultStatTone.cool => colours.accentCool,
            ResultStatTone.paper => colours.surfaceRaised,
            ResultStatTone.warm => colours.accentWarm,
          },
          radius: BorderRadiusDirectional.all(shape.radiusMd),
          elevation: PopElevation.e1,
          minTarget: 0,
          padding: const EdgeInsetsDirectional.fromSTEB(8, 11, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                textAlign: TextAlign.center,
                style: type.resultStatLabel.copyWith(color: labelColour),
              ),
              const SizedBox(height: 4),
              // A third of the pane wide, holding a number whose length the
              // shell does not control. It pans rather than shrinking or
              // clipping — the same choice ScoreSlab makes, and the same
              // reason: a value the player asked to see larger must not get
              // smaller, and a clipped digit is a wrong number.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: TabularText(
                  value,
                  style: type.resultStatValue.copyWith(
                    color: colours.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
