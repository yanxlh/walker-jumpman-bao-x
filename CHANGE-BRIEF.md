# walker-jumpman-bao-x — Change Brief

Author: Bao Xing · CSYE 7270 · Written 2026-09-16, **before implementation**
Starter: [nikbearbrown/walker-jumpman](https://github.com/nikbearbrown/walker-jumpman) @ commit `0852e7f` in this repo
Engine: Godot 4.7.2.stable.official.ed1daf0bf

> **Record discipline.** Everything under "Predictions" below is frozen as written
> on 2026-09-16 before any source edit. Where a prediction turned out wrong, the
> correction is added in `TEST-REPORT.md` and in the "Revisions" section at the
> bottom of this file, with a date. Nothing above the Revisions line is rewritten
> to make a prediction look correct.

---

## 0. Measured baseline (before any edit)

Run on this machine against commit `0852e7f`, unmodified:

| Suite | Result | Evidence |
|---|---|---|
| `tests/test_game.gd` | 25 checks / 0 failures | `evidence/baseline/00-baseline-mechanics.json` |
| `tests/test_keyboard.gd` | 9 checks / 0 failures | `evidence/baseline/00-baseline-keyboard.json` |
| Scripted route | COMPLETE, 0 deaths, **325 ticks**, 5 jumps | same |

These numbers match the starter's own BUILD-REPORT.md, so the baseline is trustworthy
and any later regression is mine.

**Physics envelope I must design inside** (from the starter's tuning + build report):

- `jump_velocity = -320`, `gravity = 960`, `speed = 160`, 60 Hz physics
- Measured jump rise: **56.07 px** (continuous model says 53.33)
- Same-height travel at full speed: **~107 px**
- Player collider: **18 × 28**, feet at `position.y`

---

## 1. Character concept — the Lamp-Head Courier

### What the starter draws

`godot/features/player/player.gd::_draw()` is seven `draw_rect` calls: a dark-blue
body block, a lighter blue inset, an orange sash, two legs driven by
`sin(tick * 0.7)`, and one cream eye that flips with `facing`. The silhouette is a
plain upright rectangle. There is no sprite sheet.

### What I am building

A courier whose head is an oversized angular lamp housing, mounted off-centre on a
narrow body, throwing a translucent light wedge in the direction of travel.

The silhouette changes from *rectangle* to *top-heavy asymmetric wedge-caster*. The
distinguishing features are shape and emitted light, not palette.

### State readability (the thing I am actually being graded on)

| State | Distinguishing cue | Driven by |
|---|---|---|
| Facing right / left | Lamp housing and light wedge both mirror | `facing` |
| Idle | Narrow wedge, legs level, lamp horizontal | `velocity.x ≈ 0` |
| Running | Wedge widens, legs stride | existing `stride` term |
| Jumping / falling | Lamp tilts down, wedge sweeps toward the floor, legs tuck | `not is_on_floor()` |

Each state is distinguishable **without colour** — by outline and wedge angle alone.

### What must not change

- `CollisionShape2D` size `(18, 28)` and offset `(0, -14)` — untouched
- Every value in `tuning.gd` — untouched
- `_physics_process` — untouched
- `collision_layer = 2`, `collision_mask = 1`, `floor_snap_length = 1.0` — untouched

Only `_draw()` is rewritten. The light wedge is decorative geometry with no physics
body; I will assert this in the test report rather than merely claim it.

---

## 2. Level extension — "Pick a Line"

### Constraint I set for myself

**Nothing at x ≤ 960 changes.** Beyond preserving the starter route as the assignment
requires, the existing fixtures in `test_game.gd` reference hard coordinates inside
that region — the coyote ledge at `(478, 285)`, the spike test at `(330, 310)`, the
fall boundary at `(415, 432)`. Leaving the original section byte-identical means those
checks stay valid as genuine regression evidence instead of being rewritten to suit me.

### Proposed geometry

```
                 B━━━━━      C━━━━━        D━━━━━             HIGH  y=272
              (1040-1104) (1168-1232)  (1296-1368)
 ORIGINAL   ┃                                        ┃ GAP  ┃
 ═══════════┫═══════▲HZ1════════▲HZ2═══════════════┫ 56px ┣═══════⚑
  x ≤ 960   ┃   L1 low road  992 – 1344             ┃      ┃ M 1400-1696
                   1120          1248                        finish 1640
```

| Element | Rect | Note |
|---|---|---|
| `L1` | `[992, 320, 352, 64]` | low road floor, reached by a 32 px gap from the original |
| `HZ1` | `[1120, 304, 24, 16]` | 3 spikes |
| `HZ2` | `[1248, 304, 24, 16]` | 3 spikes |
| `GAP-L` | 1344 – 1400 | 56 px, same height |
| `M` | `[1400, 320, 296, 64]` | merge platform |
| `B` | `[1040, 272, 64, 12]` | high ledge 1, +48 rise off L1 |
| `C` | `[1168, 272, 64, 12]` | high ledge 2, 64 px hop |
| `D` | `[1296, 272, 72, 12]` | high ledge 3, bridges GAP-L |
| finish | `[1640, 264, 24, 56]` | moved from `[916, 264, 24, 56]` |
| level width | 960 → **1696** | |

### The decision the section asks for

At x ≈ 992 the player can see both lines and must commit:

- **Low road** — wide, forgiving landings, but two spike clusters to clear and a real
  56 px gap at the end. Three jumps.
- **High road** — no spikes, and ledge D bridges the gap the low road has to jump.
  Paid for with narrow 64–72 px landings and one up-jump. Four jumps.

This is risk-vs-precision, and it deliberately echoes the starter GDD's own
"direct route or risk a detour" pillar without implementing cherries.

### Recoverable-miss design

`B` and `C` sit above *safe* floor. `HZ1` (1120–1144) and `HZ2` (1248–1272) are placed
in the horizontal shadow-free zones between the high ledges on purpose, so a blown
high-road landing drops the player onto clean floor and the run continues.

**`D` is the exception.** Missing `D` drops the player into `GAP-L` and kills them.
That is intentional — the high road should have exactly one committed jump — and I am
recording it here as a known asymmetry rather than discovering it later and calling it
a feature.

### What must not change

Controls, `tuning.gd`, collider, retry timing (`0.55 s`), pause/focus behaviour,
completion and replay, and the entire original route. If any of these has to move I
will say so explicitly and test it, rather than quietly adjusting it to make geometry
work.

---

## 3. Known hard-coded drawing that must be fixed

The assignment warns that moving level data does not move what is drawn. Confirmed by
reading the source — these are real defects, not cosmetics:

| Location | Defect |
|---|---|
| `game/session.gd:201` | spikes drawn at literal `y = 320 / 304`, ignoring the hazard rect |
| `game/session.gd:203-204` | finish pole drawn between literal `y = 320` and `250` |
| `game/session.gd:186-189` | grid loops literal `range(0, 961, 32)` |
| `game/session.gd:185` | background `Rect2(-400, -200, 1800, 900)` |
| `game/session.gd:191` | parallax hills at literal `x = [100, 470, 770]` |
| `ui/hud.gd:24` | progress bar divides by magic number `852` (old finish − spawn) |

All become data-driven from `level.width`, the hazard rects, and the finish rect.

---

## 4. Predictions — failure cases and how I will check them

Frozen before implementation. My honest expectation is that **P1 and P5 are the ones
most likely to bite.**

### P1 — The 48 px up-jump onto ledge B will be tighter than my arithmetic says
Hand-computing the continuous model, a 48 px rise is reachable between t = 0.228 s and
t = 0.439 s, giving a ~75 px takeoff runway on L1. But the continuous model already
disagrees with the engine (53.33 vs measured 56.07), and it ignores the 18 px collider
width, discrete 60 Hz integration, and `floor_snap_length`.
**Prediction:** the usable runway is narrower than 75 px, possibly by a lot.
**Check:** an automated reachability probe that sweeps takeoff x in 2 px steps through
real physics and reports the actual window. If the window is under ~30 px I revise the
geometry — lower the ledge or move it left. **I do not raise the jump.**

### P2 — Walk-under clearance on ledges B and C will be marginal
Ledge bottom is at y = 284, floor at y = 320, so clearance is 36 px for a 28 px player:
only 8 px of margin, and `floor_snap_length = 1.0` plus collider rounding eat into it.
**Prediction:** the player can walk under, but may clip or be stopped at speed.
**Check:** a probe that walks the player at full speed from x = 1000 to x = 1240 under
both ledges and asserts it arrives without losing horizontal velocity or gaining `jumps`.

### P3 — The HUD progress bar will read 100% less than halfway through the level
`hud.gd:24` computes `(player.x - 64) / 852`, where 852 = old finish 916 − spawn 64.
**Prediction:** with the finish at 1640 the bar saturates at x = 916, about 45% of the
way along, and stays full for the entire extension.
**Check:** assert `progress < 1.0` with the player standing at x = 916 after the change.

### P4 — The scripted route will exceed the existing 900-tick budget
Baseline was 325 ticks for 852 px of travel (≈ 0.38 ticks/px). The new route covers
~1576 px, so ≈ 600 ticks before counting the extra jump arcs; the high road adds three
more.
**Prediction:** the low road fits under 900; the high road may not.
**Check:** report actual tick counts for both branches. If I raise the budget I will
state the measured number and the new ceiling in `TEST-REPORT.md` and justify it as a
longer level, not as a loosened assertion.

### P5 — The finish pole will draw correctly by accident, hiding the real bug
My relocated finish keeps the same y-range (264–320) as the original, so the hard-coded
`draw_line(..., 320, ..., 250)` will *look* right at the new x while still being blind
to the finish rect's actual y and height.
**Prediction:** visual inspection alone will not catch this, and I will be tempted to
call it fixed when it is not.
**Check:** after making the drawing data-driven, move the finish to a deliberately odd
y in a throwaway fixture and confirm the pole follows. Revert the fixture afterwards.

### P6 — Camera clamp will hide the finish
`session.gd:153` clamps camera x to `width - 320` = 1376. With the player at 1640 the
viewport shows 1056–1696.
**Prediction:** this one is actually fine, and the finish stays visible.
**Check:** capture a real rendered frame at the finish and look at it.

---

## 5. Out of scope

Cherries, audio, key remapping, settings persistence, moving platforms, Web export,
standalone application, multiplayer. Not attempted, not claimed.

---

## Revisions

*(Appended after implementation. Original predictions above are unedited.)*

<!-- REVISIONS-START -->

### R1 — 2026-09-16 · The proposed geometry in §2 was impossible. Replaced.

The layout drawn in §2 does not work and was never shipped. `tests/probe_reach.gd`
returned `UNREACHABLE` for all three low-road jumps and `BLOCKED at 1116.6` for the
walk-through.

Cause: a jumping player's feet reach y ≈ 264 and their **head reaches y ≈ 236**, while
the high ledges sat at y = 272–284. You cannot jump anywhere beneath them. High-road
hops must be ≤ 107 px apart to be jumpable; a low-road jump arc needs ≥ 107 px of
*unroofed* corridor. Stacked roads that both require jumping cannot coexist at this
tuning.

**This failure mode is not among P1–P6. I did not predict it.**

Shipped layout instead — the roof became the low road's cost:

| Element | Rect |
|---|---|
| low floor `L1` | `[956, 320, 436, 64]` (butts against the original platform; no entry gap) |
| ledge `B` | `[1008, 272, 80, 12]` |
| ledge `C` | `[1152, 272, 64, 12]` |
| ledge `D` | `[1264, 248, 88, 12]` (raised: the longer drop buys horizontal reach) |
| gap | 1392 – 1448 (56 px) |
| merge `M` | `[1448, 320, 312, 64]` |
| hazard | `[1568, 304, 24, 16]` — moved to open sky after the merge |
| finish | `[1696, 264, 24, 56]` · width 1760 |

`tuning.gd` was not touched. Asserted by the `tuning-unchanged` check.

### R2 — 2026-09-16 · Fork entry reworked three times

`B` at x=1024 gave a 24 px entry window; widening it to x=1008 gave 40 px but collapsed
the low-road landing zone to 4 px. Removing the 32 px entry gap and making the floor
continuous gave **70 px**. Consequence accepted, not designed: from the corridor floor
the window back up onto `B` is 4 px, so the high road is entry-committed.

### R3 — 2026-09-16 · Tick budget reverted

P4 predicted the route would exceed 900 ticks. It was briefly raised to 1200, then
reverted to the starter's **900** after measuring 618. No ceiling was loosened.

### R4 — 2026-09-16 · Corridor label moved twice

Original placement at y = 314 sat in the player's walking line. Moving it to y = 348
hid it under the HUD footer (`CanvasLayer`, y 335–360). Final fix states both costs on
the fork sign at the decision point, with a marker at y = 333 on the floor slab.

### Prediction scoring

P1 wrong (too pessimistic, 70 px measured) · P2 partly right · **P3 correct** ·
P4 wrong · **P5 correct and the most useful** · P6 wrong, as expected.
Full detail in `TEST-REPORT.md` §6.

### R5 — 2026-09-17 · Spring trap and reward coin added (scope change, requested after freeze)

Requested by Bao after playing the build. **These were not in the frozen predictions
above and are not retrofitted into them.**

**Spring trap** replaces the static final spike. It sits at `[1568, 304, 24, 16]` and
launches to `raised_y = 240` in 0.18 s, holds 2.6 s, falls in 0.45 s.

The arming rule is plain geometry against the player's own collider box — no trigger
Area2D and nothing drawn on the floor. The zone is `[1558, 244, 38, 40]`, i.e. directly
over the spike and **inside the jump band only**:

- standing, the player occupies y 292–320, so the zone at y 244–284 is unreachable
- airborne, the player reaches y 236–264, which intersects it

Consequence: **walking never arms it; leaving the ground beside it always does.** Jump
across and the spike rises into your own arc. The solution is to bait it from the safe
side and walk underneath, where the raised spike (y 240–256) leaves 36 px of headroom.

Measured bait window: **x 1550–1558, 10 px.** Standing at x ≥ 1560 already touches the
grounded spike. Tuned in three passes at Bao's direction — trigger moved from 104 px
before the spike to directly above it, then the window halved from 20 px to 10 px.

**Reward coin** at `(1320, 206)`, above ledge D (top y = 248), the highest surface in
the game. Standing on D the body occupies y 220–248, so the coin needs a jump; and
because D is high-road-only, **the coin is the high road's payoff**. This directly
addresses limitation #3 in the first TEST-REPORT, which noted the high road cost the
same 618 ticks as the low road and therefore offered no reward.

Route cost rose 618 → **671 ticks** on both branches; the extra 53 ticks are the bait
stop. Still under the starter's original 900-tick ceiling, which remains unchanged.

### R6 — 2026-09-17 · Presentation fixes found by looking at captures

- `FINISH` label overlapped the trap sign; moved above the flag.
- Trap sign text ran into the raised spike; shortened and moved left.
- Guide rail under the spike removed at Bao's request — the trap now has no floor
  marking and no rail, so the sign is the only tell.

<!-- REVISIONS-END -->
