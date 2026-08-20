#!/usr/bin/env bash
# skill_gates.sh — the project's ONLY sanctioned way to run the skill gates.
#
# Every epic from E02 onward calls `bash tool/skill_gates.sh` in its Gates
# section. Do NOT replace it with:
#
#     for s in .claude/skills/*/scripts/*.sh; do bash "$s"; done
#
# That loop cannot exit 0. Measured against this repository, it fails on more
# than half the scripts: several take a required argument and can never pass
# argument-less, several are generators or runners rather than gates, and one
# uses `mapfile` and exits 127 on macOS system bash 3.2. This runner exists so
# the skip list is explicit, reasoned and reviewed.
#
# THE TABLES ARE LIVING. A later epic that creates a script's target moves its
# row from SKIP to RUN in the same PR, and
# test/policy/skill_gates_coverage_test.dart — which asserts each script appears
# EXACTLY ONCE — is what forces the move to be deliberate.
#
#   usage: skill_gates.sh
#   exit 0  every RUN row exited 0
#   exit 1  at least one RUN row failed
#   exit 2  bash is older than 4

set -uo pipefail

# --- bash 4 is a hard requirement -------------------------------------------
# local-notifications-scheduler/scripts/check-scheduler-purity.sh uses `mapfile`
# and exits 127 on bash 3.2. macOS system bash IS 3.2, and so is the GitHub
# macOS runner image's /bin/bash — moving CI to macOS means the runner no longer
# supplies bash 5 for free the way the Ubuntu image did. Both the local
# instructions and the CI step provide one explicitly.
#
# Do NOT edit the skill script to work around this. The skill library is not
# this repository's to change.
if (( BASH_VERSINFO[0] < 4 )); then
  cat >&2 <<'MSG'
FAIL: tool/skill_gates.sh needs bash 4 or newer; this is bash 3.2 or older.

One skill script uses `mapfile`, a bash 4 builtin, and exits 127 without it.

  local:  brew install bash   then   /opt/homebrew/bin/bash tool/skill_gates.sh
  CI:     the workflow installs one and invokes this script with it
MSG
  exit 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

SKILLS='.claude/skills'

