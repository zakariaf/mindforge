// PopSurface — the ONE primitive every Sunburst Pop component composes: the 3px
// ink border, the hard offset shadow, the focus ring and the CHROME of the
// press. The press controller itself — the durTap tween, animateTo-not-forward
// interruption, the reduce-motion split and the one commit haptic — belongs to
// `PressPhysics` (sunburst-motion-and-haptics), which this file composes. There
// is exactly one press implementation in MindForge.
//
// `dashOn` and `dashOff` are derived slots listed in SKILL.md — requests to
// sunburst-tokens, never literals here. `pressScale` and `pressScaleSmall` are
// shipped tokens; `PopElevation.pressScale(shape)` is the only thing that picks
// between them.

import 'package:flutter/material.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/motion/press_physics.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_motion.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

import 'dashed_ink_border.dart';

/// The house tap-target floor (system.html §11), measured on the fill box.
const double kPopMinTarget = 48;

/// The five hard-shadow steps. Offsets are instance fields on `SunburstShape`,
/// so a step resolves against the theme rather than carrying a const of its own.
enum PopElevation {
  flat, e1, e2, e3, e4;

  /// Null at [flat]: the absence of a shadow, not a zero-offset one.
  Offset? restOffset(SunburstShape shape) => switch (this) {
    PopElevation.flat => null,
    PopElevation.e1 => shape.e1,
    PopElevation.e2 => shape.e2,
    PopElevation.e3 => shape.e3,
    PopElevation.e4 => shape.e4,
  };

  /// 0.97 on the small e1 surfaces, 0.98 above — app.html applies both.
  double pressScale(SunburstShape shape) =>
      this == PopElevation.e1 ? shape.pressScaleSmall : shape.pressScale;
}

/// Solid is the rule. `dashed` is the locked card and locked badge; `none` is
/// the ghost button — the one sanctioned break in the outline rule.
enum PopBorderStyle { solid, dashed, none }

/// A raised Sunburst surface: fill + 3px ink border + hard offset shadow, which
/// presses down toward its own shadow when tapped.
class PopSurface extends StatefulWidget {
  const PopSurface({
    required this.fill,
    required this.radius,
    required this.child,
    this.elevation = PopElevation.e2,
    this.borderStyle = PopBorderStyle.solid,
    this.padding = EdgeInsetsDirectional.zero,
    this.onTap,
    this.enabled = true,
    this.selected = false,
    this.minTarget = kPopMinTarget,
    this.pressScaleOverride,
    this.commitMoment = Moment.buttonCommit,
    this.semanticLabel,
    super.key,
  });

  /// A semantic slot — never a primitive and never a literal.
  final Color fill;
  /// `shape.radiusSm | radiusMd | radiusLg | radiusXl | radiusPill`.
  final Radius radius;
  final Widget child;
  final PopElevation elevation;
  final PopBorderStyle borderStyle;
  final EdgeInsetsDirectional padding;
  /// Null onTap means "not a control": no press, no focus, no button semantics.
  final VoidCallback? onTap;
  final bool enabled, selected;
  /// 0 only when a larger ancestor owns the gesture — the 62px settings row
  /// around `PopToggle`. Never shrink a target to match the artwork.
  final double minTarget;
  /// Ghost only: it keeps the e2 shrink even though it sits at e1.
  final double? pressScaleOverride;
  /// The moment `FeedbackService` fires once on the commit frame. A board tile
  /// passes its own row (`Moment.tileFound`); the catalog of moments belongs to
  /// `sunburst-motion-and-haptics`.
  final Moment commitMoment;
  /// When set, the surface speaks this label and its children are excluded.
  final String? semanticLabel;

  @override
  State<PopSurface> createState() => _PopSurfaceState();
}

class _PopSurfaceState extends State<PopSurface> {
  bool _focused = false;

  bool get _interactive => widget.onTap != null && widget.enabled;

