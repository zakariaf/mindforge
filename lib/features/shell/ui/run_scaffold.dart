import 'package:flutter/material.dart';
import 'package:mindforge/theme/sunburst_colors.dart';

/// The surface every screen OUTSIDE the tab shell is drawn on.
///
/// **Four screens had none and rendered on black with yellow-underlined text.**
/// Game detail, countdown, play and results sit outside
/// `StatefulShellRoute`, so they never inherited `NavShell`'s `Scaffold` — and
/// without a `Material` ancestor Flutter paints every `Text` with the debug
/// double-underline, on whatever the window's own background is. Caught on the
/// canonical simulator; no widget test would have, because a test harness
/// supplies its own `MaterialApp` chrome.
///
/// It carries no app bar and no bottom nav on purpose: a player who has chosen
/// a game has one way forward and one way back, and a tab bar there is a third.
class RunScaffold extends StatelessWidget {
  /// Creates the surface around [child].
  const RunScaffold({required this.child, super.key});

  /// The screen.
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SunburstColors.of(context).surface,
    body: child,
  );
}