# =============================================================================
# RUN TABLE — "<script path> | <arguments>"
#
# The argument each script actually takes was read from its header and verified
# by running it. Most default to `lib`; several do not, and those are noted.
# =============================================================================
RUN_TABLE=(
  # --- repository-wide, no argument (they take a PROJECT dir, not a source dir)
  "lint-and-style-config/scripts/verify-include-pin.sh|"
  "codegen-and-toolchain/scripts/check-codegen-hygiene.sh|"
  # Takes a project dir. Measured on this iOS-only, pre-release tree: passes.
  "release-and-store-shipping/scripts/check-release-hygiene.sh|"
  # Takes a theme FILE, not a dir. Its default does not exist until E03 and it
  # exits 0 cleanly today, which is the honest state to record.
  "sunburst-tokens/scripts/check_palette_contrast.sh|"

  # --- source scans over lib/
  "project-structure-and-packages/scripts/check_structure.sh|lib"
  "flutter-architecture/scripts/check_architecture.sh|lib"
  "state-management-riverpod/scripts/ban-legacy-providers.sh|lib"
  "widget-composition/scripts/check-widget-composition.sh|lib"
  "dart3-idioms-and-coding-standards/scripts/check-dart3-idioms.sh|lib"
  "service-boundary-and-native/scripts/check-service-boundaries.sh|lib"
  "adaptive-layout/scripts/check_adaptive.sh|lib"
  "forms-and-input/scripts/check_forms.sh|lib"
  "ci-pipeline-and-gates/scripts/banned-strings.sh|lib"
  "design-system-structure/scripts/check_font_bundling.sh|lib"
  "design-system-structure/scripts/check_raw_values.sh|lib"
  "custom-canvas-and-gestures/scripts/check_painter_hygiene.sh|lib"
  "persistence-drift/scripts/check-drift-confinement.sh|lib"
  "persistence-drift/scripts/check-persistence-bans.sh|lib"
  "error-handling-typed-results/scripts/check-swallowed-catch.sh|lib"
  "error-handling-typed-results/scripts/check-softdelete-parity.sh|lib"
  "local-notifications-scheduler/scripts/check-adhoc-schedule-calls.sh|lib"
  "local-notifications-scheduler/scripts/check-manifest-permissions.sh|lib"
  "local-notifications-scheduler/scripts/check-scheduler-purity.sh|lib"
  "local-notifications-scheduler/scripts/check-single-fln-import.sh|lib"
  "testing-strategy/scripts/check_test_hygiene.sh|lib"
  "widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh|lib test"

  # --- the six sunburst gates
  "sunburst-tokens/scripts/check_raw_values.sh|lib"
  "sunburst-components/scripts/check_component_hygiene.sh|lib"
  "sunburst-shell-screens/scripts/check_shell_boundaries.sh|lib"
  "sunburst-game-surfaces/scripts/check_game_palette.sh|lib"
  "sunburst-motion-and-haptics/scripts/check_motion_tokens.sh|lib"

  # --- i18n: the half that is meaningful at one locale ------------------------
  # This is the gate that keeps E04's RTL work a string job rather than a layout
  # rewrite, so it runs from E01 onward and CI names it as a separate step too.
  "i18n-rtl-l10n/scripts/check_i18n_bans.sh|lib"

  # --- narrowed targets, each for a stated reason -----------------------------
  # Its own header says to point it at "the Flutter-free package or directory
  # that holds the generator" and to narrow TARGET_DIR rather than
  # blanket-ignore. Pointed at lib/ it reports every Flutter import in the app
  # as a determinism defect, which is noise, not a finding.
  # E09 adds lib/games/stroop_rush/domain to this argument when it exists.
  "seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh|lib/core"

  # Checks 1 and 2 (no relative imports, no cross-package lib/src) are already
  # enforced over ALL hand-written code by very_good_analysis's
  # always_use_package_imports and implementation_imports under
  # `flutter analyze --fatal-infos` — and the analyzer, unlike this script,
  # honours analysis_options.yaml's generated-file excludes. gen-l10n emits
  # relative imports into the committed lib/l10n/app_localizations*.dart and
  # offers no option not to, so pointing this at lib/ fails on a file no human
  # wrote and nobody may edit. Narrowed to lib/core, which keeps check 3 — the
  # pure-Dart compile firewall, the part nothing else does — live over the
  # directory it exists for.
  "project-structure-and-packages/scripts/check_import_boundaries.sh|lib/core"
)

