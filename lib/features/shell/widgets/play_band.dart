import 'package:flutter/material.dart';
import 'package:mindforge/features/shell/widgets/ray_header.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';

/// The coloured strip above a board.
///
/// **It is the shell's, and it takes an accent rather than a colour.** Two
/// games hand it two accents and get identical geometry — same inset, same
/// border, same safe area — which is the engine claim this whole epic exists to
/// make. A band that took a raw `Color` would let a game contribute a fill the
/// palette never approved.
///
/// It IS a [RayHeader] with a different inset. The two were written out
/// separately and were the same fill, the same 3px ink bottom border, the same
/// clipped texture stack and the same top-only safe area — and a header that
/// gained a fix the band did not is exactly what a duplicate costs.
///
/// The ray sweep and the dot lattice sit at full strength here because, as
/// `app.html` says of this strip, only ink-outlined objects are drawn on it and
/// never small text — so neither layer is standing between a reader and a
/// contrast floor.
class PlayBand extends StatelessWidget {
  /// Creates the band for [accent] around [child].
  const PlayBand({required this.accent, required this.child, super.key});

  /// Whose game this is.
  final GameAccent accent;

  /// The HUD row.
  final Widget child;

  /// The band's content inset. `app.html`: `.playband{padding-top:2px}` over
  /// the shared 20pt gutter.
  static const EdgeInsetsDirectional contentInset =
      EdgeInsetsDirectional.fromSTEB(20, 8, 20, 12);

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);

    return RayHeader(
      fill: colours.accentFor(accent, GameColourRole.base),
      rays: colours.bandRayFor(accent),
      padding: contentInset,
      child: child,
    );
  }
}
