# Cotton Cloud — MindForge design direction 01

**Files**
- `app.html` — all eight MindForge screens as phone mockups
- `system.html` — the design system reference (tokens, scales, components, Flutter mapping)

---

## Personality

Soft, calm, breathable cheer. Candy colour with grown-up manners — this is the brain gym you open to
unwind, not to compete, so nothing on screen raises its voice, including the win screen. Blurred colour
blobs drift behind frosted, pillowy cards on a lilac-white page; every layer floats and there is not a
single border anywhere in the system.

---

## Palette

Two tiers. Primitives are named for what they are; semantic slots are named for the job they do, and a
screen may only ever reference a slot.

### Primitives

| Name | Hex | Token | Role |
| --- | --- | --- | --- |
| Paper | `#FBF7FF` | `--paper` | Page ground on all eight screens. Lilac-tinted white, never pure white. |
| Cloud | `#FFFFFF` | `--white` | Raised surfaces: cards, tiles, the Stroop stimulus panel. |
| Mist | `#F3ECFB` | `--mist` | Sunken surfaces: segmented-control trough, locked tiles. |
| Haze | `#EDE4F7` | `--haze` | Progress and timer tracks, one step deeper than mist. |
| Plum | `#4A3F5C` | `--plum` | All primary text and icons. 9.20:1 on paper. |
| Plum 70 | `#756989` | `--plum-70` | Secondary text: subtitles, helper lines. 4.80:1 on paper. |
| Plum 60 | `#766497` | `--plum-60` | Muted text: small-caps labels, axis ticks, hints. 4.91:1 on paper, 4.51:1 on mist. |
| Plum 45 | `#9C8FB5` | `--plum-45` | Non-text furniture only. 2.83:1 — never text of any size. |
| Plum 20 | `#CFC6DD` | `--plum-20` | Non-text furniture only: home indicator, sheet grabber. |
| Mint | `#7FE3C4` | `--mint` | Success, found tiles, personal best. Ink `#0E7A5F`. |
| Lavender | `#B9A7FF` | `--lav` | Accent and primary action. Ink `#5B44C9`. |
| Peach | `#FFB39B` | `--peach` | Time pressure and warning. Ink `#A84C2C`. |
| Sky | `#8FD3FF` | `--sky` | Information, gradient partner. Ink `#14618F`. |
| Blush | `#FFD6E8` | `--blush` | Streak and delight. Ink `#B33A72`. |

**Deep fill tones.** A pastel base is only 1.4:1 against its own `--haze` track, so a progress fill, a ring
stroke or a chart bar may never use one. Those use `--lav-deep #7B62E0` (3.65:1 on haze), `--sky-deep #2E86C8`
(3.18:1), `--peach-deep #D25936` / `--blush-deep #C9548A` for the warm timer bar, and `--mint-deep #1E9E7D` for
the record bar (3.36:1 on white). None of them is ever text. `--plum-track #9E83BB` is the trough of an *off*
switch — 3.27:1 against the white knob, where haze gave 1.23:1.

Each pastel family ships four tones: `base` (identity), `200` (gradient lift), `tint` (fill behind text),
`ink` (the only tone allowed to *be* text).

### Semantic slots

| Slot | Resolves to | Used for |
| --- | --- | --- |
| `--surface` | `#FBF7FF` | Scaffold background |
| `--surface-raised` | `#FFFFFF` | Anything that floats |
| `--surface-sunken` | `#F3ECFB` | Troughs and wells |
| `--text-primary` | `#4A3F5C` | Headings, numbers, primary-button labels |
| `--text-secondary` | `#756989` | Subtitles, helper copy |
| `--text-muted` | `#766497` | Small-caps labels, inactive nav, axis ticks, hints |
| `--accent` | `#5B44C9` | Every interactive affordance |
| `--success` | `#0E7A5F` | Correct answers, records |
| `--warning` | `#A84C2C` | The running clock |
| `--danger` | `#B0203D` | A wrong tap, and nothing else |
| `--focus-ring` | `#5B44C9` solid | 3px ring on every focusable node. 6.37:1 — at 45% alpha it composited to 2.08:1 and failed SC 1.4.11 |

### Stroop gameplay palette

The game's whole mechanic is colour, so this palette gets its own rules. Three tones per family:
`soft` fills the button, `pure` is the identity chip, `ink` is the label **and** the giant stimulus word.

| Family | Shape | Soft | Pure | Ink | Ink on soft | Ink on white |
| --- | --- | --- | --- | --- | --- | --- |
| Red | Circle | `#FFD8DF` | `#F2546B` | `#B0203D` | 5.17:1 | 6.73:1 |
| Blue | Square | `#D6ECFF` | `#3D9BE9` | `#0F5C8C` | 5.91:1 | 7.17:1 |
| Green | Triangle | `#CFF4E5` | `#2ECC9B` | `#0B7355` | 4.93:1 | 5.84:1 |
| Yellow | Diamond | `#FFEEC2` | `#FFC53D` | `#6B4A00` | 7.01:1 | 8.06:1 |
| Purple *(Blitz)* | Hexagon | `#E7DFFF` | `#A78BFA` | `#5A3EC8` | 5.54:1 | 7.10:1 |
| Orange *(Blitz)* | Star | `#FFE1D3` | `#FF9E7A` | `#7A3410` | 7.29:1 | 9.03:1 |

