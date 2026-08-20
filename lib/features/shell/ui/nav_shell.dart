import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/ui/components/pop_bottom_nav.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// The three-branch shell that owns the bottom nav.
///
/// **`StatefulShellRoute.indexedStack` keeps every branch alive**, which is
/// what preserves each tab's scroll position and navigation stack across a
/// switch. A hand-rolled shell that rebuilt the branch would lose both, and the
/// loss is invisible until someone scrolls Home, checks Stats and comes back.
///
/// The nav is a `Row` of directional children, so mirroring is free and the
/// branch INDEX never moves: `goBranch(0)` is Play in every language, while
/// Play paints leftmost under `en` and rightmost under `fa`.
class NavShell extends StatelessWidget {
  /// Creates the shell around [shell].
  const NavShell({required this.shell, super.key});

  /// The branch navigator this shell is wrapping.
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colours.surface,
      body: shell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: PopBottomNav(
          selectedIndex: shell.currentIndex,
          // `goBranch` rather than `context.go(location)`: it restores the
          // branch's own stack instead of pushing a fresh one, which is the
          // whole reason the branches are stateful.
          onSelected: (index) => shell.goBranch(
            index,
            // Tapping the current tab returns it to its root, which is what
            // every iOS tab bar does and what a player expects after drilling
            // into a game.
            initialLocation: index == shell.currentIndex,
          ),
          items: <PopNavItem>[
            PopNavItem(glyph: SunburstGlyph.navPlay, label: l10n.navPlay),
            PopNavItem(glyph: SunburstGlyph.navStats, label: l10n.navStats),
            PopNavItem(
              glyph: SunburstGlyph.navSettings,
              label: l10n.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
