import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/sunburst_colors.dart';

import 'harness.dart';
import 'locale_cases.dart';

/// The component tier of the one app harness.
///
/// **It extends `harness.dart`; it does not fork it.** `Device`, `useDevice`
/// and `pumpLocalized` come from there, so there is one device list, one
/// `MaterialApp` chain and one direction assertion in the repository. All of
/// E03's presets are DPR 2 — the geometry `capture-screens.sh` rendered the
/// eight reference PNGs at, and the geometry of the canonical simulator — so a
/// component golden blessed here can be laid beside either.
///
/// Two wrappers around `pumpLocalized` are sanctioned in this project: this one
/// and E08's `pumpShellApp`. A third, or either of these building its own
/// `ProviderScope` -> `MaterialApp` chain, skips the direction assertion
/// silently and is the failure mode this comment exists to prevent.
extension PopHarness on WidgetTester {
  /// Pumps [child] centred on the app's own surface, in [localeCase]'s locale.
  ///
  /// There is deliberately no direction parameter. Direction arrives through
  /// `GlobalWidgetsLocalizations` from the locale, which is what makes an RTL
  /// golden honest rather than a `Directionality` wrapper over English text.
  Future<void> pumpPopComponent(
    Widget child, {
    Device device = Device.reference390,
    LocaleCase? localeCase,
    TextScaler textScaler = TextScaler.noScaling,
    bool boldText = false,
  }) async {
    useDevice(this, device);

    await pumpLocalized(
      _ComponentStage(child: child),
      localeCase ?? LocaleCase.all.first,
      textScaler: textScaler,
      boldText: boldText,
    );
  }
}

/// The surface a component is pumped onto.
///
/// A `Scaffold` on the app's own `surface`, not the default white: a component
/// whose fill matches the page reads as borderless against white and correct
/// against cream, and the golden should show which.
class _ComponentStage extends StatelessWidget {
  const _ComponentStage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SunburstColors.of(context).surface,
    body: Center(child: child),
  );
}

/// The path of a golden for [name] under [localeCase]'s language.
///
/// One naming function, so no test hand-splices a path and no locale directory
/// is invented twice with two spellings.
String popGolden(String name, LocaleCase localeCase) =>
    'goldens/${localeCase.tag}/$name.png';

/// The visual states a component is goldened in.
///
/// Not every component has every state — a `PopCard` is never `selected` — so
/// each component's matrix names the subset that applies to it, exhaustively
/// and without a `default:` clause.
enum PopComponentState {
  /// Untouched.
  rest,

  /// Held down.
  pressed,

  /// Not interactive.
  disabled,

  /// Chosen, among siblings.
  selected,

  /// Carrying keyboard focus.
  focused;

  /// The label drawn beside this row in a state-matrix golden.
  String get label => name;
}

/// Lays a component's states out in one labelled column.
///
/// The rows are what a reviewer scans: if two states are indistinguishable in
/// this image, they are indistinguishable on the device.
Widget popStateMatrix({
  required List<PopComponentState> states,
  required Widget Function(PopComponentState state) buildState,
}) => _StateMatrix(states: states, buildState: buildState);

class _StateMatrix extends StatelessWidget {
  const _StateMatrix({required this.states, required this.buildState});

  final List<PopComponentState> states;

  /// Named `buildState` and not `build`: a field called `build` collides with
  /// `StatelessWidget.build` and does not compile.
  final Widget Function(PopComponentState state) buildState;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);

    return ColoredBox(
      color: colours.surface,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final state in states) ...[
              Text(
                state.label,
                style: TextStyle(
                  fontSize: 11,
                  color: colours.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              buildState(state),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

/// Renders [child] with all colour removed.
///
/// The greyscale lane's whole job is to catch a state that is carried by hue
/// alone: if `selected` and `rest` are the same shape in different colours,
/// they collapse here, and a player with a colour vision deficiency sees what
/// this golden shows.
class Greyscale extends StatelessWidget {
  /// Wraps [child] in a saturation-zero filter.
  const Greyscale({required this.child, super.key});

  /// The subtree to desaturate.
  final Widget child;

  /// The standard luminance-preserving desaturation matrix.
  ///
  /// Public so a test can apply it arithmetically rather than by rendering and
  /// reading pixels back: one matrix, two consumers, and no second definition
  /// of what "greyscale" means here.
  static const List<double> saturationZero = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  @override
  Widget build(BuildContext context) => ColorFiltered(
    colorFilter: const ColorFilter.matrix(saturationZero),
    child: child,
  );
}
