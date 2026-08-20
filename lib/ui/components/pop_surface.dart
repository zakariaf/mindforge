import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/shared/feedback/feedback_service.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/motion/press_physics.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/dashed_ink_border.dart';

/// The smallest thing a finger is allowed to be asked to hit.
///
/// 48 logical pixels, on both axes, regardless of how small the thing looks.
/// A 24px close glyph is a 48px target with the glyph centred in it.
const double kPopMinTarget = 48;

/// How far off the page a surface sits.
///
/// Not a number — a step. Every raised surface in Sunburst Pop picks one of
/// these, and the shadow, the press travel and the press scale all follow from
/// the choice, so no component decides any of them separately.
enum PopElevation {
  /// On the page. Draws **no** shadow at all.
  ///
  /// Not "a shadow at zero offset": a zero-offset hard shadow still paints a
  /// ring of ink around the surface. Flat means nothing is drawn.
  flat,

  /// The half-step below [e1], for chips and badges.
  ///
  /// Its own step rather than a number a component types: without it
  /// `SunburstShape.eChip` is a token nothing can reach, since `restOffset` is
  /// the only place a step becomes an offset.
  chip,

  /// The lowest raised step.
  e1,

  /// The default raised step.
  e2,

  /// A lifted step, for the thing currently in play.
  e3,

  /// The highest step, for sheets and the primary action.
  e4;

  /// The hard-shadow offset this step rests at, or `null` when [flat].
  Offset? restOffset(SunburstShape shape) => switch (this) {
    PopElevation.flat => null,
    PopElevation.chip => shape.eChip,
    PopElevation.e1 => shape.e1,
    PopElevation.e2 => shape.e2,
    PopElevation.e3 => shape.e3,
    PopElevation.e4 => shape.e4,
  };

  /// How far a surface at this step shrinks while held.
  ///
  /// The e1 family is small enough that the larger scale is imperceptible on
  /// it, so the smaller surfaces shrink harder.
  double pressScale(SunburstShape shape) => switch (this) {
    PopElevation.flat ||
    PopElevation.chip ||
    PopElevation.e1 => shape.pressScaleSmall,
    PopElevation.e2 || PopElevation.e3 || PopElevation.e4 => shape.pressScale,
  };
}

/// How a surface's edge is drawn.
enum PopBorderStyle {
  /// The 3px ink edge every raised surface carries.
  solid,

  /// A dashed ink edge, for a locked or not-yet-real surface.
  dashed,

  /// No edge at all.
  ///
  /// The carve-out for a surface whose fill *is* the affordance — an answer
  /// key, a ghost button — where an ink edge would fight the colour it exists
  /// to show.
  none,
}

