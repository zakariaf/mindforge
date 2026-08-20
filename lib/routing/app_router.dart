import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/features/countdown/ui/countdown_screen.dart';
import 'package:mindforge/features/game_detail/ui/game_detail_screen.dart';
import 'package:mindforge/features/home/ui/home_screen.dart';
import 'package:mindforge/features/play/ui/play_scaffold.dart';
import 'package:mindforge/features/results/ui/results_screen.dart';
import 'package:mindforge/features/settings/ui/settings_screen.dart';
import 'package:mindforge/features/shell/ui/nav_shell.dart';
import 'package:mindforge/features/shell/ui/not_found_screen.dart';
import 'package:mindforge/features/shell/ui/run_scaffold.dart';
import 'package:mindforge/features/stats/ui/stats_screen.dart';
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
///
/// **It honours the platform's initial route.** iOS hands one over for a
/// Universal Link, a Handoff continuation, a shortcut, or `flutter run
/// --route=`; an app that ignores it drops the player at Home and gives no sign
/// that it was asked for anywhere else. It defaults to `/`, which is
/// [Routes.home], so the ordinary launch is unchanged.
///
/// An unreadable one is not handled here. `errorBuilder` already renders the
/// not-found screen for a location the router cannot match, and duplicating
/// that judgement would put two answers in the app for one question.
final Provider<String> initialLocationProvider = Provider<String>((ref) {
  final requested = WidgetsBinding.instance.platformDispatcher.defaultRouteName;

  return requested.isEmpty ? Routes.home : requested;
});

/// The app's router, built once.
final Provider<GoRouter> routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: ref.watch(initialLocationProvider),
    errorBuilder: (context, state) =>
        const RunScaffold(child: NotFoundScreen()),
    routes: <RouteBase>[
      // OUTSIDE the shell, deliberately: game detail, countdown, play and
      // results carry no bottom nav. A player mid-run has one way out and it is
      // the pause sheet, not a tab bar.
      GoRoute(
        path: '/game/:${Routes.gameIdParam}',
        builder: (context, state) => RunScaffold(
          child: GameDetailScreen(
            gameId: GameId(state.pathParameters[Routes.gameIdParam]!),
          ),
        ),
        routes: <RouteBase>[
          GoRoute(
            path: 'countdown',
            builder: (context, state) => _runScreen(
              state,
              (config) => CountdownScreen(config: config),
            ),
          ),
          GoRoute(
            path: 'play',
            builder: (context, state) =>
                _runScreen(state, (config) => PlayScaffold(config: config)),
          ),
          GoRoute(
            path: 'results',
            builder: (context, state) =>
                _runScreen(state, (config) => ResultsScreen(config: config)),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => NavShell(shell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.stats,
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Rebuilds a config from the route, or sends the player back.
///
/// A hand-edited or stale deep link is a thing people produce; it renders the
/// not-found screen rather than throwing, which is what `Routes.configFrom`
/// returning null is for.
Widget _runScreen(
  GoRouterState state,
  Widget Function(RunConfig config) build,
) {
  final config = Routes.configFrom(
    gameId: state.pathParameters[Routes.gameIdParam],
    difficulty: state.uri.queryParameters[Routes.difficultyParam],
    seed: state.uri.queryParameters[Routes.seedParam],
  );

  // The RunScaffold goes here rather than at each of the three call sites:
  // the not-found branch needs it too, and a screen that forgot it renders on
  // black with yellow-underlined text.
  return RunScaffold(
    child: config == null ? const NotFoundScreen() : build(config),
  );
}
