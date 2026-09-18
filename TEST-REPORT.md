# walker-jumpman-bao-x — Test Report

Source revision: see `git log` · Build ID `9b98509592…` (`evidence/build-manifest.json`)
Engine: **Godot 4.7.2.stable.official.ed1daf0bf**, Compatibility / OpenGL, 60 Hz physics
Machine: macOS 26.5.1, Apple M4 Pro · Logical viewport 640 × 360, window 1280 × 720
Starter baseline: commit `0852e7f` (nikbearbrown/walker-jumpman, unmodified)

---

## 1. Baseline before any edit

Run against the unmodified starter so that any later regression is attributable to me.

| Suite | Checks | Failures | Evidence |
|---|---:|---:|---|
| `test_game.gd` | 25 | 0 | `evidence/baseline/00-baseline-mechanics.json` |
| `test_keyboard.gd` | 9 | 0 | `evidence/baseline/00-baseline-keyboard.json` |

Scripted route: COMPLETE, 0 deaths, **325 ticks**, 5 jumps. Matches the starter's own
BUILD-REPORT.md, confirming the baseline is trustworthy.

## 2. After the change

| Suite | Checks | Failures |
|---|---:|---:|
| `test_game.gd` | **40** | **0** |
| `test_keyboard.gd` | **9** | **0** |
| Total | **49** | **0** |

**All 25 starter checks still pass with their assertions unmodified.** Nothing was
deleted, relaxed, or rewritten. The 15 added checks are listed in §4.

Reproduce:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/test_game.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/test_keyboard.gd
/Applications/Godot.app/Contents/MacOS/Godot --path godot --script res://tests/capture_game.gd   # not headless
node scripts/record-build.cjs
```

---

## 3. Required check table

| Check | Result | Evidence |
|---|---|---|
| Startup and controls | **PASS** — normal main-scene launch runs with no script errors; 9/9 keyboard checks inject real key events for start, move, jump, pause, resume, retry, replay, menu, restart | `evidence/keyboard-*.json` |
| Character appearance | **PASS (machine)** — four rendered poses; collider provably unchanged | `screens/05-08`, checks `character-collider-unchanged`, `beam-adds-no-collision-body` |
| Extended route | **PASS** — both branches reach the relocated finish with 0 deaths | `complete-real-route`, `complete-high-road-route` |
| Failure and recovery | **PASS** — real spike contact kills and auto-retries; 20 consecutive retries; replay after completion | `actual-spike-collision`, `twenty-retries`, `replay-idempotent` |
| Camera and presentation | **PASS** — finish and both lines visible and readable at the relocated flag | `screens/09-12` |
| Automated checks | **42 / 0 failures** | §2 |
| **Human playtest** | **NOT YET PERFORMED** | see §7 |

---

## 4. The eight added checks

| ID | Asserts | Observed |
|---|---|---|
| `character-collider-unchanged` | one collision child, `RectangleShape2D` 18×28 at offset (0,−14) | `size (18,28)`, `offset (0,-14)`, `shape_count 1` |
| `beam-adds-no-collision-body` | the light wedge added no collider | `collision_children: 1` |
| `tuning-unchanged` | speed 160, jump −320, gravity 960, coyote 6, buffer 6 | all match |
| `low-corridor-walkable-no-jump` | the roofed corridor is traversable end to end | reached `x=1388.3`, `jumps=0`, still PLAYING |
| `old-finish-position-no-longer-wins` | x=916 no longer completes the level | state stayed PLAYING |
| `relocated-finish-triggers` | x=1700 completes | state COMPLETE |
| `hud-progress-tracks-relocated-finish` | progress bar derives from level data | `0.522` at old finish x, `1.0` at new finish |
| `complete-high-road-route` | the high branch also reaches the finish | COMPLETE, 0 deaths, 671 ticks, 9 jumps, **coin 1** |

Added later with the spring trap and coin (CHANGE-BRIEF R5):

| ID | Asserts | Observed |
|---|---|---|
| `trap-not-armed-by-walking` | walking past never arms the trap | phase `down` at x=1551 |
| `spring-trap-bait-then-walk-under` | bait from the safe side, then walk under | reached x=1641, still PLAYING |
| `spring-trap-actually-rises` | the spike reaches `raised_y` | top reached **240.0** |
| `spring-trap-punishes-the-jump` | jumping across is fatal | DYING at (1566.6, 265.5), reason "It goes up when you do" |
| `coin-not-collectable-on-foot` | the coin is above standing height | walked D end to end, `coins_taken 0` |
| `coin-collected-by-jumping` | a jump from ledge D takes it | `coins_taken 1` |
| `retry-rearms-trap-and-coin` | a death restores both | `coins_taken 0`, phase `down`, spike y 304 |

The two route checks were also tightened to assert the coin split: `complete-real-route`
requires `coins_taken == 0` (the low road cannot reach it) and `complete-high-road-route`
requires `coins_taken == 1`.

### Fixture changes, and why they are not weakening

- `route_driver.gd` gained a `branch` argument and extra jump marks. `Route.new()`
  with no argument still yields the original five marks, so the starter's
  `complete-real-route` keeps its meaning; it now simply runs further.
- **The 900-tick budget was deliberately left alone.** CHANGE-BRIEF P4 predicted an
  overrun and I briefly raised it to 1200. Measurement showed both branches finish in
  **618 ticks**, so I reverted to the starter's 900. No ceiling was loosened.
- No assertion was deleted or softened anywhere.

---

## 5. Measured jump windows

From `tests/probe_reach.gd`, which sweeps real takeoff positions in 2 px steps through
real physics. These are measurements, not arithmetic.

| Jump | Rise / drop | Takeoff window |
|---|---|---:|
| floor → ledge B | +48 | **70 px** |
| B → C | flat, 64 px gap | 56 px |
| C → D | +24, 48 px gap | 58 px |
| D → merge platform | −72 | 54 px |
| low road → merge (56 px gap) | flat | 38 px |
| low corridor walk-through | — | clear, 0 jumps |
| **spring-trap bait from standing** | — | **10 px (x 1550–1558)** |

Standing at x ≥ 1560 already touches the grounded spike, so 1558 is the last safe
bait position and the window is bounded on both sides by geometry, not by tuning.

Run it with:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/probe_reach.gd
```

