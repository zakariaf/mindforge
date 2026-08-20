import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/l10n/l10n_providers.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/hud_pill.dart';

/// The three-column strip above a board.
///
/// **It formats, and the board does not.** A `HudSlot` arrives as a key and a
/// canonical integer; this resolves the key and renders the number through the
/// active locale — which is why switching language mid-run changes the pills
/// and nothing else.
class PlayBand extends ConsumerWidget {
  /// Creates the band over [hud].
  const PlayBand({required this.hud, required this.fill, super.key});

  /// The three values.
  final GameHud hud;

  /// The band's background — the game's accent.
  final Color fill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        border: Border(
          bottom: BorderSide(color: colours.border, width: shape.borderWidth),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              for (final slot in hud.slots)
                HudPill(
                  label: _label(ref, slot),
                  value: _value(ref, slot),
                  tone: slot.tone,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The ARB string behind [slot]'s key.
  ///
  /// A switch over the KEYS a HUD may carry, not over a game: gen-l10n cannot
  /// resolve a key at runtime, and this is the same sanctioned shape as
  /// `game_strings.dart`.
  String _label(WidgetRef ref, HudSlot slot) {
    final l10n = ref.watch(appLocalizationsProvider);

    return switch (slot.labelKey) {
      'hudTimeLabel' || 'hudTime' => l10n.hudTime,
      'hudScoreLabel' || 'hudScore' => l10n.hudScore,
      'hudStreak' => l10n.hudStreak,
      'hudFound' => l10n.hudFound,
      'hudNext' => l10n.hudNext,
      // Not a fallback that renders the key: a HUD slot naming a string nobody
      // translated is a shipping defect, and printing `hudWhatever` on a live
      // board would look like a bug the player caused.
      _ => throw StateError(
        'no HUD label is registered for "${slot.labelKey}". Add a row here '
        'when a game introduces a slot — gen-l10n cannot look a key up at '
        'runtime.',
      ),
    };
  }

  /// [slot]'s value, formatted for the active locale.
  String _value(WidgetRef ref, HudSlot slot) {
    final numbers = ref.watch(localeNumbersProvider);

    return switch (slot.format) {
      StatFormat.duration => numbers.clock(slot.canonicalValue),
      StatFormat.percent => numbers.percent(slot.canonicalValue / 1000),
      StatFormat.points || StatFormat.count => numbers.count(
        slot.canonicalValue,
      ),
    };
  }
}
