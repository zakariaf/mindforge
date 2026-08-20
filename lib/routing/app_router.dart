import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/features/shell/ui/nav_shell.dart';
import 'package:mindforge/features/shell/ui/not_found_screen.dart';
import 'package:mindforge/routing/routes.dart';

/// The app's one router.
///
/// **It is not a function of the locale.** `routerProvider` reads no locale
/// provider, so switching language does not rebuild it — a router that watched
/// the locale would tear down the branch stack on every switch, losing the
/// player's place and silently making the Settings screen's "changing language
/// does not restart the app" claim false.
///
/// Three branches in a `StatefulShellRoute.indexedStack`, which is what keeps
/// each tab's scroll position and navigation stack alive across a switch. A
/// hand-rolled shell that rebuilt the branch would lose both.
/// Where the app opens.
///
/// A provider rather than a constant so a test can cold-start at any location —
/// which is the only way to exercise a deep link, since `go()` from a live
/// shell keeps the branch it is already in.
final Provider<String> initialLocationProvider = Provider<String>(
  (ref) => Routes.home,
);

/// The app's router, built once.
final Provider<GoRouter> routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: ref.watch(initialLocationProvider),
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => NavShell(shell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const _HomePlaceholder(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.stats,
                builder: (context, state) => const _StatsPlaceholder(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const _SettingsPlaceholder(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Home, until T08.5 replaces it.
class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

/// Stats, until T08.9 replaces it.
class _StatsPlaceholder extends StatelessWidget {
  const _StatsPlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

/// Settings, until T08.9 replaces it.
class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
