import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

/// A two-state switch whose printed word is its non-colour channel.
///
/// The track turns green when it is on, and it also **says so**. That word is
/// what makes the control readable to a player who cannot tell the green track
/// from the cream one, and it is why the track sizes to its own label rather
/// than to a number transcribed from an English mockup: `ON` and `OFF` fit 66
/// points; `روشن` and `خاموش` do not, and a control that cannot show its own
/// state word in two of the four shipped locales is broken in those locales.
class PopToggle extends StatelessWidget {
  /// Creates a switch that is [value].
  const PopToggle({
    required this.value,
    required this.onLabel,
    required this.offLabel,
    required this.semanticLabel,
    required this.onChanged,
    super.key,
  });

  /// Whether the switch is on.
  final bool value;

  /// The already-localized word shown when it is on.
  final String onLabel;

  /// The already-localized word shown when it is off.
  final String offLabel;

  /// The already-localized label a screen reader announces.
  final String semanticLabel;

  /// Called with the new value. `null` disables the switch.
  final ValueChanged<bool>? onChanged;

  /// The knob's diameter.
  /// The knob's diameter.
  ///
  /// Package-visible so `_Knob` can size itself to it.
  static const double knobSize = 26;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);
    final changed = onChanged;

    // NO ExcludeSemantics around the surface. It stripped the tap action the
    // GestureDetector inside contributes, so a screen-reader user could focus
    // "Sound, on", double-tap, and nothing happened — every Settings toggle
    // was unreachable. The surface carries the label and the role; this node
    // adds only the toggled state.
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      child: Builder(
        builder: (context) => PopSurface(
          fill: value ? colours.success : colours.surfaceSunk,
          radius: BorderRadiusDirectional.all(shape.radiusPill),
          elevation: PopElevation.flat,
          onTap: changed == null ? null : () => changed(!value),
          semanticLabel: semanticLabel,
          padding: const EdgeInsetsDirectional.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            // The knob leads when the switch is OFF and trails when it is ON,
            // in READING order — the Row is directional, so in Persian the
            // on-knob sits at the left, which is where "further along" is.
            children: value
                ? <Widget>[
                    _Word(label: onLabel, type: type, colours: colours),
                    _Knob(colours: colours),
                  ]
                : <Widget>[
                    _Knob(colours: colours),
                    _Word(label: offLabel, type: type, colours: colours),
                  ],
          ),
        ),
      ),
    );
  }
}

class _Knob extends StatelessWidget {
  const _Knob({required this.colours});

  final SunburstColors colours;

  @override
  Widget build(BuildContext context) => PopSurface(
    fill: colours.surfaceRaised,
    radius: BorderRadiusDirectional.all(
      SunburstShape.of(context).radiusPill,
    ),
    elevation: PopElevation.flat,
    // Inside the track, so the thinner edge — otherwise the knob's border and
    // the track's read as one thick smudge.
    nested: true,
    minTarget: 0,
    child: const SizedBox.square(dimension: PopToggle.knobSize),
  );
}

class _Word extends StatelessWidget {
  const _Word({
    required this.label,
    required this.type,
    required this.colours,
  });

  final String label;
  final SunburstType type;
  final SunburstColors colours;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
    child: Text(
      label,
      style: type.label.copyWith(color: colours.textPrimary),
    ),
  );
}