/// The one raised surface in Sunburst Pop.
///
/// A fill, a 3px ink edge, and one hard offset shadow with `blurRadius` and
/// `spreadRadius` at **0**. It translates toward that shadow while held, and
/// its hit area does not move while it does. Every component in the catalog is
/// this, with a different fill, radius and child.
///
/// **Its padding is `EdgeInsetsDirectional` and its radius is
/// `BorderRadiusDirectional`, by type.** Not `EdgeInsetsGeometry`: the narrower
/// type makes a physical inset a *compile error* at every call site, which is a
/// stronger guarantee than a grep over source text.
///
/// **The shadow does not mirror.** It is a light source fixed at the top-start
/// of the page — one imaginary light for the whole app — not a reading-order
/// property. A mirrored shadow would put the light behind the reader in half
/// the shipped locales and make every RTL screenshot disagree with the design
/// for no reason anyone could name.
class PopSurface extends ConsumerStatefulWidget {
  /// Creates a raised surface.
  const PopSurface({
    required this.fill,
    required this.child,
    this.radius,
    this.elevation = PopElevation.e2,
    this.borderStyle = PopBorderStyle.solid,
    this.nested = false,
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

  /// The surface's fill.
  final Color fill;

  /// What sits inside the surface.
  final Widget child;

  /// The corner radius. Defaults to the shape scale's medium corner.
  final BorderRadiusDirectional? radius;

  /// How far off the page the surface sits.
  final PopElevation elevation;

  /// How the edge is drawn.
  final PopBorderStyle borderStyle;

  /// Whether this surface is drawn **inside** another one.
  ///
  /// A nested surface takes the thinner edge: a knob inside its rail, a pill
  /// inside a card, a fill inside a track all put two borders within a few
  /// pixels of each other, and at the full width the pair reads as one smudge.
  ///
  /// It is a parameter rather than three components each building their own
  /// decoration — which is what they did before, and three of them reaching
  /// for the same token independently is the signal that it belongs here.
  final bool nested;

  /// The inset between the edge and [child].
  final EdgeInsetsDirectional padding;

  /// What a completed tap does. A `null` tap makes this not a button.
  final VoidCallback? onTap;

  /// Whether the surface is interactive.
  final bool enabled;

  /// Whether the surface is the chosen one among its siblings.
  final bool selected;

  /// The smallest the surface is allowed to be.
  ///
  /// Set to `0` when an ancestor owns the gesture and the target — a row in a
  /// list, a tile in a grid — so two nested 48px floors do not fight.
  final double minTarget;

  /// Overrides the press scale [elevation] would choose.
  final double? pressScaleOverride;

  /// The moment fired when a tap resolves.
  final Moment commitMoment;

  /// The label a screen reader announces.
  final String? semanticLabel;

  @override
  ConsumerState<PopSurface> createState() => _PopSurfaceState();
}

class _PopSurfaceState extends ConsumerState<PopSurface> {
  bool _focused = false;

  bool get _isInteractive => widget.enabled && widget.onTap != null;

  void _handleTap() {
    ref.read(feedbackServiceProvider).fire(widget.commitMoment);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final shape = SunburstShape.of(context);
    final colours = SunburstColors.of(context);
    final radius = widget.radius ?? BorderRadiusDirectional.all(shape.radiusMd);
    final geometry = PressGeometry(
      restOffset: widget.elevation.restOffset(shape),
      pressScale:
          widget.pressScaleOverride ?? widget.elevation.pressScale(shape),
    );

    final label = widget.semanticLabel;
    final painted = _PaintedSurface(
      t: 0,
      geometry: geometry,
      radius: radius,
      edgeWidth: widget.nested ? shape.borderWidthNested : shape.borderWidth,
      focused: false,
      fill: _resolveFill(colours),
      ink: _resolveInk(colours),
      shape: shape,
      borderStyle: widget.borderStyle,
      padding: widget.padding,
      elevation: widget.elevation,
      focusRing: colours.focusRing,
      gapColour: colours.surface,
      child: _content(label),
    );

    // A SURFACE WITH NOTHING TO DO BUILDS NOTHING TO DO IT WITH. Every chip,
    // badge, HUD pill and untapped card was paying for a FocusableActionDetector,
    // a GestureDetector and a PressPhysics — whose initState allocates an
    // AnimationController and a Ticker — to sit still.
    if (!_isInteractive) {
      return Semantics(
        button: widget.onTap != null,
        enabled: widget.onTap == null ? null : widget.enabled,
        selected: widget.selected ? true : null,
        label: label,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minTarget,
            minHeight: widget.minTarget,
          ),
          child: painted,
        ),
      );
    }

    return Semantics(
      // A surface with an onTap is a BUTTON whether or not it is currently
      // enabled. Gating the role on interactivity stripped it from every
      // disabled control — and since the whole catalog disables by passing
      // `onTap: null`, that ternary also dropped hasEnabledState, so a disabled
      // button announced as plain static text with no hint that it was a
      // control at all.
      button: true,
      enabled: widget.enabled,
      selected: widget.selected ? true : null,
      label: label,
      child: FocusableActionDetector(
        // Without these the catalog is focusable and DEAD to a hardware
        // keyboard, to iOS Full Keyboard Access and to Switch Control:
        // FocusableActionDetector inserts no Actions when given an empty map,
        // and Flutter supplies no default ActivateAction.
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _handleTap();
              return null;
            },
          ),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: (_) {
              _handleTap();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          child: ConstrainedBox(
            // The floor is on the GESTURE, outside the transform. The painted
            // surface moves; this box does not, so a finger that pressed the
            // edge is still inside the target when it lifts.
            constraints: BoxConstraints(
              minWidth: widget.minTarget,
              minHeight: widget.minTarget,
            ),
            child: PressPhysics(
              geometry: geometry,
              builder: (context, t, child) => _PaintedSurface(
                t: t,
                geometry: geometry,
                radius: radius,
                edgeWidth: widget.nested
                    ? shape.borderWidthNested
                    : shape.borderWidth,
                focused: _focused,
                fill: _resolveFill(colours),
                ink: _resolveInk(colours),
                shape: shape,
                borderStyle: widget.borderStyle,
                padding: widget.padding,
                elevation: widget.elevation,
                focusRing: colours.focusRing,
                gapColour: colours.surface,
                child: child!,
              ),
              child: _content(label),
            ),
          ),
        ),
      ),
    );
  }

  /// The child, with its own semantics suppressed when this surface labels it.
  ///
  /// Without the exclusion the child's `Text` merges INTO the surface's node
  /// and every component announces its label twice — "Play, Play, button".
  Widget _content(String? label) => Center(
    widthFactor: 1,
    heightFactor: 1,
    child: label == null ? widget.child : ExcludeSemantics(child: widget.child),
  );

  /// The disabled fill, resolved **inside the palette**.
  ///
  /// Never an `Opacity` over the enabled colour: a translucent surface picks up
  /// whatever is behind it, so the same disabled button reads differently on
  /// cream and on a coloured card, and its ink edge goes grey-blue rather than
  /// grey. The exception is a borderless surface, whose fill IS the affordance
  /// — an answer key stays its own colour when it is not tappable, or the
  /// player cannot tell which key they missed.
  Color _resolveFill(SunburstColors colours) {
    if (widget.enabled) return widget.fill;
    if (widget.borderStyle == PopBorderStyle.none) return widget.fill;

    return colours.surfaceSunk;
  }

  /// The ink for both the edge and the shadow.
  ///
  /// One resolution, not two: the edge and the shadow it casts are the same
  /// ink, and a disabled surface whose shadow stayed full-strength would read
  /// as raised while looking unavailable.
  Color _resolveInk(SunburstColors colours) =>
      widget.enabled ? colours.border : colours.borderDisabled;
}

