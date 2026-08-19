// The same widget twice: once as it usually arrives in a diff, once as it must
// ship. This is the HUD stat pill from system.html §10 — "Time 0:23", the small
// paper capsule that sits in the play-screen HUD.
//
// Nothing here is a style preference. Every line in the WRONG version fails a
// gate, a contrast floor, or a stated rule in SKILL.md, and the comment says
// which one.

import 'package:flutter/material.dart';

import 'sunburst_theme.dart';

// ===========================================================================
// WRONG
// ===========================================================================

class WrongHudStatPill extends StatelessWidget {
  const WrongHudStatPill({
    required this.label,
    required this.value,
    required this.isAlarm,
    super.key,
  });

  final String label;
  final String value;
  final bool isAlarm;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      // WRONG: raw Duration + a framework curve. check_raw_values.sh fails on
      // both. It also picks 200ms, which is not one of the four Sunburst
      // durations, and easeOut, which is not Cubic(.2,.8,.2,1).
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        // WRONG: raw hex. #FFFFFF happens to be the right white today; the next
        // person copies the line and reaches for #FAFAFA.
        color: isAlarm ? const Color(0xFFD81E2C) : const Color(0xFFFFFFFF),
        // WRONG: magic radius. 14 is not on the scale (10/16/22/28/pill), so
        // this pill is 2px rounder than every other pill on the screen.
        borderRadius: BorderRadius.circular(14),
        // WRONG: Colors.* — and a 3px black border, not a 3px ink border.
        // Ink is #2B1B4D; pure black is explicitly banned by the direction.
        border: Border.all(color: Colors.black, width: 3),
        // WRONG: a blurred shadow. Sunburst Pop has no blur anywhere — this
        // renders as a generic Material card and destroys the die-cut look.
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            // WRONG: hardcoded fontSize + fontFamily + letterSpacing, and
            // ink-2 on a danger fill in the alarm case — 1.53:1, invisible.
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 10,
              letterSpacing: 1.4,
              color: Color(0xFF5A4A7D),
            ),
          ),
          Text(
            value,
            // WRONG: no tabular figures. "0:23" and "0:11" have different
            // widths, so the pill jitters every second of the run.
            style: const TextStyle(fontFamily: 'Fredoka', fontSize: 22),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// RIGHT
// ===========================================================================

class HudStatPill extends StatelessWidget {
  const HudStatPill({
    required this.label,
    required this.value,
    this.isAlarm = false,
    super.key,
  });

  /// The static caption — "Time", "Score", "Streak".
  final String label;

  /// The live value, already formatted by the ViewModel. Never formatted here.
  final String value;

  /// Under five seconds. Carries a colour change AND the alarm glyph the caller
  /// supplies — colour is the third channel, never the first.
  final bool isAlarm;

  @override
  Widget build(BuildContext context) {
    final colors = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);
    final motion = SunburstMotion.of(context);

    // The fill decides the label colour; the call site never picks one.
    final fill = isAlarm ? colors.danger : colors.surfaceRaised;
    final onFill = isAlarm ? colors.surfaceRaised : colors.textPrimary;
    // textSecondary is legal on surface/surfaceSunk/surfaceRaised only. On the
    // saturated danger fill it drops to 1.53:1, so the caption goes to the
    // same on-fill colour as the value (paper on danger, 5.07:1).
    final onFillMuted = isAlarm ? colors.surfaceRaised : colors.textSecondary;

    return AnimatedContainer(
      // resolve() is the only place a widget asks whether to animate; under
      // reduce-motion this is Duration.zero and the colour still lands.
      duration: motion.resolve(context, motion.durState),
      curve: motion.easeOut, // colour transitions never take easePop
      padding: const EdgeInsets.symmetric(
        horizontal: SunburstShape.space3,
        vertical: SunburstShape.space2,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.all(shape.radiusMd),
        border: Border.all(color: colors.border, width: shape.borderWidth),
        // e1 — the elevation a HUD pill earns. shadow() is the only BoxShadow
        // constructor in the app and it hardcodes blurRadius: 0.
        boxShadow: shape.shadow(shape.e1, colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: type.label.copyWith(color: onFillMuted),
          ),
          Text(
            value,
            // numericHud already carries FontFeature.tabularFigures().
            style: type.numericHud.copyWith(color: onFill),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// The one thing the gate cannot see
// ===========================================================================
//
// check_raw_values.sh passes on this file and would also pass on a version that
// used `colors.playRed` for the alarm fill — the grep only knows about raw
// values, not about tier. Reaching a gameplay slot for chrome is a review
// finding, and the reason it matters is concrete: `playRed` is re-pointed to
// cbPink when a player turns on the colour-blind palette, so a HUD alarm wired
// to it would silently turn magenta for exactly the players who need the alarm
// most. `danger` reads the primitive and never moves.
