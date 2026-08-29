# App Review — Guideline 4.3(a), and what changed

| | |
|---|---|
| **Build rejected** | 1.0.0 (1), uploaded 2026-08-21, app id `6803829952` |
| **Rejected** | 2026-08-29, Guideline 4.3(a) — Design: Spam |
| **Answered by** | E12, `epics/E12-two-original-games.md` |
| **Status** | evidence prepared; the reply and the resubmission are account-holder actions |

## What the rejection said

> We noticed the app shares a similar binary, metadata, and/or concept as apps
> submitted to the App Store by other developers, with only minor differences.

## What it is, and is not

It is **not** a claim about the source. MindForge is open source under Apache-2.0
at `github.com/zakariaf/mindforge`, was written from scratch, uses no app
template and no third-party UI kit. Answering with that alone answers a question
nobody asked.

It is a claim about the **catalogue**, and read that way it was fair. 1.0.0's
entire content was the **Stroop task** and the **Schulte table** — two
public-domain psychology instruments the App Store already carries in quantity.
From a reviewer's screen, four seconds in, the app looked like thirty others.

## What changed

Two new games, chosen under one rule: **the mechanic must be something only this
app can ship.** That rule excluded the obvious candidates — N-Back, Simon, Corsi
block-tapping, Trail Making, Tower of Hanoi, mental rotation — because each is
another public-domain classic with exactly the saturation that produced the
rejection. Adding two of those would have turned "two classic tests" into "four
classic tests", which is a worse answer, not a better one.

### Digit Bridge — a cross-script numeral match

A target numeral is shown in one numbering system; six candidates are shown in
the other; the player finds the match. One side always renders the reader's own
digits and the other renders the other script, and a seeded bit decides which
side is which — so the game is always "translate from or to what you know", in
every language the app ships.

The five wrong candidates are near-misses drawn from a declared taxonomy — a
transposition, a substitution, a reordering, a length change — never random
numbers, because random numbers would make the board a spot-the-shape exercise
winnable without reading either script.

| Claim | Where to check it |
|---|---|
| The game exists and is registered | `lib/games/digit_bridge/`, one line in `lib/games/game_registry.dart` |
| The distractor taxonomy is real | `lib/games/digit_bridge/domain/bridge_distractor.dart`, proved in `test/games/digit_bridge/domain/bridge_round_generator_test.dart` |
| Two numbering systems render at once | `LocaleNumbers.digitsInScript`, `lib/l10n/locale_numbers.dart` |
| Rounds are identical in all four locales | `test/games/digit_bridge/domain/bridge_round_locale_test.dart` |

**It could not have been built without work this app had already done.** The
numbering systems are pinned per locale in `LocaleNumbers` — the one
`NumberFormat` construction site in the codebase — because `intl` ships no
Sorani number symbols and falls back to Latin silently. That machinery exists
because the app ships Persian and Kurdish Sorani, and it is what the game is
made of.

### False Light — a board with no colour and no text

Tiles sit on a field, most raised under the app's single light source, some
pressed flat. The player sweeps the pressed ones; clearing a field deals the
next.

A raised tile and a pressed one differ in three channels at once, **none of them
hue**: the shadow is present or absent, the tile is at rest or translated into
where its shadow was, and the fills differ in luminance rather than only in
colour.

| Claim | Where to check it |
|---|---|
| The board draws no text at all | `test/policy/engine_locale_purity_test.dart`, "False Light DRAWS nothing a locale could translate" |
| The states are separable with hue removed | `test/games/false_light/ui/light_tile_states_test.dart`, computed WCAG luminance plus a greyscale golden |
| The colour-blind setting changes nothing on it | `test/games/false_light/ui/light_tile_states_test.dart`, "changes nothing on this board" — rendered fills compared with the setting on and off |
| A screen-reader user is told the depth in words | `lightTileRaised` / `lightTilePressed` / `lightTileSwept`, asserted present |

## The differentiators that were already true, and are checkable

These were true of 1.0.0 as well. They are listed because a reviewer cannot see
them in four seconds, not because they are new.

| Claim | Where to check it |
|---|---|
| Four locales, two right-to-left | `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_fa.arb`, `lib/l10n/app_ckb.arb`; `CFBundleLocalizations` in `ios/Runner/Info.plist` |
| Kurdish Sorani needs custom delegates, because iOS ships none | `lib/l10n/ckb_localizations.dart`, `test/l10n/material_delegate_support_test.dart` |
| A colour-blind-playable Stroop test | Settings → Colour-blind friendly palette; `lib/games/stroop_rush/ui/board/play_fill.dart` puts a fill pattern on the key **and** inside the printed word |
| Zero permissions | `test/policy/permissions_test.dart` — no `NS*UsageDescription`, no entitlements, no background modes |
| No network code at all | `test/policy/dependency_policy_test.dart` over the resolved lockfile |
| No analytics, no crash reporting, no accounts | same gate; the App Privacy answers of "Data Not Collected" are literally accurate |

## What this document does not claim

- It does not claim the rejection will be overturned. 4.3(a) is a reviewer
  judgement, and shipping differentiation improves the argument without settling
  it. If a second rejection follows, the escalation is an App Review Board
  appeal with this document as the evidence — not a fifth game added in hope.
- It does not claim the two new games are unprecedented as *tasks*. Numeral
  recognition and visual search are ordinary cognitive work. What is claimed is
  narrower and checkable: **these two implementations depend on capabilities this
  app has and a repackaged template does not**, and neither is a clone of a
  named instrument.
- It does not claim anything about other developers' apps.

## Verification

Every row above names a file, a test or a setting. `test/policy/store_listing_test.dart`
fails if a claim in this document names something that does not exist.
