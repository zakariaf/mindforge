import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Border width, the radius scale, hard-offset elevation, press physics, the
/// focus ring, and the spacing rhythm.
///
/// `blurRadius` is absent by construction: [shadow] is the only constructor of
/// a `BoxShadow` in the app and it hardcodes zero.
@immutable
class SunburstShape extends ThemeExtension<SunburstShape> {
  /// Creates a shape scale.
  const SunburstShape({
    required this.borderWidth,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.radiusPill,
    required this.e1,
    required this.e2,
    required this.e3,
    required this.e4,
    required this.pressScale,
    required this.pressScaleSmall,
    required this.focusGap,
    required this.focusWidth,
    required this.stripePitch,
    required this.stripeAngle,
  });

  /// The ink border on every raised surface. Three logical pixels, everywhere.
  final double borderWidth;

  /// The smallest corner: chips, tiles, small keys.
  final Radius radiusSm;

  /// The default corner: buttons, list rows.
  final Radius radiusMd;

  /// Cards.
  final Radius radiusLg;

  /// Sheets and the largest surfaces.
  final Radius radiusXl;

  /// A fully rounded end, for pills and toggles.
  final Radius radiusPill;

  /// The lowest hard-offset elevation.
  ///
  /// The **absence** of a shadow is `const <BoxShadow>[]` — what `system.html`
  /// calls `--sh-0`. There is deliberately no `e0` field: a zero-offset shadow
  /// still paints, and a surface that should be flat must draw nothing.
  final Offset e1;

  /// The second elevation step.
  final Offset e2;

  /// The third elevation step.
  final Offset e3;

  /// The highest elevation step.
  final Offset e4;

  /// How far a large pressable shrinks: buttons, answer keys, game cards.
  final double pressScale;

  /// How far a small pressable shrinks: tiles, toggles, tabs, segments.
  ///
  /// Two scales, both transcribed. The e1 family is small enough that the
  /// larger scale is imperceptible on it, so the smaller surfaces shrink harder.
  final double pressScaleSmall;

  /// The gap between a surface's edge and its focus ring.
  final double focusGap;

  /// The focus ring's stroke width.
  final double focusWidth;

  /// The distance between stripe centres in a striped fill.
  final double stripePitch;

  /// The stripe angle, in degrees.
  final double stripeAngle;

  /// 4 — the smallest step.
  ///
  /// Spacing is layout **rhythm**, not a themeable value: it is identical in
  /// every conceivable variant, and interpolating a gutter mid-animation is
  /// meaningless. So it is static rather than an instance field, and does not
  /// appear in [copyWith], [lerp] or equality.
  static const double space1 = 4;

  /// 8.
  static const double space2 = 8;

  /// 12.
  static const double space3 = 12;

  /// 16.
  static const double space4 = 16;

  /// 20.
  static const double space5 = 20;

  /// 28.
  static const double space6 = 28;

  /// 40 — the largest step.
  static const double space7 = 40;

  /// The screen gutter, on all eight screens, with no exceptions.
  static const double gutter = space5;

  /// The gap between stacked cards.
  static const double cardGap = space4;

  /// A card's inner padding.
  static const double cardPadding = space4;

  /// The **only** `BoxShadow` factory in MindForge.
  ///
  /// Blur and spread are zero, always: the light comes from one fixed direction
  /// and the shadow is the same ink as the border, so a surface reads as
  /// die-cut card stock rather than as a floating panel.
  ///
  /// The offset **does not mirror in RTL**. It is a light-source constant — one
  /// imaginary light for the whole app — not a reading-direction property. A
  /// Persian build lit from the other side would disagree with every reference
  /// screenshot, and `test/policy/directional_geometry_test.dart` pins it.
  List<BoxShadow> shadow(Offset elevation, Color ink) => <BoxShadow>[
    // The two zeros are written out even though they are BoxShadow's defaults.
    // avoid_redundant_argument_values wants them gone; making them implicit
    // would hide the single most load-bearing invariant in the design system
    // at the one place it is enforced.
    // ignore: avoid_redundant_argument_values
    BoxShadow(color: ink, offset: elevation, blurRadius: 0, spreadRadius: 0),
  ];

  /// Where a surface at [elevation] moves while pressed.
  ///
  /// It travels `elevation - 1` on both axes and keeps a 1px shadow, so it
  /// reads as pushed **into** the page rather than as merely smaller. The hit
  /// area does not move with it.
  Offset pressTranslate(Offset elevation) =>
      Offset(elevation.dx - 1, elevation.dy - 1);

  /// The shadow a pressed surface keeps.
  static const Offset pressedShadow = Offset(1, 1);