  @override
  Widget build(BuildContext context) {
    final colors = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final motion = SunburstMotion.of(context);
    final duration = motion.resolve(context, motion.durTap);
    final drawsBorder = widget.borderStyle != PopBorderStyle.none;

    // Disabled changes shape inside the palette: cream-2 fill, ink-3 edge, the
    // shadow one step shallower and in ink-3 (`.btn[disabled]` is 3px 3px 0
    // ink-3 — an e1 shadow, never no shadow). Never a Material grey, never
    // Opacity. Ghost has no fill or edge, so it disables by label colour alone.
    //
    // The `!drawsBorder` guard is what keeps a Stroop answer key legal: a
    // resolved key stops taking taps by dropping `onTap`, never by
    // `enabled: false`, because the surfaceSunk substitution would erase the
    // hue that IS the answer. `sunburst-game-surfaces` rule 3 owns that.
    final fill = widget.enabled || !drawsBorder ? widget.fill : colors.surfaceSunk;
    final ink = widget.enabled ? colors.border : colors.borderDisabled;
    final restedAt = widget.elevation.restOffset(shape);
    final rest = widget.enabled || restedAt == null ? restedAt : shape.e1;
    // Ghost draws no shadow, but it still sits at e1, so its travel DERIVES to
    // the 2px system.html states for `.btn--ghost:active` instead of being
    // typed. Null here means "paints no shadow", never "a zero-offset one".
    final Offset? shadowRest = drawsBorder ? rest : null;

    // Paints one frame of the surface. `press.shadow` arrives already
    // interpolated between rest and (1,1) by PressPhysics — this layer never
    // owns a controller, a duration or a curve of its own.
    Widget chrome(BuildContext context, PressGeometry press, Widget? child) {
      // shape.shadow() is the only BoxShadow factory in the app: blur/spread 0.
      Widget surface = AnimatedContainer(
        duration: duration,
        curve: motion.easeOut, // fill crosses are colour: easeOut, never easePop
        padding: widget.padding,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.all(widget.radius),
          border: widget.borderStyle == PopBorderStyle.solid
              ? Border.all(color: ink, width: shape.borderWidth)
              : null,
          boxShadow:
              shadowRest == null ? null : shape.shadow(press.shadow, ink),
        ),
        child: child,
      );

      if (widget.borderStyle == PopBorderStyle.dashed) {
        // BorderSide has no dash: the locked edge is stroked from PathMetrics.
        surface = CustomPaint(
          foregroundPainter: DashedInkBorder(
            radius: widget.radius,
            ink: ink,
            width: shape.borderWidth,
            on: shape.dashOn,
            off: shape.dashOff,
          ),
          child: Padding(padding: EdgeInsets.all(shape.borderWidth), child: surface),
        );
      }

      // The ring is painted OUTSIDE the border as a stroke, never a spread
      // shadow, and it travels with the press — it is inside the transform.
      return CustomPaint(
        painter: _focused
            ? _FocusRingPainter(
                radius: widget.radius,
                gapColour: colors.surface,
                ringColour: colors.focusRing,
                gap: shape.focusGap,
                ring: shape.focusWidth,
              )
            : null,
        child: surface,
      );
    }

    return Semantics(
      container: true,
      button: widget.onTap != null,
      enabled: widget.enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: FocusableActionDetector(
        enabled: _interactive,
        mouseCursor: _interactive ? SystemMouseCursors.click : MouseCursor.defer,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        // PressPhysics (sunburst-motion-and-haptics) owns the controller, the
        // interruption rules, the reduce-motion split and the single commit
        // haptic. There is one press implementation in the app and this is
        // where it is composed — PopSurface only paints what it is handed.
        // Gesture and the ≥48px target sit OUTSIDE the transform inside it:
        // the paint moves, the hit area never does.
        child: MergeSemantics(
          child: PressPhysics(
            restShadow: shadowRest ?? Offset.zero,
            pressedShadow: shadowRest == null
                ? Offset.zero
                : SunburstShape.pressedShadow,
            travel: rest == null ? 0 : shape.pressTranslate(rest).dx,
            scale: widget.pressScaleOverride ??
                widget.elevation.pressScale(shape),
            minTarget: widget.minTarget,
            commitMoment: widget.commitMoment,
            onPressed: _interactive ? widget.onTap : null,
            builder: chrome,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// 4px focusRing outside a 3px surface gap, drawn beyond the layout box so the
/// ring adds no size — like the shadow. The cream gap holds grape-pop at 4.1:1
/// over a sunshine fill instead of 2.8:1 measured directly.
class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter({
    required this.radius,
    required this.gapColour,
    required this.ringColour,
    required this.gap,
    required this.ring,
  });

  final Radius radius;
  final Color gapColour, ringColour;
  final double gap, ring;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    for (final (out, width, colour) in <(double, double, Color)>[
      (gap / 2, gap, gapColour),
      (gap + ring / 2, ring, ringColour),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(box.inflate(out), Radius.circular(radius.x + out)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = colour,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FocusRingPainter old) =>
      (old.radius, old.gapColour, old.ringColour, old.gap, old.ring) !=
      (radius, gapColour, ringColour, gap, ring);
}
