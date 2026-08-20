import 'package:flutter/material.dart';
import 'package:mindforge/features/shell/widgets/halftone_dots.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

/// The coloured region behind a screen's title.
///
/// A fill, an optional ray sweep, a dot lattice, and a 3px ink bottom border —
/// and no other border. `app.html`:
/// `.hdr{border-bottom:var(--bw) solid var(--border)}`.
///
/// **The rays and the dots do not mirror.** They are a light source and a
/// texture, one imaginary light for the whole app, exactly like the hard offset
/// shadow. The CONTENT does mirror, because it is text and controls, and that
/// falls out of `EdgeInsetsDirectional` without a conditional.
///
/// **[rays] is required and nullable rather than defaulted.** The four headers
/// in the app deliberately differ — sunshine at .5 on Home, none on Stats,
/// grape at .3 on Settings, leaf at .55 on Results — and a default would have
/// made "all three headers glow identically" the easy mistake to ship. Passing
/// `null` is how a screen says it wants no sweep, and it costs no frame.
///
/// It exposes no semantics of its own: the decoration layers are excluded, so a
/// screen reader walks the content and never announces a texture.
class RayHeader extends StatelessWidget {
  /// Creates a header filled with [fill] around [child].
  const RayHeader({
    required this.fill,
    required this.rays,
    required this.child,
    this.padding = contentInset,
    super.key,
  });

  /// The header's background.
  final Color fill;

  /// The ray colour with its alpha already applied, or `null` for no sweep.
  final Color? rays;

  /// The title row and anything beside it.
  final Widget child;

  /// The content inset.
  final EdgeInsetsDirectional padding;

  /// The default content inset. `app.html`: `.hdr > .in{padding:6px 20px 22px}`.
  static const EdgeInsetsDirectional contentInset =
      EdgeInsetsDirectional.fromSTEB(20, 6, 20, 22);

  /// The inset the two tab headers use.
  ///
  /// `app.html`: `.stats-hdr .in` and `.set-hdr .in` both override to
  /// `padding-top:10px;padding-bottom:18px`. A tab header carries a kicker and
  /// a title and no wordmark row, so it starts lower and ends tighter.
  static const EdgeInsetsDirectional tabInset = EdgeInsetsDirectional.fromSTEB(
    20,
    10,
    20,
    18,
  );

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        border: Border(
          bottom: BorderSide(color: colours.border, width: shape.borderWidth),
        ),
      ),
      child: ClipRect(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: HalftonePainter(
                      HalftoneScene(ink: colours.headerDots, ray: rays),
                    ),
                  ),
                ),
              ),
            ),
            // SafeArea for the top inset only: a header is the thing under the
            // status bar, and the bottom is the nav bar's problem.
            SafeArea(
              bottom: false,
              child: Padding(padding: padding, child: child),
            ),
          ],
        ),
      ),
    );
  }
}