# =============================================================================
# SKIP TABLE — "<script path> | <structural reason>"
#
# Every reason names a structural fact. "It fails" is never a reason.
# =============================================================================
SKIP_TABLE=(
  "i18n-rtl-l10n/scripts/check_arb_parity.sh|measured: exits 2 on a directory holding only the template (FAIL: no locale ARB files (app_*.arb) beside the template). E01 ships app_en.arb alone. E04 MOVES THIS ROW TO THE RUN TABLE with the argument lib/l10n, in the same PR that lands app_de.arb, app_fa.arb and app_ckb.arb."
  "ci-pipeline-and-gates/scripts/ci-gates.sh|a runner, not a gate: it re-runs format/analyze/test/build_runner, which the workflow already runs as named steps. Nesting them hides which one failed."
  "codegen-and-toolchain/scripts/regen.sh|mutates the tree. A gate verifies; it never blesses (ci-pipeline-and-gates rule 9)."
  "lint-and-style-config/scripts/lint-gates.sh|a format/analyze wrapper duplicating two named workflow steps."
  "custom-canvas-and-gestures/scripts/analyze.sh|an analyze wrapper duplicating a named workflow step."
  "testing-strategy/scripts/run_tests.sh|duplicates the test step, without the randomized ordering seed CI passes."
  "scaffold-feature-module/scripts/scaffold_feature.sh|a generator, not a check."
  "scaffold-feature-module/scripts/verify_feature.sh|takes ONE feature directory and verifies its internal shape. Run per feature by E08, E09 and E10, not repo-wide; E08 moves it to the run table for the first feature folder."
  "service-boundary-and-native/scripts/check-flavor-graph.sh|requires a BANNED_REGEX argument and a flavor graph to walk. MindForge ships no flavors, so any invocation would be checking a regex against nothing."
  "release-and-store-shipping/scripts/check-ipa-slices.sh|needs a built IPA (measured: 'no IPA found'). E11 owns the release build and moves this row."
  "ads-and-iap-monetization/scripts/check-release-ad-ids.sh|measured: fails because ios/Runner/Info.plist has no GADApplicationIdentifier. It never will — CLAUDE.md's hard constraints are no ads and no IAP, and this whole skill is out of scope. The correct state of this gate is 'not applicable', not 'passing'."
  "value-objects-money-and-units/scripts/check-money-violations.sh|measured: structurally cannot exit 0 on a clean tree. It runs under 'set -euo pipefail' and pipes 'grep' into a reporter, so the FIRST scan that finds nothing aborts the script with status 1 — observed here, printing only its header. MindForge also models no money or units. Not this repository's script to fix."
  "value-objects-money-and-units/scripts/verify-core.sh|a runner, not a gate: it invokes 'dart analyze' and 'dart test' over a pure-core package, duplicating two named workflow steps. MindForge has no money core."
  "dependency-hygiene/scripts/audit-deps.sh|its check 3 locates the lint include by taking the FIRST glob match under ~/.pub-cache/hosted/pub.dev/very_good_analysis-*/ instead of the version resolved in pubspec.lock. Measured here: three versions are cached (10.2.0, 10.3.0, 7.0.0), it picks 10.2.0 lexicographically, does not find analysis_options.10.3.0.yaml in it, and reports the ruleset as disabled. The verdict therefore depends on which unrelated projects share this machine's pub cache, which is not a gate. All four of its checks are covered here by something that resolves correctly: (1) lock committed and not gitignored -> test/policy/repo_layout_test.dart; (2) no exact pins -> dependency_policy_test.dart; (3) the include -> verify-include-pin.sh in the RUN table above, which resolves through the real package config, plus lint_config_test.dart, which compares the pinned filename against pubspec.lock; (4) no banned package in the transitive tree -> dependency_policy_test.dart, over the resolved lock. Its audit_deps.py ALLOW list is still the project's policy record and is still edited here."
  "navigation-and-routing/scripts/check_routing.sh|measured: 'FAIL: no GoRouter(...) found under lib — the app must have one router.' There is no router until E08 builds it. E08 MOVES THIS ROW to the run table."
)

# =============================================================================

pass=0; fail=0; skipped=0; status=0

printf '%s\n' "== skill gates (bash ${BASH_VERSION%%(*}) =="

for row in "${RUN_TABLE[@]}"; do
  script="${row%%|*}"
  args="${row#*|}"
  path="$SKILLS/$script"

  if [[ ! -f "$path" ]]; then
    printf 'FAIL %s — listed in the run table but not on disk\n' "$script"
    fail=$((fail + 1)); status=1
    continue
  fi

  # Word-split $args deliberately: a row may pass more than one argument.
  # shellcheck disable=SC2086
  if output="$(bash "$path" $args 2>&1)"; then
    printf 'RUN  %s%s → exit 0\n' "$script" "${args:+ $args}"
    pass=$((pass + 1))
  else
    code=$?
    printf 'RUN  %s%s → exit %d\n' "$script" "${args:+ $args}" "$code"
    printf '%s\n' "$output" | sed 's/^/       /'
    fail=$((fail + 1)); status=1
  fi
done

for row in "${SKIP_TABLE[@]}"; do
  script="${row%%|*}"
  reason="${row#*|}"
  printf 'SKIP %s — %s\n' "$script" "$reason"
  skipped=$((skipped + 1))
done

printf '\n%d passed · %d failed · %d skipped\n' "$pass" "$fail" "$skipped"
exit "$status"
