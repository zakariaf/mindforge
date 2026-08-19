<!--
  Fill in all five sections. See CONTRIBUTING.md.
  For a new game, link the epic file that describes it.
-->

**Epic:** <!-- epics/E<NN>-<slug>.md, or "n/a" with a reason -->

## What changed


## Why


## How it was verified

<!-- Paste the commands you ran and their results. -->

- [ ] `/simplify` run, findings addressed
- [ ] `/code-review` run, findings addressed
- [ ] `dart format --set-exit-if-changed .`
- [ ] `flutter analyze --fatal-infos`
- [ ] `flutter test`
- [ ] `bash tool/skill_gates.sh`

## Screens compared

<!--
  Which reference PNGs in design/sunburst-pop/screens/ did you compare against, on the canonical
  simulator (MindForge iPhone 14, 390x844), and what did you find?
  Compare in order: structure -> spacing rhythm -> surface construction -> type role -> sampled hex.
  Write "n/a (no visual surface)" if this PR renders nothing.
  A visual PR that leaves this empty will be sent back.
-->

| Screen | Direction | Result |
|---|---|---|
|  | LTR / RTL |  |

- [ ] Checked in all four locales (`en`, `de`, `fa`, `ckb`) where strings are rendered
- [ ] Checked at text scale 1.0 / 1.3 / 2.0 — nothing shrinks to fit, nothing is ellipsised

## Deliberately left out

<!-- Scope you chose not to cover, and why. Being explicit here is not a weakness. -->
