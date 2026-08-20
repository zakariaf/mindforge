# Sunburst Pop — reference screens

These PNGs are the **implementation targets**. Every screen built in Flutter is compared
against the matching file here before it is considered done.

| File | Screen | Owned by |
|---|---|---|
| `01-home.png` | Home / game hub | shell |
| `02-game-detail.png` | Game detail + difficulty select | shell |
| `03-countdown.png` | Countdown | shell |
| `04-stroop-rush.png` | Stroop Rush gameplay | shell HUD + game board |
| `05-schulte-grid.png` | Schulte Grid gameplay | shell HUD + game board |
| `06-results.png` | Results | shell |
| `07-stats.png` | Stats | shell |
| `08-settings.png` | Settings | shell |

Open `contact-sheet.html` to see all eight side by side.

## Provenance

Rendered from `../app.html` at 390×844 (iPhone 14 class) at 2× device pixel ratio.
`../system.html` remains the authority for **token values**; these screens are the authority for
**layout, spacing rhythm, and composition**. If the two ever disagree, `system.html` wins on values
and the screens get re-rendered.

## Regenerating

```bash
cd design/sunburst-pop
./capture-screens.sh          # rewrites screens/*.png from app.html
```

Run it whenever `app.html` changes, and commit the PNGs with the change. The script pins each screen
with `position: fixed` before capture so no ancestor layout can offset it, and waits on a virtual
time budget so the webfonts land before the shot.

## How to compare during implementation

1. Run the Flutter app on **`MindForge iPhone 14`**, UDID
   `C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6 — the canonical device, and the only one a
   reference PNG can honestly be compared on:

   ```bash
   bash tool/ios_simulator.sh run              # verify, boot, then flutter run
   bash tool/ios_simulator.sh shot <path>.png  # capture
   ```

   It is exactly **390×844 logical points**. No iPhone 16-class simulator matches — iPhone 16 is
   393×852 and 16 Pro is 402×874 — so a screenshot taken on those is a comparison against a
   different canvas, and every spacing judgement made from it is wrong by a few points in a way
   that is invisible until it accumulates. macOS is **not** an option: it is not a platform this
   project targets, and a desktop window is whatever the developer dragged it to.

   **The one honest caveat: the references are 2× and the simulator is 3×.** These PNGs are
   780×1688; the iPhone 14 simulator renders 1170×2532. The *logical* geometry matches exactly and
   the pixel density does not, because no available simulator is 390×844 at 2×. That is a property
   of the target hardware, not a shortcut — which is why the comparison below is structural and
   **never a pixel diff**.

2. Screenshot the built screen.
3. Put it beside the reference and check, in this order:
   - **Structure** — same regions in the same order, same relative heights.
   - **Spacing rhythm** — gaps between blocks match; nothing is tighter or looser than the reference.
   - **Component construction** — 3px ink border and the correct hard-shadow step on every raised
     surface; no blurred shadows.
   - **Type** — same face, weight and relative size per role.
   - **Colour** — sampled hexes match `system.html`.
4. Differences are defects in the implementation, not in the reference. If you believe the reference
   is wrong, change `app.html`, re-run `capture-screens.sh`, and commit that as a deliberate design
   change — never let the code and the reference silently drift apart.

These are static mockups: they show **end states only**. Motion, press physics, haptics and the
transitions between screens are specified by the `sunburst-motion-and-haptics` skill, and cannot be
verified from a screenshot.