  /// The shape scale attached to [context]'s theme.
  ///
  /// Asserts rather than falling back, for the same reason `SunburstColors.of`
  /// does.
  static SunburstShape of(BuildContext context) {
    final extension = Theme.of(context).extension<SunburstShape>();
    assert(
      extension != null,
      'SunburstShape is missing from the theme. Build it with '
      'buildSunburstTheme().',
    );
    return extension!;
  }

  List<Object?> get _props => <Object?>[
    borderWidth,
    radiusSm,
    radiusMd,
    radiusLg,
    radiusXl,
    radiusPill,
    e1,
    e2,
    e3,
    e4,
    pressScale,
    pressScaleSmall,
    focusGap,
    focusWidth,
    stripePitch,
    stripeAngle,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SunburstShape &&
          runtimeType == other.runtimeType &&
          _sameProps(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);

  static bool _sameProps(List<Object?> a, List<Object?> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  SunburstShape copyWith({
    double? borderWidth,
    Radius? radiusSm,
    Radius? radiusMd,
    Radius? radiusLg,
    Radius? radiusXl,
    Radius? radiusPill,
    Offset? e1,
    Offset? e2,
    Offset? e3,
    Offset? e4,
    double? pressScale,
    double? pressScaleSmall,
    double? focusGap,
    double? focusWidth,
    double? stripePitch,
    double? stripeAngle,
  }) => SunburstShape(
    borderWidth: borderWidth ?? this.borderWidth,
    radiusSm: radiusSm ?? this.radiusSm,
    radiusMd: radiusMd ?? this.radiusMd,
    radiusLg: radiusLg ?? this.radiusLg,
    radiusXl: radiusXl ?? this.radiusXl,
    radiusPill: radiusPill ?? this.radiusPill,
    e1: e1 ?? this.e1,
    e2: e2 ?? this.e2,
    e3: e3 ?? this.e3,
    e4: e4 ?? this.e4,
    pressScale: pressScale ?? this.pressScale,
    pressScaleSmall: pressScaleSmall ?? this.pressScaleSmall,
    focusGap: focusGap ?? this.focusGap,
    focusWidth: focusWidth ?? this.focusWidth,
    stripePitch: stripePitch ?? this.stripePitch,
    stripeAngle: stripeAngle ?? this.stripeAngle,
  );

  @override
  SunburstShape lerp(covariant SunburstShape? other, double t) {
    if (other == null) return this;
    double d(double a, double b) => lerpDouble(a, b, t)!;
    Radius r(Radius a, Radius b) => Radius.lerp(a, b, t)!;
    Offset o(Offset a, Offset b) => Offset.lerp(a, b, t)!;

    return SunburstShape(
      borderWidth: d(borderWidth, other.borderWidth),
      radiusSm: r(radiusSm, other.radiusSm),
      radiusMd: r(radiusMd, other.radiusMd),
      radiusLg: r(radiusLg, other.radiusLg),
      radiusXl: r(radiusXl, other.radiusXl),
      radiusPill: r(radiusPill, other.radiusPill),
      e1: o(e1, other.e1),
      e2: o(e2, other.e2),
      e3: o(e3, other.e3),
      e4: o(e4, other.e4),
      pressScale: d(pressScale, other.pressScale),
      pressScaleSmall: d(pressScaleSmall, other.pressScaleSmall),
      focusGap: d(focusGap, other.focusGap),
      focusWidth: d(focusWidth, other.focusWidth),
      stripePitch: d(stripePitch, other.stripePitch),
      stripeAngle: d(stripeAngle, other.stripeAngle),
    );
  }

  /// The one shape scale, transcribed from `system.html`.
  static const SunburstShape sunburstPop = SunburstShape(
    borderWidth: 3,
    radiusSm: Radius.circular(10),
    radiusMd: Radius.circular(16),
    radiusLg: Radius.circular(22),
    radiusXl: Radius.circular(28),
    radiusPill: Radius.circular(999),
    e1: Offset(3, 3),
    e2: Offset(5, 5),
    e3: Offset(8, 8),
    e4: Offset(10, 10),
    pressScale: 0.98,
    pressScaleSmall: 0.97,
    // DERIVED: system.html §12 draws the focus ring as a 4px grape-pop outline
    // offset 3px from the surface. Neither number is a :root custom property.
    focusGap: 3,
    focusWidth: 4,
    // DERIVED: the striped answer fill in system.html §7 repeats every 9px at
    // 45 degrees. Neither is a :root custom property.
    stripePitch: 9,
    stripeAngle: 45,
  );
}
