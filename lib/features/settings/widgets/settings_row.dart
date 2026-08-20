import 'package:flutter/material.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// One row inside a settings group.
///
/// **The WHOLE row is the target, not the control at its end.** A 66x34 toggle
/// is under the 48pt floor on its own, and asking someone to hit it is asking
/// them to hit a third of the row they can see.
///
/// A row with no [onTap] is a row whose control owns the interaction — a
/// toggle, which handles its own tap — and it is not focusable, so a keyboard
/// pass does not stop twice on the same thing.
class SettingsRow extends StatelessWidget {
  /// Creates a row.
  const SettingsRow({
    required this.glyph,
    required this.label,
    this.trailing,
    this.below,
    this.onTap,
    this.semanticValue,
    super.key,
  });

  /// The mark in the leading chip.
  final SunburstGlyph glyph;

  /// The already-localized label.
  final String label;

  /// The control or value at the end edge.
  final Widget? trailing;

  /// Anything under the label, such as a palette preview.
  final Widget? below;

  /// What tapping the row does, or `null` when its control owns the tap.
  final VoidCallback? onTap;

  /// The current value, announced after the label.
  ///
  /// A row that announces only its label tells a screen-reader user what the
  /// setting is called and not what it is set to — which is the half they came
  /// for.
  final String? semanticValue;

  /// The leading chip's size. `app.html`: `.srow .si{width:36px;height:36px}`.
  static const double chipSize = 36;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);
    final trailing = this.trailing;
    final below = this.below;

    final row = Padding(
      // app.html: `.srow{padding:14px 15px}`.
      padding: const EdgeInsetsDirectional.fromSTEB(15, 14, 15, 14),
      // AN EXPANDED LABEL BESIDE A FLEXIBLE CONTROL. Both halves flex, so
      // free space splits evenly — and the label's half is TIGHT, which is
      // what keeps it against the icon chip. Two loose halves centred it,
      // because a shrink-wrapped label inside a spaceBetween row sits wherever
      // its share leaves it; caught on the simulator against 08-settings.png.
      //
      // The control has to flex at all because its printed word is translated:
      // Sorani's OFF is "داخراوە", seven characters, and at text scale 1.3 the
      // track it sits in is wider than a natural-width trailing slot would be
      // given. This row is where the ON/OFF-inside-the-track design first
      // stops fitting.
      child: Row(
        children: <Widget>[
          ExcludeSemantics(
            child: Container(
              width: chipSize,
              height: chipSize,
              decoration: BoxDecoration(
                color: colours.surfaceSunk,
                borderRadius: BorderRadius.all(shape.radiusSm),
                border: Border.all(
                  color: colours.border,
                  width: shape.borderWidthNested,
                ),
              ),
              alignment: Alignment.center,
              child: SunburstGlyphIcon(glyph, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: type.titleBar.copyWith(color: colours.textPrimary),
                ),
                if (below != null) ...<Widget>[
                  const SizedBox(height: 7),
                  below,
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 12),
            // FLEXIBLE, not natural width. The Language row's value is a
            // language name, and "کوردیی ناوەندی" beside a translated label at
            // text scale 1.3 is wider than the row — measured. The value
            // wraps; the label does not lose its start edge.
            Flexible(child: trailing),
          ],
        ],
      ),
    );

    if (onTap == null) return row;

    return Semantics(
      button: true,
      label: label,
      value: semanticValue,
      child: ExcludeSemantics(
        child: PopSurface(
          fill: colours.surfaceRaised,
          radius: BorderRadiusDirectional.zero,
          elevation: PopElevation.flat,
          nested: true,
          onTap: onTap,
          child: row,
        ),
      ),
    );
  }
}

/// A stack of [SettingsRow]s inside one raised card.
///
/// **The divider is ink, not cream.** `app.html` says so on the rule itself: a
/// 1.1:1 divider is no divider at all.
class SettingsGroup extends StatelessWidget {
  /// Creates a group of [rows].
  const SettingsGroup({required this.rows, super.key});

  /// The rows, in order.
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    return PopSurface(
      fill: colours.surfaceRaised,
      radius: BorderRadiusDirectional.all(shape.radiusLg),
      minTarget: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.all(shape.radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final (index, row) in rows.indexed) ...<Widget>[
              if (index > 0)
                ColoredBox(
                  color: colours.border,
                  child: SizedBox(height: shape.borderWidth),
                ),
              row,
            ],
          ],
        ),
      ),
    );
  }
}
