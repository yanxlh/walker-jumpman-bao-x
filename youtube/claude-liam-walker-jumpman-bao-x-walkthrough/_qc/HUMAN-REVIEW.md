# Manual QC — things the machine gates cannot judge

Reviewed by inspecting actual frames and the audio track of the exported master,
not by trusting the gate output.

| Check | Result |
|---|---|
| Container | 3840 x 2160, h264, 30 fps, AAC stereo 48 kHz, 202.0 s |
| Gate V (frame QC) | 26 frames sampled, **0 BLOCKER, 0 MAJOR** |
| `godot-waikthrough --check` | PASS — 19 implemented features, 5 planned, 20 evidence intervals |
| Narration present throughout | sampled at 5/40/80/120/160 s: −28.1, −28.7, −26.9, −29.2, −25.9 dB |
| Outro silent | 190 s: −91.0 dB (correct: the final card carries no narration) |
| `SCRIPTED INPUT` label survives compositing | verified by cropping the top-left of the master at 62 s against `media/B02.mp4` — present and legible |
| Gameplay not center-cut | clip durations were aligned to measured narration; the compositor's "center-cut" notice is gone from the final compile log |
| Gameplay not retimed | action segments play 1.000x; every frozen tail carries `HELD FRAME` |
| Menu and HUD text readable at 4K | inspected: title bar, controls line, fork signage, COIN/RETRIES/timer all legible |
| Bookend order (walker mode) | B00 ask → B01 what-was-built → gameplay body → B10 verdict → B11 your-turn → B12 outro ✓ |
| Outro card | exact title restated, `@NikBearBrown` hardcoded, slug-seeded mascot below the handle, no subline ✓ |

## Asset blocker — reported, not worked around

**The stock outro jingle is missing.** `OUTRO-LOCK.md` requires "existing slug-seeded
regular jingle from `svg/claude/mp3/`". That directory does not exist in this checkout
of brutalist.art — `svg/` is absent entirely. The final card therefore plays **silent**
(−91.0 dB) instead of silent-under-jingle.

Per the skill: "If stock outro assets are missing, report that asset blocker rather
than inventing a substitute." No substitute jingle was generated or sourced. Everything
else on the outro card conforms to the lock.

## Declared QC exemptions, and why they are legitimate

Beats B02–B07 declare `qc.full_bleed: true` and `qc.contrast_regions`.

- **full_bleed** — these beats are a native Godot viewport that fills the frame by
  construction. The title-safe margin test assumes a card with margins. The mechanism
  is per-beat and visible in the beat-sheet diff by design; it is not a reel-wide switch.
- **contrast_regions** — the whole-frame ink average is genuinely low (a light cream
  playfield with a small dark character), which trips the flat-card heuristic. The two
  declared regions are where the essential text actually lives (the HUD bar and footer)
  and **both must still pass**. Underfill, empty-frame and every other check stayed armed,
  and they pass.

Gameplay was **not** relabelled as a source report, and no check was globally disabled.

## What this QC does NOT establish

- That any narration claim is true. That is `FACTCHECK.md`.
- That the feature inventory is complete. 19 features were found by reading the source;
  a missed feature would not show up here.
- That the game is enjoyable. One human has played it — the person who designed it.

## Re-cut 2026-09-18 — verdict beat corrected

B10 was re-recorded and the film recompiled. The earlier cut placed "the high road
still costs the same 671 ticks" in the verdict's untested/caveat half, which framed a
deliberate design choice as a shortfall. The fork trades precision for the coin, not
for speed; the card now carries it under **By design**, between the observed items and
the untested one. Gate V re-run after the recompile.

## Master

```
/Users/yxlh/Documents/csye 7270/walker-jumpman-bao-x/youtube/claude-liam-walker-jumpman-bao-x-walkthrough/exports/landscape/claude-liam-walker-jumpman-bao-x-walkthrough.mp4
sha256  9d82df50cf6d012e5f5138689dcf3dd7dc279dccb5c3b24117ec64e14fb94ec9
```
