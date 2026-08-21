import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/l10n/arb_lookup.dart';
import 'package:mindforge/l10n/l10n_providers.dart';
import 'package:mindforge/l10n/stat_text.dart';
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
  /// Resolved through `arb_lookup.dart`, which is the app's ONE key table. It
  /// used to be a switch here, a second one on the results screen and a third
  /// in `game_strings.dart` — so adding a game meant editing three files and
  /// missing one was a StateError on a live board.
  String _label(WidgetRef ref, HudSlot slot) =>
      arbString(ref.watch(appLocalizationsProvider), slot.labelKey);

  /// [slot]'s value, formatted for the active locale.
  ///
  /// Through `stat_text.dart`, the app's one switch over `StatFormat`. The HUD
  /// and the results screen each carried their own, four of five arms
  /// identical, so a new format had to be written twice.
  String _value(WidgetRef ref, HudSlot slot) => statText(
    slot.format,
    slot.canonicalValue,
    l10n: ref.watch(appLocalizationsProvider),
    numbers: ref.watch(localeNumbersProvider),
    // A RUNNING CLOCK, not a measurement: the HUD counts, results reports.
    durationStyle: DurationStyle.clock,
    total: slot.total,
  );
}
