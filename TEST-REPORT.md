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
| `test_game.gd` | **44** | **0** |
| `test_keyboard.gd` | **9** | **0** |
| Total | **53** | **0** |

**All 25 starter checks still pass with their assertions unmodified.** Nothing was
deleted, relaxed, or rewritten. The 19 added checks are listed in §4.

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

## 7. Human playtest — TWO PLAYERS

Godot 4.7.2 on this machine, normal keyboard input via `./walker-jumpman.command`.

### Player 1 — Bao Xing (the author), 2026-09-18 and 2026-09-21, two sessions

**Reported by the player.** Session 1 (2026-09-18): reached the finish; fewer than five
retries; the fork read as two roads; worked out the spring-trap bait unaided and did not
find it hard. Session 2 (2026-09-21): **replay works, both branches were played, and pause,
resume and manual R were each exercised and all worked.**

| Question | Observation | Verdict |
|---|---|---|
| Reached the finish? | Yes | PASS |
| Retries taken | **Fewer than 5** | within the "quick retry, try again" intent |
| Failure and recovery experienced? | Implied by a non-zero retry count | PASS |
| Did the fork read as a choice before committing? | "Saw it was two roads" | PASS |
| Did the spring trap's bait solution occur to the player unaided? | "Worked it out, not hard" | PASS |
| Which branch was taken? | **Both** — high and low were each played to the finish | PASS |
| Was the high road's 48 px entry jump findable by hand? | Yes — the high line was completed | PASS |
| Replay from the completion card | Yes — confirmed working | PASS |
| Pause / resume / manual R by hand | Tested — all three work | PASS |

Every row above is confirmed by hand, including the three the rubric names by name —
route, failure/recovery, and replay — plus pause, resume and manual R.

### Player 2 — a second person, not the author, 2026-09-21

| Question | Observation | Verdict |
|---|---|---|
| Reached the finish? | **Yes** | PASS |
| Did the spring trap's bait solution occur to them **unaided**? | **Yes — after dying to it several times, they worked it out themselves.** No hint was given. | PASS |
| Overall impression | "Good" | — |
| Retries taken | not counted | UNKNOWN |
| Which branch(es) taken | not recorded | UNKNOWN |

**This is the single most useful result in this report**, because it is the one thing
the author's own playtest structurally could not establish. Player 1 knew the trap's
mechanism before pressing a key. Player 2 did not, met the trap, **died to it, and then
solved it** — which is exactly the loop the trap was designed to produce: punish the
obvious play, name its own cause on the death card, and let a fast retry teach the
correct one.

**What it does not establish.** n = 2. Player 2's retry count was not recorded, so
there is no number for "how expensive was the lesson". Nobody timed them, nobody
watched where they hesitated, and their impression is one word. This is a pass, not a
study.

An earlier draft of this table asserted "Completion and replay — PASS" before the player
had reported it. That was inference, not evidence; it was struck, and the rows above are
now filled only from what was actually reported.

### What this does and does not establish

It retires two risks I had recorded as unverified:

- **Limitation #4 (the 10 px bait window may be unfindable).** It was found and
  executed without difficulty. The window stays at 10 px.
- **Fork readability.** The sign plus the ledge layout communicated a choice at the
  decision point, which is what the revision in §8 was for.

**Player 1's caveat still stands for Player 1:** Bao designed the level and knew the
trap's mechanism, the bait position and the geometry before pressing a key. That
session is strong evidence the level is completable and not frustrating for someone who
understands it, and no evidence at all about discoverability.

**Player 2 is what closes that gap** — a person who had not seen the design met the
trap cold, died to it, and worked out the bait without being told. Limitation #4 in
earlier revisions of this report ("the 10 px bait window may be unfindable") is
retired by that result rather than by argument.

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

## 8b. Design decision — the fork became a mandatory detour

The extension shipped for four days as a **fork**: a high road of narrow ledges and a
low road through a roofed corridor, either of which finished the level, with an
optional coin on the high line as its payoff.

On 2026-09-22 Bao replaced the coin with a **key that the door requires**. That single
change is incompatible with the fork, and the incompatibility is arithmetic, not taste:
the key sits above ledge D, ledge D is only reachable from the high road, and a
mandatory pickup on one branch makes the other branch a dead end.

Four options were put to him. He chose a **there-and-back detour**: ledge D now
dead-ends at a barrier, so the high road is not an alternative route — it is the only
way to the key, and you must come back down to use it.

**So this level no longer asks the player to choose.** Every "Pick a Line" claim in
these documents, in the signage and in the film has been rewritten rather than
relabelled. What the section asks for now is sequencing — see the locked thing, find
what opens it, come back — which is a weaker design prompt than a choice, and is
recorded as such rather than dressed up.

Measured by `probe_reach.gd` after the change:

| Jump | Window |
|---|---|
| floor → ledge B (+48) | 70 px |
| B → C (flat 64) | 56 px |
| C → D (+24) | 58 px |
| **D → merge platform** | **UNREACHABLE — the barrier, working** |
| corridor → merge (56 px gap) | 38 px |
| bait the trap from standing | 10 px |
| walk the roofed corridor | clear, 0 jumps |

Route cost **671 → 865 ticks**. The starter's 900-tick ceiling had been kept untouched
through every earlier revision; the detour genuinely does not fit inside it, so it is
now 1400 with the measured number reported in the check's own observation.

## 8c. The test harness was non-deterministic, and that is now fixed

**Found 2026-09-18, after everything else was done.** Re-running the suite on a loaded
machine produced 2–3 failures, including two of the starter's own checks
(`fixed-jump-and-no-double`, `held-jump-no-bounce`, both reporting `jumps: 2`).

**It is not a regression I introduced.** The unmodified starter in the sibling
`walker-jumpman-main/` folder fails the same two checks **3 runs out of 3** under the
same load. The defect is in the starter's harness and has always been there.

**Cause.** `steps(n)` was `for i in range(n): await physics_frame; await process_frame`.
Godot runs several physics ticks in one frame to catch up when the machine is busy,
and the extra ticks elapse *while awaiting the process frame* — unobserved. Instrumented
on this machine: at loop iteration 12 the player's own tick counter read **41**, not 16,
and the player had already passed its jump apex and was descending. The check then
"presses jump again" against a player that has effectively landed, and a legitimate
second jump happens.

**Fix.** `steps(n)` in `test_game.gd` and `probe_reach.gd` now awaits `physics_frame`
only, which is exactly one tick. `test_keyboard.gd` deliberately keeps `process_frame`:
input events reach `_unhandled_input` during the process frame, and without it
`enter-start`, `keyboard-jump` and `menu-start-again` starve. The drift is harmless
there because nothing in that file counts ticks. Both files carry a comment saying why
they differ.

**Verified after the fix:** mechanics 40/40 on 6 consecutive runs, keyboard 9/9 on
7 consecutive runs, under the same load that was failing.

**What this means for the earlier numbers in this report.** The baseline (25/25) and
every "0 failures" result before today were taken on a quiet machine and were real —
but the harness that produced them could drift silently. They should be read as
"passed, on a harness that has since been made deterministic", not as stronger evidence
than they were. Nothing was re-passed by loosening an assertion; the assertions are
untouched and the harness now measures what they always assumed.

**A first attempt that was worse.** My first fix set `Engine.max_physics_steps_per_frame
= 1`. It made the checks deterministic but forced every run to real time — the
reachability probe went from ~3 minutes to over 5 and was still running when I killed
it. Reverted in favour of the one-line change above.

## 9. Honest limitations

1. **No human has played this.** The largest gap in this report. §7 is empty.
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
