# Contributing to MindForge

Thanks for wanting to build here. MindForge is an engine, so the most valuable contribution is
usually **a new game** — and there is a defined path for it.

Everything below applies to any change, but the game path is the one this document is shaped around.

## The three steps

1. **Write an epic.** A markdown file in [`epics/`](epics/) describing what you are building, why,
   and every task in it — with the tests stated before the implementation.
2. **Implement it.** On a branch, test-first, in granular commits.
3. **Open a pull request.** The maintainer reviews and merges. Please do not merge your own PR.

Step 1 is not paperwork. It is where the design decisions get made and where a reviewer can disagree
with you cheaply — before you have written a thousand lines. An implementation PR with no epic will be
asked for one.

---

## Before you start

Read these three, in this order:

| File | What it gives you |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | The house rules: product constraints, architecture, working agreements. |
| [`epics/README.md`](epics/README.md) | The build order, the delivery loop, the screenshot rule. |
| An existing epic, e.g. [`epics/E10-schulte-grid.md`](epics/E10-schulte-grid.md) | The format and level of detail expected. |

Then open the skills your work touches. `.claude/skills/` holds 45 of them; they are the actual
conventions, and several are enforced by scripts that will fail your PR if you ignore them. For a new
game the relevant set is usually:

`sunburst-game-surfaces` · `sunburst-components` · `sunburst-tokens` · `sunburst-shell-screens` ·
`seeded-determinism-and-golden-vectors` · `i18n-rtl-l10n` · `testing-strategy` ·
`widget-golden-and-a11y-testing` · `accessibility-as-code`

## Step 1 — Write the epic

Create `epics/E<NN>-<slug>.md`, taking the next free number. Match the structure of the existing
files exactly:

```markdown
# E<NN> · <Title>

| | |
|---|---|
| **Branch** | `epic/<NN>-<slug>` |
| **Depends on** | <epic ids, or "nothing"> |
| **Unblocks** | <epic ids> |
| **Status** | Not started |

## The epic
## Why we need it
## Current state
## What we will achieve
## Skills to load          <- a table: Skill | Why, for this epic
## Tasks
## Gates that must pass
## Risks and open questions
## Definition of done
```

Every task carries all eight fields:

```markdown
### T<NN>.<n> — <title>
**Goal.** One sentence.
**Tests first (TDD).** The tests to write before the implementation, named, with what each asserts.
**Implementation.** What to build, naming real files and types.
**Files.** Paths created or changed.
**Skills.** The subset for this task.
**Screenshot check.** The reference PNG and what to compare — or "n/a (no visual surface)".
**Done when.** A verifiable checklist.
**Commits.** The granular commits this task should produce, in order.
```

Open the epic as its own small PR if you would like feedback before implementing. That is encouraged
for anything large.

## Step 2 — Implement it

Branch from `main`:

```bash
git checkout main && git pull
git checkout -b epic/<NN>-<slug>
```

### Test-first, always

Write the test, watch it fail, then make it pass. Every task in every epic states its tests before its
implementation, and PRs are read that way. A change that arrives with tests written afterwards to fit
the code is visible, and will be asked for rework.

### Commit granularly

One logical change per commit, with the tests committed alongside the code they cover. The commit
sequence is the record of how the work was built — it should be readable on its own. No emoji in
commit messages.

### What a new game may and may not do

The engine only works if games stay inside their fence. `lib/games/**` may **not**:

- import `go_router`, use `Navigator`, or change a route — the shell owns navigation
- build a `Scaffold`, `AppBar`, `SafeArea` or any HUD widget — the shell owns all chrome
- declare a `Color` — a game picks one `GameAccent` case from the existing palette
- own a run timer or persist anything itself — `RunNotifier` owns the clock, repositories own writes

A game supplies a `GameDefinition`, a board widget that fills the rectangle it is given, and a
`BoardSnapshot` reporting three HUD slots plus progress. `scripts/check_shell_boundaries.sh` and
`check_game_palette.sh` enforce this.

**UI colours and gameplay colours are separate tiers and never mix.** In a game where colour carries
meaning, a chrome colour appearing on the board reads to the player as a hint.

**Every state needs at least three non-colour channels** — shadow depth, translate, border weight,
glyph, label. A greyscale screenshot must still answer "what state is this?".

### Localization is part of the work, not a follow-up

MindForge ships in `en`, `de`, `fa` and `ckb`. Persian and Kurdish Sorani are right-to-left.

- Every user-facing string goes in `lib/l10n/app_en.arb` **and gets translated in all four locales.**
  If you cannot translate, say so in the PR and it will be handled — do not ship English strings under
  a Persian locale key.
- **Directional geometry only**: `EdgeInsetsDirectional`, `AlignmentDirectional`, `TextAlign.start`.
  `EdgeInsets.only(left:)` and `Alignment.centerLeft` fail the gate.
- **Numerals localize.** `fa` and `ckb` render Eastern Arabic digits. If your game displays numbers,
  they go through the numeral policy, and your golden tests pin the expected output per locale.
- **Seeded generation must not depend on locale.** Generators emit integers and semantic tokens;
  localization happens at render. Your golden vectors must be byte-identical across all four locales.
- The hard offset shadow does **not** mirror — it is a light-source constant, not a reading direction.

### Compare against the reference screenshots

Any screen or board you build gets compared against its reference PNG in
[`design/sunburst-pop/screens/`](design/sunburst-pop/screens/), running on the canonical simulator at
390×844, in this order:

**structure → spacing rhythm → surface construction → type role → sampled hex**

A difference is a defect in your code. If you believe the reference is wrong, that is a design change:
edit `design/sunburst-pop/app.html`, re-run `capture-screens.sh`, and commit the regenerated PNGs with
your reasoning. What must never happen is silent divergence.

This is a human step. No pipeline performs it, which is why the PR asks you which screens you compared
and what you found.

## Step 3 — Open the pull request

Before you push, run all of this and get it green:

```bash
/simplify        # then address the findings
/code-review     # then address the findings

dart format --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
bash tool/skill_gates.sh
```

`/simplify` first, then `/code-review` — so the review reads the code you actually intend to ship.

> Do not run `for s in .claude/skills/*/scripts/*.sh; do bash "$s"; done`. Only 20 of the 49 scripts
> pass argument-free; five need an argument, five are runners rather than gates, and one breaks on
> macOS system bash. `tool/skill_gates.sh` is the sanctioned runner and carries an explicit skip table.

Then push and open the PR. The template asks for five things:

1. **What changed**
2. **Why**
3. **How it was verified** — the gate commands and their results
4. **Screens compared** — which reference PNGs, in which direction, and what you found
5. **Deliberately left out** — scope you chose not to cover, and why

A PR that leaves section 4 empty for visual work will be sent back.

### Review and merge

The maintainer reviews every PR and merges it. Merges preserve the granular commits rather than
squashing, because the commit sequence is part of the record.

Expect review comments. Disagreement is fine and often useful — the conventions in this repository
have reasons, and if a reason does not hold for your case, say so.

## Reporting bugs and proposing ideas

Open an issue. For a bug, include the device, the locale and text scale, and a screenshot — locale and
text scale are the two axes most bugs here hide in.

For a game idea, an issue is a good place to discuss it before you invest in writing an epic.

## License

By contributing you agree that your contributions are licensed under the
[Apache License 2.0](LICENSE), the same licence as the project.
