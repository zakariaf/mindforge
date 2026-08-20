import 'package:flutter/material.dart';
import 'package:mindforge/features/shell/widgets/halftone_dots.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

/// The coloured region behind a screen's title.
///
/// A fill, a ray sweep, a dot lattice, and a 3px ink bottom border — and no
/// other border. `app.html`: `.hdr{border-bottom:var(--bw) solid var(--border)}`.
///
/// **The rays and the dots do not mirror.** They are a light source and a
/// texture, one imaginary light for the whole app, exactly like the hard offset
/// shadow. The CONTENT does mirror, because it is text and controls, and that
/// falls out of `EdgeInsetsDirectional` without a conditional.
///
/// It exposes no semantics of its own: the decoration layers are excluded, so a
/// screen reader walks the content and never announces a texture.
class RayHeader extends StatelessWidget {
  /// Creates a header filled with [fill] around [child].
  const RayHeader({
    required this.fill,
    required this.child,
    this.rayColour,
    super.key,
  });

  /// The header's background.
  final Color fill;

  /// The ray colour, defaulting to the deep sunshine the design uses.
  final Color? rayColour;

  /// The title row and anything beside it.
  final Widget child;

  /// The content inset. `app.html`: `.hdr > .in{padding:6px 20px 22px}`.
  static const EdgeInsetsDirectional contentInset =
      EdgeInsetsDirectional.fromSTEB(20, 6, 20, 22);

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
                      HalftoneScene(
                        ink: colours.border,
                        ray: rayColour ?? colours.accentDeep,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // SafeArea for the top inset only: a header is the thing under the
            // status bar, and the bottom is the nav bar's problem.
            SafeArea(
              bottom: false,
              child: Padding(padding: contentInset, child: child),
            ),
          ],
        ),
      ),
    );
  }
}
