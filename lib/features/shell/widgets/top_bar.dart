import 'package:flutter/material.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_type.dart';

/// The row app.html draws above a screen: a control, a name, and one chip.
///
/// **The title is drawn and never announced.** Every screen carrying this bar
/// names itself again below it — the hero panel on game detail, the `Semantics`
/// header on play — so a bar that also announced would make a screen reader say
/// the same three words twice before reaching anything new.
///
/// Both slots are optional and both are directional: [leading] sits at the
/// start edge and [trailing] at the end, so the whole bar mirrors in `fa` and
/// `ckb` without this file knowing which way it is running.
class TopBar extends StatelessWidget {
  /// Creates the bar.
  const TopBar({required this.title, this.leading, this.trailing, super.key});

  /// The already-localized name of the screen.
  final String title;

  /// The control at the start edge — back, pause.
  final Widget? leading;

  /// The state at the end edge — the difficulty chip.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final type = SunburstType.of(context);

    return Padding(
      // app.html: `.topbar{padding:2px 20px 16px}`.
      padding: const EdgeInsetsDirectional.fromSTEB(20, 2, 20, 16),
      child: Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            // app.html: `.topbar{gap:12px}`, and game detail's back button has
            // always drawn at 14. The larger of the two, once, rather than two
            // bars that differ by two points for no reason anyone can state.
            const SizedBox(width: 14),
          ],
          Expanded(
            child: ExcludeSemantics(
              child: Text(
                title,
                // ELLIPSIS, because the trailing chip is the difficulty and a
                // long title that pushed it off the end would take the one
                // piece of state the bar carries with it. `ckb` titles run
                // longer than `en` ones at the same step.
                overflow: TextOverflow.ellipsis,
                style: type.titleBar.copyWith(color: colours.textPrimary),
              ),
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 12),
            // FLEXIBLE, not intrinsic. Ellipsing the title is only half of
            // it: at x2.0 on a 320pt phone "Klassisch" is wider than what an
            // ellipsed title leaves behind, and the row overflowed. A chip
            // given a width bound wraps to its own second line.
            Flexible(child: trailing!),
          ],
        ],
      ),
    );
  }
}
