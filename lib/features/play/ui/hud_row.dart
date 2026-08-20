import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/l10n/l10n_providers.dart';
import 'package:mindforge/ui/components/hud_pill.dart';

/// The three live values above a board.
///
/// **It formats, and the board does not.** A `HudSlot` arrives as a key and a
/// canonical integer; this resolves the key and renders the number through the
/// active locale — which is why switching language mid-run changes the pills
/// and nothing else.
///
/// The three pills are equal-flex, so a longer German caption cannot widen one
/// of them and push the other two out of line.
class HudRow extends ConsumerWidget {
  /// Creates the row over [hud].
  const HudRow({required this.hud, super.key});

  /// The three values.
  final GameHud hud;

  /// The gap between pills. `app.html`: `.hud{gap:8px}`.
  static const double gap = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: <Widget>[
        for (final (index, slot) in hud.slots.indexed) ...<Widget>[
          if (index > 0) const SizedBox(width: gap),
          Expanded(
            child: HudPill(
              label: _label(ref, slot),
              value: _value(ref, slot),
              tone: slot.tone,
            ),
          ),
        ],
      ],
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
      // NOT ISOLATED, and that is the whole point. The logical order is the
      // sign then the digit in every locale — one ARB message — and the bidi
      // algorithm is what puts the sign on the reading-START side: `x7` in
      // English, `۷×` in Persian, which is what the RTL reference draws.
      //
      // An FSI here resolves to the direction of the first STRONG character,
      // and `x7` has none, so it falls back to LTR and pins the sign left in
      // every locale. The pill holds nothing but this value, so there are no
      // neighbours for an isolate to protect.
      StatFormat.multiplier =>
        ref
            .watch(appLocalizationsProvider)
            .streakMultiplier(
              slot.canonicalValue,
              numbers.count(slot.canonicalValue),
            ),
      StatFormat.points || StatFormat.count => numbers.count(
        slot.canonicalValue,
      ),
    };
  }
}