### The layout this probe rejected

The first geometry had the high ledges directly above a spiked low road. The probe
returned `UNREACHABLE` for all three low-road jumps and `BLOCKED at 1116.6` for the
walk-through. Cause: **a jumping player's head reaches y ≈ 236, while the ledges sat at
y = 272–284.** You cannot jump anywhere beneath them. High-road hops must be ≤ 107 px
apart; a low-road jump arc needs ≥ 107 px of *unroofed* corridor. Those constraints are
mutually exclusive when the roads are stacked.

I revised the geometry — the roofed stretch became a deliberate no-jump corridor, and
the final ledge was raised so the longer drop buys horizontal reach. **The jump was not
touched.** Verified by `tuning-unchanged`.

---

## 6. Prediction outcomes

Scored honestly against `CHANGE-BRIEF.md` §4.

| | Prediction | Outcome |
|---|---|---|
| P1 | 48 px up-jump tighter than the ~75 px arithmetic suggested | **WRONG, too pessimistic.** Measured 70 px, close to the continuous model. The real problem was one I had not predicted at all: the roofing conflict. |
| P2 | Walk-under clearance marginal (36 px vs 28 px player) | **PARTLY RIGHT.** Clearance works — `low-corridor-walkable-no-jump` walks the full 400 px with 0 jumps — but I predicted clipping, and the actual failure was that *jumping* under a ledge is impossible, which I had not thought through. |
| P3 | HUD bar saturates at x = 916 | **CORRECT.** Measured `0.522` at the old finish x after the fix; it would have read `1.0`. |
| P4 | Scripted route exceeds the 900-tick budget | **WRONG.** 618 ticks. Budget reverted to 900. |
| P5 | Finish pole draws correctly by accident, hiding the real bug | **CORRECT, and the most useful prediction.** With the finish left at its original y-range the hard-coded pole rendered fine. Forcing `finish = [1640,208,24,112]` and `hazard h=48` proved the fix is real — `screens/13-p5-datadriven-fixture.png`. Fixture reverted. |
| P6 | Camera clamp hides the finish | **WRONG, as expected.** Finish visible — `screens/12`. |

Two of six predictions were right, two wrong, one partly right, one correctly
predicted as a non-issue. The single most consequential problem — the roofing
conflict — **was not predicted by me at all** and was found only by running the probe.

---

## 7. Human playtest — PERFORMED 2026-09-18

Player: **Bao Xing** (the author), on this machine, Godot 4.7.2, normal keyboard
input via `./walker-jumpman.command`. One session.

| Question | Observation | Verdict |
|---|---|---|
| Reached the finish? | Yes | PASS |
| Retries taken | **Fewer than 5** | within the "quick retry, try again" intent |
| Did the fork read as a choice before committing? | "Saw it was two roads" | PASS |
| Was the high road's 48 px entry jump findable? | Yes — took the high road | PASS |
| Did the spring trap's bait solution occur to the player unaided? | "Worked it out, not hard" | PASS |
| Did the 10 px bait window feel unfair? | No | PASS |
| Completion and replay | Reached the finish; completion card shown | PASS |

