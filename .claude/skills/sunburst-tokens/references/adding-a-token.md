# Adding a token

Most requests that arrive as "I need a new colour" are answered by an existing slot. This is the procedure for telling the two apart, and the mechanics for the case where a new slot really is the answer.

## The decision procedure

Answer in order. The first "yes" ends it.

1. **Does a slot already carry this meaning?** Not this *value* — this **meaning**. `surfaceRaised` and `#FFFFFF` are the same white; if what you need is "a raised surface", the slot is the answer even if you arrived by wanting white.
2. **Is it a state of something that already has a slot?** Pressed, focused, disabled and selected are not colours in Sunburst Pop — they are shadow depth, translate, ring, and a shape change. There is no `accentPressed`. If you are about to add one, the component is wrong, not the palette. See `sunburst-components`.
3. **Is it a game's identity?** Then it is a `game<Name>` / `game<Name>Deep` pair and nothing else changes. `sunburst-game-surfaces` owns the accent contract.
4. **Is it a gameplay answer colour?** Then it lands in the gameplay tier, must clear 4.5:1 as text on cream *or* ship with the ink outline, and must claim an unused `PlayFill`. There are four patterns; when they are gone, the answer set is full.
5. **Is it decoration that never carries a label?** Then say so in the row's `Role` column and give it no `@contrast` line — but check it is genuinely never labelled, because `gameStroopDeep` at 3.90:1 under ink is exactly the trap.
6. **None of the above** → a new semantic slot. Continue below.

Never the alternatives: a one-off `const Color` in a feature file (the gate fails it), a `// ignore:` (the gate exists to be un-ignorable), `Color.lerp` between two slots at a call site (an unnamed colour nobody measured), or `.withOpacity()` on a slot (it fades the 3px ink border with the fill, and the border is the brand).

## Worked example — a legitimate new slot

> "The Stats screen needs a chart gridline. It's behind the bars, it must not compete with them, and it sits on paper."

Walk it: it is not an existing meaning (no slot means "recessive rule on a raised surface"); not a state; not identity; not gameplay; it carries no label of its own. `divider` looks close — but `divider` is documented as *the toggle-track inset only*, and at 1.26:1 on paper it is invisible under a chart. Widening `divider`'s meaning to cover both would make one slot answer two questions and guarantee that fixing one breaks the other.

So: a new slot `chartGrid`, mapped to the existing primitive `inkMuted` — **3.59:1 on paper**, recessive enough to sit behind the bars and visible enough to clear the 3.0 non-text floor. Note the two things that did **not** happen. No new primitive: a slot reusing an existing primitive is the cheap, common, correct case. And no discomfort about `inkMuted` already being the value behind `textDisabled` — a primitive is a *value*, a slot is a *meaning*, and one value legitimately serving two meanings is exactly what the two-tier split is for. What would be wrong is `chartGrid: colors.textDisabled` at a call site: that aliases the two meanings, and the next person who softens disabled text moves every gridline in the app.

Do not reach for `creamEdge` here because it is "the quiet one". Picking a hex by how it looks and then hunting for a meaning to attach is the failure mode this whole procedure exists to stop — and it would ship a gridline nobody can see.

## Worked example — a request that should reuse a slot

> "The 'unsaved run' banner needs its own amber. Tangerine is too loud next to the coral timer."

Walk it: step 1 says the meaning is "warning", and `warning` exists. The complaint is not that the meaning is missing — it is that two saturated fills are adjacent. Adding `warningSoft` would put two colours in the app that both mean caution, and the next screen would pick whichever looked nicer, which is exactly how a palette stops meaning anything. Fix the adjacency instead: drop the banner to e1, move it out of the coral band, or give it a paper fill with a tangerine chip. `warning` stays one value.

The same answer applies to "a slightly lighter ink for this caption" (that is `textSecondary`), "a softer border on the settings rows" (`border` is structural — the row separator is ink at 3px or it is nothing), and "a disabled state that doesn't look so dead" (disabled is `textDisabled` + `borderDisabled` **and** a shape change; making it prettier by making it more legible defeats it).

## Mechanics — the four places, plus the gate

Adding `chartGrid` to `SunburstColors`. The compiler catches exactly one of these; the other three are on you.

1. **Field + constructor parameter.** `required this.chartGrid` and `final Color chartGrid;` in its group.
2. **`copyWith`.** Add `Color? chartGrid` and `chartGrid: chartGrid ?? this.chartGrid`.
3. **`lerp`.** Add `chartGrid: c(chartGrid, other.chartGrid)`. This is the one that rots: someone adds a slot, updates the constructor and `copyWith`, and the new slot then never interpolates — forever, silently.
4. **The `const SunburstColors.sunburstPop` instance.** `chartGrid: _P.creamEdge,`. **This is the one the compiler catches** (a missing required argument), which is why the other three need a checklist.

Plus, if the slot ever sits under text or is itself a UI boundary:

5. **A `// @contrast <fg> <bg> <min>` line** next to the others. `scripts/check_palette_contrast.sh` resolves it through the const instance to a primitive and recomputes the ratio. Floors: 4.5 for body text, 3.0 for large text and non-text UI. Fix the hex or restate the pair — never lower the floor. A decorative slot legitimately has no line; say so in the reference table so the omission reads as a decision.

Also update `references/palette-and-slots.md` and add the row to `_props` (equality and `hashCode`), or two different palettes will compare equal.

Adding to `SunburstShape` / `SunburstMotion` / `SunburstType` is the same four steps against those classes — except `SunburstMotion.lerp` is a deliberate midpoint snap, so a new duration or curve needs nothing there. Its comment says so; do not "restore" a per-field interpolation.

## Adding a primitive

Rarer, and a bigger deal: a new primitive is a new value in the product's vocabulary. Add one only when no existing primitive expresses the hue, and then:

- Put it in `_P` in the family order already there, with its `-deep` partner if anything will ever stripe or ray with it.
- Add it to `system.html`'s `:root` block **and** its token table in the same change. The design file is the authority; a primitive that exists only in Dart is a value that has escaped review.
- Measure it against cream, paper and ink before it is used, not after.

The known standing constraint: any new gameplay colour must clear 4.5:1 on cream *or* ship with the ink outline, **and** claim an unused fill pattern. Do not let a new game add a pastel to the answer palette, and do not let it ship with hue as its only channel.

## Renaming and removing

**Renaming** a slot is a mechanical rename across the six places above plus `system.html`'s table — do it in one commit, never leave the old name as a deprecated alias. Two names for one value is how a palette starts drifting: the next person picks whichever they find first, and reviewers stop being able to tell whether two call sites mean the same thing.

**Removing** a slot needs one check the compiler will not do for you: grep the whole repo for the field name before deleting it, because a slot with no remaining references is dead weight but a slot with one reference is load-bearing. Delete it from `_props` last — that is the field the equality contract depends on, and removing it there while leaving the field elsewhere makes two different palettes compare equal, which silently blinds every golden test that would otherwise have caught the change.

## The smell that means you got it wrong

Six months from now, the sign a slot was added for a value rather than a meaning is that you cannot describe it without naming its colour. `surfaceRaised` and `warning` survive the test — you can say what they are for without saying what they look like. `lightAmber`, `borderSoft` and `accent2Alt` do not, and each one will end up used for two unrelated things by two different people.

When you catch one, the fix is not a rename. Find the two meanings it is serving, give each the slot it should have had, and delete the original.
