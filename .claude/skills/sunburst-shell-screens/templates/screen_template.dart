// Skeleton for a NEW shell screen (lib/features/<feature>/presentation/).
// Copy, rename, delete every TODO. If you are adding a GAME, this is the wrong
// file — a game adds no shell screen at all; see references/shell-game-boundary.md.
//
// Pre-wired: cream background + SafeArea content, the 20/16 rhythm, the one
// Semantics header, entry focus, and the large-text escape hatch. Everything a
// reviewer would otherwise have to ask about.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/sunburst_theme.dart';
import '../../../ui/components/pop_surface.dart';
import '../../shell/widgets/ray_header.dart';
import '../application/example_notifier.dart'; // TODO: rename

/// TODO: one sentence saying what this screen is FOR, not what it contains.
class ExampleScreen extends ConsumerStatefulWidget {
  const ExampleScreen({super.key});

  @override
  ConsumerState<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends ConsumerState<ExampleScreen> {
  // Focus on entry lands on the screen's h1, not on its first control, so the
  // screen reader announces where you are before what you can do (rule 9).
  final _headingFocus = FocusNode(debugLabel: 'ExampleScreen.heading');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _headingFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _headingFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SunburstColors.of(context);
    final type = SunburstType.of(context);
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(exampleNotifierProvider); // one Notifier, ready to render

    return Scaffold(
      // Cream behind the status-bar strip. Content sits inside SafeArea and the
      // coloured header starts BELOW the top inset — only CountdownScreen bleeds
      // edge to edge (rule 6). Delete `bottom: false` if this screen is not a
      // nav branch, so its own content clears the home indicator.
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // TODO: pick ONE — a RayHeader (Home/Stats/Settings/Results) or a top
            // bar (game detail / play). Not both. Header inner padding is
            // 10/20/18 for Stats and Settings, 6/20/22 for Home, 10/20/26 for Results.
            RayHeader(
              fill: colors.accentAlt, // TODO: this screen's header fill
              rayFill: colors.focusRing, // grape-pop, as `.set-hdr` uses
              rayOpacity: 0.3, // TODO: re-measure if the label is cream (5.0:1 floor)
              dotOpacity: 0.16,
              padding: const EdgeInsetsDirectional.fromSTEB(
                SunburstShape.gutter, 10, SunburstShape.gutter, 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.exampleKicker, // TODO
                    // TODO: textInvert on grape/ink, textPrimary on sunshine/
                    // turquoise/leaf — a saturated fill never takes ink-2.
                    style: type.greeting.copyWith(color: colors.textInvert),
                  ),
                  // Exactly ONE header per screen. Never a second `header: true`.
                  Semantics(
                    header: true,
                    child: Focus(
                      focusNode: _headingFocus,
                      child: Text(
                        l10n.exampleTitle, // TODO
                        style: type.displayL.copyWith(color: colors.textInvert),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SafeArea(
                top: false, // the header already sat under the top inset
                child: ListView(
                  // Gutter 20 horizontally on every screen, without exception.
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    SunburstShape.gutter,
                    SunburstShape.cardGap,
                    SunburstShape.gutter,
                    SunburstShape.cardGap,
                  ),
                  children: [
                    // Stacked cards are separated by 16 (`cardGap`). Never 12,
                    // never 24. No FittedBox, no ellipsis, no clamped textScaler —
                    // this list scrolls so large text has somewhere to go (rule 11).
                    _ExampleSection(state: state),
                    const SizedBox(height: SunburstShape.cardGap),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // No bottomNavigationBar here: the 90pt PopBottomNav belongs to the
      // StatefulShellRoute (rule 10). Home, Stats and Settings get it for free
      // by being branches; every other screen must not have one.
    );
  }
}

/// TODO: one small const widget CLASS per section. Never a `Widget _buildX()`.
class _ExampleSection extends StatelessWidget {
  const _ExampleSection({required this.state});

  final ExampleState state;

  @override
  Widget build(BuildContext context) {
    final colors = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    return PopSurface(
      fill: colors.surfaceRaised,
      elevation: PopElevation.e2,
      radius: shape.radiusLg,
      // Card inner padding is 15–17 across the whole app; `cardPadding` (16) is
      // the default, and 15 or 17 only where app.html measures one.
      padding: const EdgeInsetsDirectional.all(SunburstShape.cardPadding),
      child: Text(state.label, style: SunburstType.of(context).body),
    );
  }
}
