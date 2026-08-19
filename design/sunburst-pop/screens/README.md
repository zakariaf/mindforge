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

1. Run the Flutter app on a 390×844 logical-size device (iPhone 14 simulator, or
   `flutter run -d macos` with the window sized to match).
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
