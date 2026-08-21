import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/shared/feedback/testing/fake_haptic_gateway.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_type.dart';

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
  /// Set [resetFirst] when re-pumping in a DIFFERENT LOCALE inside one test.
  ///
  /// Riverpod reuses the `ProviderScope` element across pumps, and swapping an
  /// override on a rebuild does not re-subscribe a stream provider — so the
  /// second pump keeps the first one's container. The chrome changes and the
  /// NUMBERS do not, which is a state the app can never be in, and it quietly
  /// passed a Schulte board test that was checking exactly those numerals.
  Future<void> pumpPopComponent(
    Widget child, {
    Device device = Device.reference390,
    LocaleCase? localeCase,
    TextScaler textScaler = TextScaler.noScaling,
    bool boldText = false,
    bool disableAnimations = false,
    FakeHapticGateway? hapticGateway,
    AppSettings settings = const AppSettings.defaults(),
    bool resetFirst = false,
  }) async {
    useDevice(this, device);

    // OPT-IN, because pumping twice is how half this suite makes a
    // transition — `isWrong` false then true — and a teardown between them
    // turns the rebuild into a fresh mount.
    if (resetFirst) await pumpWidget(const SizedBox.shrink());

    await pumpLocalized(
      _ComponentStage(child: child),
      localeCase ?? LocaleCase.all.first,
      textScaler: textScaler,
      boldText: boldText,
      disableAnimations: disableAnimations,
      hapticGateway: hapticGateway,
      settings: settings,
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
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);

    return Scaffold(
      backgroundColor: colours.surface,
      // An explicit default text style, because the theme deliberately sets no
      // textTheme: the type scale is a ThemeExtension every component reads
      // from directly, so an unstyled Text falls through to the test font and
      // a golden full of Ahem boxes matches its own baseline forever. Measured,
      // on the first component golden.
      body: DefaultTextStyle(
        style: SunburstType.of(
          context,
        ).body.copyWith(color: colours.textPrimary),
        child: Center(child: child),
      ),
    );
  }
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
                style: SunburstType.of(
                  context,
                ).label.copyWith(color: colours.textSecondary),
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

/// The decoration of the [index]th `DecoratedBox` in the tree.
///
/// One helper, because reading a component's construction back is the single
/// most repeated line in this epic's tests and it was written four different
/// ways.
BoxDecoration decorationAt(WidgetTester tester, [int index = 0]) =>
    tester.widget<DecoratedBox>(find.byType(DecoratedBox).at(index)).decoration
        as BoxDecoration;

/// Every `BoxDecoration` in the tree, in paint order.
List<BoxDecoration> decorationsIn(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .map((box) => box.decoration as BoxDecoration)
    .toList();

/// Whether the subtree under [finder] carries a mirroring transform.
///
/// The RTL flip is applied by a widget rather than a painter, so "is this
/// mirrored" is "is there a Transform" — asserted five separate ways before
/// this existed.
bool isMirrored(WidgetTester tester, Finder finder) => find
    .descendant(of: finder, matching: find.byType(Transform))
    .evaluate()
    .isNotEmpty;

/// The total translation applied by every `Transform` under [finder].
///
/// **Scoped, not an ancestor walk.** `MaterialApp`'s page transition wraps the
/// whole route in transforms of its own, so an unscoped walk multiplies the
/// route's entry animation into the reading — which looks exactly like a
/// widget whose animation starts ninety milliseconds late. That cost an hour
/// once; it is written down here so it costs nobody else one.
///
/// Four tests had written this out, three of them character-identical apart
/// from which type they searched under.
Offset translationUnder(WidgetTester tester, Finder finder) => tester
    .widgetList<Transform>(
      find.descendant(of: finder, matching: find.byType(Transform)),
    )
    .fold(Offset.zero, (total, t) {
      final v = t.transform.getTranslation();

      return total + Offset(v.x, v.y);
    });

/// The product of every scale applied by the `Transform`s under [finder].
double scaleUnder(WidgetTester tester, Finder finder) => tester
    .widgetList<Transform>(
      find.descendant(of: finder, matching: find.byType(Transform)),
    )
    .map((t) => t.transform.getMaxScaleOnAxis())
    .fold(1, (total, scale) => total * scale);

/// Samples [read] every [step] for [frames] frames, pumping between each.
///
/// Rounded to four places, because a frame-for-frame comparison of raw doubles
/// across locales is a comparison of floating-point noise.
Future<List<double>> sampleFrames(
  WidgetTester tester,
  double Function(WidgetTester tester) read, {
  required int frames,
  required Duration step,
}) async {
  final samples = <double>[];

  for (var i = 0; i < frames; i++) {
    samples.add(double.parse(read(tester).toStringAsFixed(4)));
    await tester.pump(step);
  }

  return samples;
}