/// The painted half of a [PopSurface], rebuilt on every press frame.
class _PaintedSurface extends StatelessWidget {
  const _PaintedSurface({
    required this.t,
    required this.geometry,
    required this.radius,
    required this.edgeWidth,
    required this.focused,
    required this.fill,
    required this.ink,

    required this.shape,
    required this.borderStyle,
    required this.padding,
    required this.elevation,
    required this.focusRing,
    required this.gapColour,
    required this.child,
  });

  final double t;
  final PressGeometry geometry;
  final BorderRadiusDirectional radius;

  /// How thick the ink edge is: the primary width, or the nested one.
  final double edgeWidth;
  final bool focused;
  final Color fill;

  /// The ink the edge and the shadow are drawn in.
  final Color ink;

  final SunburstShape shape;
  final PopBorderStyle borderStyle;
  final EdgeInsetsDirectional padding;
  final PopElevation elevation;
  final Color focusRing;
  final Color gapColour;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final resolved = radius.resolve(Directionality.of(context));
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: resolved,
        border: borderStyle == PopBorderStyle.solid
            ? Border.all(color: ink, width: edgeWidth)
            : null,
        boxShadow: _shadow(),
      ),
      child: Padding(padding: padding, child: child),
    );

    // Each CustomPaint gets a RepaintBoundary: the dashed edge and the focus
    // ring repaint on their own schedule, and without a boundary every one of
    // those repaints dirties the whole surface above them.
    final edged = borderStyle == PopBorderStyle.dashed
        ? RepaintBoundary(
            child: CustomPaint(
              foregroundPainter: DashedInkBorder(
                radius: resolved,
                colour: ink,
                strokeWidth: edgeWidth,
                dashOn: shape.dashOn,
                dashOff: shape.dashOff,
              ),
              child: surface,
            ),
          )
        : surface;

    final ringed = focused
        ? RepaintBoundary(
            child: CustomPaint(
              foregroundPainter: _FocusRingPainter(
                radius: resolved,
                ring: focusRing,
                gap: gapColour,
                gapWidth: shape.focusGap,
                ringWidth: shape.focusWidth,
              ),
              child: edged,
            ),
          )
        : edged;

    // Transform.translate, not a Positioned or a Padding: the surface moves
    // WITHOUT changing its layout size, so nothing around it reflows while a
    // finger is down.
    return Transform.translate(
      offset: geometry.offsetAt(t),
      child: Transform.scale(scale: geometry.scaleAt(t), child: ringed),
    );
  }

  /// The hard shadow, at rest and while held.
  ///
  /// `blurRadius` and `spreadRadius` are 0 in every branch. That is the whole
  /// construction: a hard offset shadow is a second shape in ink, not a blur.
  List<BoxShadow>? _shadow() {
    final rest = elevation.restOffset(shape);
    if (rest == null) return null;

    // A held surface keeps a 1px shadow rather than losing it. Dropping to zero
    // reads as the surface vanishing rather than as it being pushed into the
    // page.
    final offset = Offset.lerp(rest, SunburstShape.pressedShadow, t)!;

    // shape.shadow is the ONE BoxShadow factory in the app: it is what pins
    // blurRadius and spreadRadius to 0, so a hard offset shadow cannot be
    // built anywhere as a soft one by accident.
    return shape.shadow(offset, ink);
  }
}

/// Paints the focus ring outside the surface's own box.
///
/// A stroke, not a `BoxShadow` with a spread: the ring has to sit clear of the
/// surface with a gap of page showing between, and a spread shadow is a
/// silhouette rather than an outline.
class _FocusRingPainter extends CustomPainter {
  _FocusRingPainter({
    required this.radius,
    required this.ring,
    required this.gap,
    required this.gapWidth,
    required this.ringWidth,
  }) : _gapPaint = Paint()
         ..color = gap
         ..style = PaintingStyle.stroke
         ..strokeWidth = gapWidth,
       _ringPaint = Paint()
         ..color = ring
         ..style = PaintingStyle.stroke
         ..strokeWidth = ringWidth;

  final BorderRadius radius;
  final Color ring;
  final Color gap;
  final double gapWidth;
  final double ringWidth;

  /// Built once in the constructor, never inside [paint].
  ///
  /// The ring repaints on every frame a focused surface animates; allocating a
  /// Paint there is the allocation `check_painter_hygiene.sh` exists to catch.
  final Paint _gapPaint;
  final Paint _ringPaint;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;

    canvas
      ..drawRRect(radius.toRRect(box).inflate(gapWidth / 2), _gapPaint)
      ..drawRRect(
        radius.toRRect(box).inflate(gapWidth + ringWidth / 2),
        _ringPaint,
      );
  }

  @override
  bool shouldRepaint(_FocusRingPainter old) =>
      old.radius != radius ||
      old.ring != ring ||
      old.gap != gap ||
      old.gapWidth != gapWidth ||
      old.ringWidth != ringWidth;
}