### What this does and does not establish

It retires two risks I had recorded as unverified:

- **Limitation #4 (the 10 px bait window may be unfindable).** It was found and
  executed without difficulty. The window stays at 10 px.
- **Fork readability.** The sign plus the ledge layout communicated a choice at the
  decision point, which is what the revision in §8 was for.

**The caveat that matters: this player designed the level.** Bao knew the trap's
mechanism, the bait position, and the geometry before playing. That makes this
strong evidence that the level is *completable and not frustrating for someone who
understands it*, and weak evidence about **discoverability for a first-time player**.
The honest reading is: one informed playtest passed; no naive playtest has happened.

An automated input route is still not a playtest, and the route fixtures in
`test_game.gd` are not counted as one here.

## 8. Inspect-and-revise cycle

**Observation.** Looking at `screens/11-low-corridor.png`, the label "LOW / NO ROOM TO
JUMP" at y = 314 sat directly in the player's walking line; the courier rendered on top
of the text in every run of the corridor. A label teaching a constraint was illegible
at exactly the place it was supposed to teach it.

**Revision 1 — made it worse.** Moved the label down onto the floor slab at y = 348.
Re-captured: it vanished entirely. The HUD footer is drawn on a `CanvasLayer` occupying
y 335–360, so the label was hidden underneath it.

**Revision 2 — the actual fix.** The information belongs at the decision point, not in
the corridor. The fork sign now reads:

```
03 / PICK A LINE
UP: three tight landings.
ACROSS: no headroom, one committed gap.
```

with a short `LOW / NO HEADROOM` marker at y = 333, on the dark slab, clear of both the
walking line and the HUD footer. Verified in `screens/09-fork-decision.png`.

**Third cycle (spring trap, three passes at Bao's direction).** The first trap armed
from x = 1464, 104 px before the spike — it sprang while the player was nowhere near
it, which read as unrelated. Moved the arming test to a zone directly above the spike
and restricted it to the jump band. Measured bait window came out 20 px; halved to
**10 px** on a second instruction by moving the zone's left edge from 1548 to 1558.
The guide rail drawn under the spike was then removed, so the trap has no floor
marking and no rail — the sign is the only tell.

**Second cycle (capture quality).** `screens/10-high-road-ledges.png` originally froze
mid-jump, so it documented a blur rather than the landing it was meant to show. The
capture loop now waits for `is_on_floor()` before freezing.

---

## 9. Honest limitations

1. **No human has played this.** The largest gap in this report. §7 is empty.
2. **The high road still saves no time — but it now pays.** Both branches cost the same
   671 ticks, because horizontal speed is constant and jumps do not change it. That was
   limitation #3 in the first version of this report: the fork traded precision for
   nothing. The reward coin above ledge D fixes the *payoff* (high road 1 coin, low road
   0, both asserted) but **not** the timing. The fork is still not a shortcut.
3. **Missing ledge D kills you.** B and C sit above safe floor so a miss is recoverable,
   but D overhangs the gap. This asymmetry was recorded in the change brief before
   implementation, not discovered afterwards and rationalised.
4. **The high road is entry-committed.** Once you drop to the low road you cannot climb
   back up — the measured window from the corridor floor onto B is 4 px. I kept this
   because it makes a miss a legible demotion rather than a retry-spam loop, but it was
   a *consequence of the geometry I discovered*, not an intention I started with.
5. **The light beam extends past the collider.** It is translucent, draw-only, and
   proved colliderless by `beam-adds-no-collision-body`, but a player could in principle
   misread it. No human has told me whether they do.
6. **`probe_reach.gd` is a diagnostic, not an assertion.** It prints windows; it does not
   fail a build. The binding route checks are in `test_game.gd`.
7. **Coverage of the extension is route-based.** Both branches are verified along one
   fixed input line each. Off-route behaviour in the new section — odd approach speeds,
   backtracking, jumping into ledge corners — is unverified.
8. **No export.** Source-only. No Web build, no standalone application.
9. **The 10 px bait window is validated only by an informed player.** §7 found it
   easy, but by someone who knew where to stand. Still unvalidated for a naive player.
10. **The trap's timing constants held for one player.** `rise 0.18 s`, `hold 2.6 s`,
   `fall 0.45 s` were chosen for the scripted route; one human run did not report the
   hold expiring. Not stress-tested against a hesitant player.
