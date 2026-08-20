import 'package:flutter/widgets.dart';
import 'package:mindforge/core/hud_tone.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/components/tabular_text.dart';

/// A live value in the play HUD: a caption and a number.
///
/// **Neither pressable nor focusable.** A HUD pill reports; it is not a
/// control, and giving it a button role would put three stops in a screen
/// reader's path through a running game.
///
/// **It formats nothing.** The value arrives already localized — `۰:۲۳`,
/// `1.480` — from the shell, which owns `LocaleNumbers`. A component's contract
/// is to render whatever digits it is handed without tofu, reflow or clipping.
class HudPill extends StatelessWidget {
  /// Creates a pill showing [value] under [label].
  const HudPill({
    required this.label,
    required this.value,
    this.tone = HudTone.neutral,
    super.key,
  });

  /// The already-localized caption.
  final String label;

  /// The already-localized value.
  final String value;

  /// How much attention the pill is asking for.
  final HudTone tone;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);
    final palette = _PillPalette.of(tone, colours);

    // MergeSemantics, so a screen reader says "Time, 0:23" as one thing rather
    // than reading a caption and a number as two unrelated stops.
    return MergeSemantics(
      child: PopSurface(
        fill: palette.fill,
        radius: BorderRadiusDirectional.all(shape.radiusMd),
        elevation: PopElevation.e1,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        minTarget: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: type.label.copyWith(color: palette.label)),
            // TabularText, not Text: numericHud declares tnum, but the bundled
            // Fredoka does not honour it — measured, 0:23 renders eight points
            // wider than 0:11, so a running clock would jitter every tick.
            TabularText(
              value,
              style: type.numericHud.copyWith(color: palette.value),
            ),
          ],
        ),
      ),
    );
  }
}

/// The three colour resolutions a pill can take.
@immutable
final class _PillPalette {
  const _PillPalette({
    required this.fill,
    required this.label,
    required this.value,
  });

  /// Resolves [tone] against the palette.
  ///
  /// **The alarm is `danger`, never a `game*` slot.** The colour-blind setting
  /// re-points gameplay colours, and an alarm aliased to one would change hue
  /// for exactly the players who need it most. It is also why the alarm's own
  /// text goes to `surfaceRaised` rather than staying ink: coral-on-ink is the
  /// contrast trap this resolution exists to avoid.
  factory _PillPalette.of(HudTone tone, SunburstColors colours) =>
      switch (tone) {
        HudTone.neutral => _PillPalette(
          fill: colours.surfaceRaised,
          label: colours.textSecondary,
          value: colours.textPrimary,
        ),
        HudTone.highlight => _PillPalette(
          fill: colours.accent,
          label: colours.textPrimary,
          value: colours.textPrimary,
        ),
        HudTone.alarm => _PillPalette(
          fill: colours.danger,
          label: colours.surfaceRaised,
          value: colours.surfaceRaised,
        ),
      };

  final Color fill;
  final Color label;
  final Color value;
}
