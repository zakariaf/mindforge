import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/l10n/arb_lookup.dart';
import 'package:mindforge/l10n/bidi_text.dart';
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
  /// Resolved through `arb_lookup.dart`, which is the app's ONE key table. It
  /// used to be a switch here, a second one on the results screen and a third
  /// in `game_strings.dart` — so adding a game meant editing three files and
  /// missing one was a StateError on a live board.
  String _label(WidgetRef ref, HudSlot slot) =>
      arbString(ref.watch(appLocalizationsProvider), slot.labelKey);

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
      // ISOLATED, unlike the multiplier, and for the opposite reason. A
      // fraction has to keep reading numerator-first in every language, and
      // `۶ / ۲۵` inside an RTL line renders as `۲۵ / ۶` without this: the
      // spaces and the slash are neutrals that take the paragraph direction.
      // FSI resolves to LTR here because the run carries no strong character,
      // which is exactly the direction a fraction wants.
      StatFormat.fraction => BidiText.isolate(
        ref
            .watch(appLocalizationsProvider)
            .foundOfTotal(
              numbers.count(slot.canonicalValue),
              numbers.count(slot.total ?? 0),
            ),
      ),
      StatFormat.points || StatFormat.count => numbers.count(
        slot.canonicalValue,
      ),
    };
  }
}
