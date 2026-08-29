import 'package:flutter/material.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_board_state.dart';
import 'package:mindforge/games/digit_bridge/ui/board/bridge_numeral.dart';
import 'package:mindforge/shared/motion/shake_on_wrong.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

/// One candidate chip: a numeral, and four states.
///
/// **Hue is never the answer here, so hue never moves.** A chip is a raised
/// cream surface in every state; what changes is elevation, translation, the
/// fill when it is taken, and the ink strike bar.
///
/// | state | fill | elevation | translate | strike bar |
/// |---|---|---|---|---|
/// | idle | surfaceRaised | e2 | none | no |
/// | rejected | surfaceRaised | flat | (2, 2) | yes |
/// | locked | surfaceRaised | flat | none | no |
///
/// **There is no "matched" state, and there was one until it was found to be
/// unreachable.** A correct tap advances the round in the same frame, so the
/// chip that was tapped is gone before it could draw anything. Its residue
/// under Sound off, Haptics off and Reduce motion on is the whole board
/// changing — a new target and six new numerals — which is a larger change than
/// any single-chip animation would have been.
///
/// A resolved chip **drops its `onTap`** rather than passing `enabled: false`:
/// the disabled shape swaps the fill to `surfaceSunk`, which reads as a control
/// that failed rather than one that is finished (`sunburst-components` rule 6).
class BridgeChip extends StatelessWidget {
  /// Creates a chip.
  const BridgeChip({
    required this.label,
    required this.state,
    required this.wrongTapId,
    required this.onTap,
    required this.semanticLabel,
    super.key,
  });

  /// The numeral, already rendered in this round's script for this side.
  final String label;

  /// What the chip is showing.
  final BridgeChipState state;

  /// A value that changes on every wrong tap.
  ///
  /// Keys the shake, so tapping the same wrong chip twice shakes twice.
  final int wrongTapId;

  /// What a tap does, or `null` once the chip is resolved.
  final VoidCallback? onTap;

  /// What a screen reader announces.
  ///
  /// Separate from [label] because the two are genuinely different: the label
  /// is a numeral in whichever script this side of the bridge is drawn in, and
  /// a reader who cannot see it needs to be told which system it is written in
  /// as well as what it says.
  final String semanticLabel;

  /// The key every tile that is not currently rejected carries.
  ///
  /// Any constant would do; -1 is chosen because `wrongTapId` counts up from
  /// zero and can never reach it.
  static const int _restingIdentity = -1;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    final (
      Color fill,
      PopElevation elevation,
      Offset translate,
      bool isStruck,
    ) = switch (state) {
      BridgeChipState.idle => (
        colours.surfaceRaised,
        PopElevation.e2,
        Offset.zero,
        false,
      ),
      BridgeChipState.rejected => (
        colours.surfaceRaised,
        PopElevation.flat,
        SunburstShape.pressedShadow,
        true,
      ),
      BridgeChipState.locked => (
        colours.surfaceRaised,
        PopElevation.flat,
        Offset.zero,
        false,
      ),
    };

    final chip = Transform.translate(
      offset: translate,
      child: PopSurface(
        fill: fill,
        radius: BorderRadiusDirectional.all(shape.radiusLg),
        elevation: elevation,
        onTap: onTap,
        semanticLabel: semanticLabel,
        child: Padding(
          padding: EdgeInsetsDirectional.all(shape.borderWidth),
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: <Widget>[
              BridgeNumeral(
                label: label,
                style: type.numericHud.copyWith(color: colours.textPrimary),
              ),
              if (isStruck)
                PositionedDirectional(
                  start: SunburstShape.space2,
                  end: SunburstShape.space2,
                  child: Container(
                    height: shape.borderWidth,
                    color: colours.border,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return ShakeOnWrong(
      // KEYED ON THE REJECTED TILE, not on every chip. `wrongTapId` is a
      // board-wide counter, so keying every chip on it changes every key on one
      // wrong tap: `Widget.canUpdate` fails across the grid and the whole
      // subtree is discarded. Measured on a board — 6 of 6 chips
      // remounted for one shake, which is ~60 AnimationController and Ticker
      // create-and-dispose pairs on the exact frame that starts an animation
      // and fires a haptic. A correct tap remounted none, which is what proved
      // it was the key.
      //
      // Only one chip is ever `rejected` — the notifier resets the rest — so a
      // constant for every other state gives the newly-rejected chip a fresh
      // identity and leaves the other five alone. Tapping the same chip twice
      // still shakes twice, which is the behaviour the identity exists for.
      key: ValueKey<int>(
        state == BridgeChipState.rejected ? wrongTapId : _restingIdentity,
      ),
      isWrong: state == BridgeChipState.rejected,
      child: chip,
    );
  }
}