**Colour words are always drawn in `ink`, never `pure`.** A pure tone only clears 3:1 on white for red —
green sits at 2.05 and yellow at 1.58 — so a round that happened to pick yellow would be unreadable.
Pure tones are only ever solid non-text blocks, where hue rather than luminance carries identity.

**Colour is never the only channel.** Adjacent pure tones separate by as little as 1.02:1, and under
deuteranopia the old red `#B0203D` and yellow `#8A5D00` simulated to the same olive at 1.06:1 — roughly
half of all rounds would have been unwinnable. Three fixes, all shipped:

1. Yellow and orange ink were deepened to `#6B4A00` and `#7A3410`, separating them from red by *lightness* —
   the one channel dichromacy leaves intact.
2. Every identity chip is a **shape** (circle / square / triangle / diamond / hexagon / star) filled in `pure`
   and outlined in that family's `ink`, so the chip carries form, hue and the stimulus tone at once. This ships
   unconditionally, not behind a setting.
3. The **Colour-blind friendly palette** setting adds the matching shape as a corner mark on the stimulus
   panel — the one element that would otherwise carry a single channel. Every answer button also carries its
   name in text.

---

## Type pairing

| Role | Family | Google Fonts name | Weights |
| --- | --- | --- | --- |
| Headings + all numbers | Rounded geometric | **Quicksand** | 500, 600, 700 |
| Body, labels, HUD captions | Humanist sans | **Manrope** | 400–800 |

```
https://fonts.googleapis.com/css2?family=Quicksand:wght@500;600;700&family=Manrope:wght@400;500;600;700;800&display=swap
```

Quicksand's rounded terminals are the cheapest way to make a scoreboard feel friendly, so it carries
every number in the app; its low x-height means it must never be set below 15px. Manrope handles
everything at 11–15px and supplies the tabular figures that stop the HUD clock jittering.

In Flutter both fonts are **bundled in `assets/fonts/`**, never fetched with `google_fonts` — MindForge
has no network permission at all.

---

## When to pick this direction

Pick Cotton Cloud when:

- The product promise is **restorative** — train to feel clearer, not to beat a leaderboard.
- Sessions are short and repeated daily, so the app must never feel like a chore to open.
- You want a **platform** look that hosts ten more games without a re-skin: the chrome is entirely
  shared, and a new game only has to style its board.
- The audience is broad and adult, and loud gamification would put them off.

Pick a different direction when you need arcade adrenaline, dense tabular data, guaranteed performance
on low-end hardware, or a first-class dark mode.

---

## Risks and trade-offs

- **Low contrast is one careless step away, and it already happened once.** The first build routed real
  copy — the in-game Stroop instruction, settings hints, the chart's only numbers, the inactive nav — through
  a 2.83:1 muted token that the docs themselves labelled "never body copy". Three separate documents said the
  right thing and the screens did the wrong thing, which is the argument for a gate rather than a rule:
  `--plum-45` is now furniture-only, `--text-muted` resolves to `--plum-60` at 4.91:1, and the honest reading
  is that this palette has room for **two** text tones, not three. Enforce it with a contrast lint over the
  token→role map, not with review.
- **Non-text contrast is the half everyone forgets.** Focus rings, progress fills, ring strokes and switch
  troughs all owe 3:1 under SC 1.4.11, and every one of them failed in the first build while the *text*
  ratios were immaculate. That is why the deep fill tones exist.
- **Blur and frost cost fill-rate.** Drifting blobs plus `BackdropFilter` on the bottom nav is real GPU
  work on a cheap Android device. Budget for a "flatten blobs to static gradients" path behind the same
  flag as reduce-motion if the floor device drops frames.
- **Low-energy by design.** There is deliberately no shouting register. If marketing later wants an
  aggressive streak-pressure loop or a competitive ladder, this system has no gear for it and will feel
  limp rather than calm.
- **No dark mode.** The argument of the direction is a light, breathable page; a dark Cotton Cloud is a
  different design system, not a token swap. Shipping one later is a project, not a setting.
- **Wide soft shadows eat vertical rhythm.** A 32px blur reads as extra padding, so spacing that looks
  correct in a spec looks cramped in the build. Trust the rendered screen, not the number.
- **Quicksand under 15px turns to mush.** Every small label must be Manrope. This is the single easiest
  mistake for a new contributor to make.
- **11px is the label floor and it costs width.** Uppercase labels at 11px with +0.13em tracking do not fit a
  three-up HUD pill, so tracking drops to +0.08em where the pill is narrow. Dropping the *size* instead — to
  9 or 9.5px, as the first build did — is not available.
