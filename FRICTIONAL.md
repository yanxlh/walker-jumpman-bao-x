# FRICTIONAL — honest log

walker-jumpman-bao-x · Bao Xing · CSYE 7270

**How to read this.** Entries are in the order they happened. Each says what was tried,
what was expected, what actually happened, and what changed as a result. Where a
decision was mine and where it was Claude's is marked explicitly. Sections marked
**[TO BE COMPLETED BY BAO]** are mine to write after I play the build; Claude organised
the log and wrote up the sessions it ran, but it must not invent my experience.

---

## Entry 0 — Deciding what to build

**Human (me).** Claude offered three character concepts and three level-extension
shapes. I picked the lamp-head courier over a shelled beetle and a cloaked wanderer,
and the high/low fork over a descending drop and a spike ladder.

Why the courier: Claude flagged that the beetle's squat body would leave visible empty
space in the top of a 28 px-tall collider, which is the "misleading visual/collision
mismatch" the rubric penalises, and that the cloak's flare would extend past the
collider on the trailing side. The lamp reads as top-heavy, which *fills* the tall box
rather than fighting it.

Why the fork: it was the only one of the three that poses a decision rather than a
skill check.

**Rejected:** Claude's first instinct was to present a written spec document and a
separate implementation plan before touching code. I told it to execute. The change
brief covers the same ground and the assignment already supplies the spec.

---

## Entry 1 — The starter does not run as downloaded

**Expected:** unzip, open in Godot, play.

**What happened:** `walker-jumpman.command` failed. The zip unpacks with
`project.godot` at the repo root and every document in a nested `walker-jumpman-main/`
subfolder, but the launcher execs `--path "$DIR/godot"`, `scripts/record-build.cjs`
walks `root/godot`, and `test_game.gd` writes to `res://../evidence`. Three separate
tools all assume a `godot/` + `evidence/` sibling layout that the download does not have.

**Response:** restored the layout those tools already expect, and committed it as
commit 1 with the file contents byte-identical, so the restructure is visible and
separable from my actual changes.

**Learned:** the starter's own BUILD-REPORT was written against a working layout. The
distribution, not the project, is what is broken. Worth checking before assuming the
code is at fault.

---

## Entry 2 — Baseline first

**Human decision (me).** Run the starter's own 34 checks *before* editing anything.
Claude proposed going straight to the character rewrite.

**Result:** 25 mechanics + 9 keyboard, 0 failures, route 325 ticks — matching the
starter's published BUILD-REPORT exactly. Archived to `evidence/baseline/`.

**Why it mattered later:** when I had 33 checks passing at the end, I could say the 25
original ones were still passing *unmodified* rather than hoping so.

---

## Entry 3 — Freezing predictions before building

I wrote six predicted failure cases into `CHANGE-BRIEF.md` before any source edit.
Final score: **two right, two wrong, one partly right, one correctly a non-issue.**

The honest part: the single biggest problem in the whole build — the roofing conflict
in Entry 4 — **was not on my list at all.** Writing predictions did not let me foresee
it. What it did do was stop me quietly rewriting history afterwards, because P1 and P4
are on the record as wrong.

---

## Entry 4 — The level design I picked is geometrically impossible

**This is the entry that actually taught me something.**

**Expected:** the fork Claude and I agreed on — narrow high ledges directly above a
spiked low road, so a missed landing drops you into the gauntlet. I hand-computed the
landing windows and they looked fine.

**What happened:** `probe_reach.gd`, a sweep of real takeoff positions through real
physics, returned:

```
L1 -> over HZ1      UNREACHABLE
L1 -> over HZ2      UNREACHABLE
L1 -> M (56px gap)  UNREACHABLE
walk-under B and C  BLOCKED at 1116.6
```

Every low-road jump was impossible and the walk-through died on spikes.

**Diagnosis.** A jumping player's feet reach y ≈ 264 and their **head reaches y ≈ 236**.
The ledges sat at y = 272–284. You cannot jump anywhere underneath them. And the two
constraints are irreconcilable: high-road hops must be ≤ 107 px apart to be jumpable,
while a low-road jump arc needs ≥ 107 px of *unroofed* corridor. Stacked parallel roads
that both require jumping cannot exist at this tuning. The design was not mistuned; it
was impossible.

**What I changed.** Not the jump. The assignment forbids buffing jump strength to
rescue geometry, and it would have been the wrong fix anyway. Instead the roofed
stretch became the low road's actual cost — a corridor you can walk but cannot jump in
— and the last ledge was raised to y = 248 so the longer drop buys more horizontal
reach on the way down. Re-probed: all seven jumps reachable, corridor clear.

**Human vs AI.** Claude wrote the probe and diagnosed the head-height cause. The call
to keep the fork concept and re-cut the geometry around the constraint, rather than
abandon the fork or touch `tuning.gd`, was mine.

**Learned:** I would have shipped an unplayable level. My arithmetic was not wrong
about the jump arc; it was wrong about what else was in the way. Measuring the thing
you are standing under matters as much as measuring the thing you are jumping to.

---

## Entry 5 — Three tries at the fork entry

Even after the redesign the numbers kept fighting each other:

| Attempt | floor → B | low-road entry |
|---|---:|---|
| B at x=1024 | 24 px window | 16 px of landing floor before B's shadow |
| B widened to x=1008 | 40 px | collapsed to a 4 px window |
| Entry gap removed, floor made continuous | **70 px** | trivial — you just keep running |

**Response:** dropped the 32 px entry gap entirely and butted the new floor against the
original platform. The fork became "hop up, or keep running," which is a cleaner read
anyway. The original section still was not edited — the new slab starts at x=956 and
overlaps the starter's platform by 4 px.

**Consequence I accepted rather than fixed:** from the corridor floor the window back up
onto ledge B is 4 px, i.e. once you are on the low road you are committed. I kept it
because it turns a missed landing into a legible demotion instead of a retry-spam loop.
But I want to be clear in `TEST-REPORT.md` §9 that this was a *consequence I noticed*,
not an intention I started with.

---

## Entry 6 — The prediction that paid off

P5 said the finish pole would render correctly *by accident* and I would be tempted to
call it fixed. That is exactly what would have happened: I kept the relocated finish at
the same y-range as the original, so the hard-coded
`draw_line(..., 320, ..., 250)` looked right at the new x.

Forcing a deliberately wrong fixture — `finish = [1640, 208, 24, 112]`, hazard height 48
— proved the data-driven rewrite actually works
(`evidence/screens/13-p5-datadriven-fixture.png`). Fixture reverted.

**Learned:** "it looks right" and "it is right" came apart here, and only an
adversarial fixture told them apart.

---

## Entry 7 — A fix that made things worse

Looking at `screens/11-low-corridor.png` I saw the label "LOW / NO ROOM TO JUMP" sitting
in the player's walking line, with the courier drawn on top of it.

Moved it down to the floor slab at y = 348. Re-captured: **gone entirely.** The HUD
footer is a `CanvasLayer` covering y 335–360 and was drawn over it.

Second attempt worked, and changed my mind about the problem: the information belongs
at the *decision point*, not in the corridor. The fork sign now states both costs
before you commit, with a small marker at y = 333 on the dark slab.

**Learned:** I moved the label twice before asking what it was for. The first move
treated it as a collision problem; it was an information-placement problem.

---

## Entry 8 — Where I did not take Claude's output

- **Raising the tick budget.** Claude raised the route ceiling from 900 to 1200 when
  extending the route, citing P4. Measurement showed 618 ticks. I had it revert to 900:
  an untouched ceiling that still passes is stronger evidence than a raised one.
- **The character sheet captures.** Claude's first pass spawned the poses at x=300,
  which is on the starter's spike cluster at x=320. All four "character" frames were
  death screens with the pose hidden behind the retry card. Caught by looking at the
  images.
- **The spec-document detour.** Rejected, see Entry 0.

---

## Entry 9 — What is still not done

- **Played 2026-09-18** — see Entry 11. The remaining hole is that the only playtester
  is the person who designed the level.
- **The Brutalist skill is now installed** — vendored from
  `github.com/nikbearbrown/brutalist.art` to `~/brutalist.art` and symlinked into
  `~/.claude/skills`. Its render toolchain is not: `ffmpeg`, `kokoro-onnx`, `mutagen`,
  `manim`, `faster-whisper`, the Remotion `node_modules` and the Kokoro voice model are
  all still missing, so nothing has been rendered.
- **Open question I have not resolved:** the high road saves no time (both branches run
  618 ticks, because jumps do not change horizontal speed). Is a fork whose branches
  cost the same still a real decision? I think yes — it trades precision against nerve
  — but I would rather a playtester told me than assume it.

---

## Entry 10 — 2026-09-17 · I played it, and asked for two changes

I ran the build and asked for a reward to chase and for the last spike to become a
trap rather than an obstacle. Both were scope additions **after** the change brief was
frozen, so they are recorded as CHANGE-BRIEF R5, not folded into the predictions.

What took iteration was the trap's arming rule, and all three corrections were mine:

1. Claude's first version armed from x = 1464, **104 px before the spike.** It sprang
   while I was nowhere near it, which read as a random event rather than a trap.
   Told it to put the detection directly above the spike.
2. It also drew a yellow pressure plate on the floor. I did not want a plate — the
   arming should be a position match against the character, with no floor marking.
3. The rebuilt zone gave a measured 20 px bait window. Too generous; told it to halve
   it. Final window is **10 px (x 1550–1558)**, bounded on the right by the fact that
   standing at 1560 already puts you inside the grounded spike.
4. Finally I had the guide rail under the spike removed, so the trap has no tell at all
   except the sign.

**What I learned from the numbers.** The reason this trap works at all is a coincidence
of the starter's tuning I had not appreciated: standing, the player occupies y 292–320;
at the top of a jump, y 236–264. Those two bands do not overlap. So a zone placed at
y 244–284 is *provably* unreachable on foot and *provably* reachable in the air —
walking can never arm it and jumping always will. That is not a tuned threshold, it is
geometry, which is why I asked for the arming test to be a plain rectangle intersection
against the collider box rather than an Area2D.

**A bug worth recording.** Wiring the coin reproduced the exact defect the starter's
BUILD-REPORT describes for deaths: re-enabling `monitoring` on respawn replays the
pre-reset overlap, so the coin got re-collected one frame after a retry had restored
it. The fix was to put the pickup behind the starter's existing `contact_settle_ticks`
gate. I had read that comment days earlier and still walked into the same trap.

**Still open:** I have not verified that a 10 px bait window is findable by someone who
has not read the code. I asked for it to be that tight; I have not yet proved it is
fair. That belongs in the playthrough section below, unfilled.

---

## Entry 11 — 2026-09-18 · My own playthrough

Played it start to finish with the keyboard. **Completed, fewer than 5 retries.**

Three things I specifically wanted to check, because I had written all three into the
report as unverified risks:

- **Did the fork read as a choice?** Yes — at x≈960 I could see it was two roads.
  That is the revision from Entry 7 working; the earlier version had the explanation
  buried in the corridor where the character walked over it.
- **Did I work out the spring trap unaided?** Yes, and it was not hard. This is the one
  that surprised me, because I had asked Claude to halve the bait window to 10 px and
  then written a limitation saying I was not sure that was fair. It was fine.

**A correction I had to make.** Claude's first draft of TEST-REPORT §7 listed
"Completion and replay — PASS" and "high road entry findable — yes". I told it three
things: I finished, under five retries, the fork read as two roads, and the trap bait
was not hard. I never said which branch I took, and I never said I pressed Enter to
replay. Those rows were inferred, not reported. They are now marked UNTESTED BY HAND.
Catching this mattered more than the result itself — a playtest table that quietly
grows extra passes is worse than a short one.

**The thing I have to be honest about:** I designed this. I knew the trap sprang on
leaving the ground, I knew roughly where to stand, and I knew the coin was on the top
ledge. So "not hard" from me is much weaker evidence than "not hard" from someone who
has never seen it. I have written it that way in TEST-REPORT §7 rather than letting a
clean pass stand unqualified. The remaining gap is a naive playtester, and I have not
got one.

**Nothing changed as a result.** The playthrough confirmed the design rather than
correcting it, so there is no revision to record here — which is itself worth stating
plainly instead of inventing a tweak to look responsive.

---

## Entry 12 — 2026-09-18 · Everything was green, so I re-ran it

After the film was done I ran the suite once more before calling it finished. **2
failures.** Two of them were the *starter's* own checks, which had passed all day.

My first instinct was that I had broken something with the last round of edits. I had
not — but the way I found that out matters more than the answer: I ran the **unmodified
starter** in the sibling folder and it failed the same two checks, 3 out of 3. So the
defect predates me.

Then I guessed wrong twice:

1. Guessed physics catch-up was making `steps(1)` advance several ticks. Wrote a probe.
   It reported exactly 10 ticks for `steps(10)` — **hypothesis disproved.** (The machine
   happened to be idle for those few seconds.)
2. Guessed it was test-order pollution. Ran the failing check in isolation — it passed.

What actually found it was printing the player's own tick counter inside the loop: at
iteration 12 the tick read **41**, not 16. So hypothesis 1 had been right all along and
my probe had simply been too lucky to show it. The extra ticks slip past during
`await process_frame`.

Fixed it the wrong way first — capped `Engine.max_physics_steps_per_frame` to 1, which
worked but forced every run to real time and made the probe unusably slow. The right
fix was one line: stop awaiting the process frame in the tick loop.

Then that fix broke the keyboard tests (8/9, 8/9), because input events are delivered
on the process frame. So the two files now differ on purpose, each with a comment
saying why.

**Learned, and slightly uncomfortable:** every "0 failures" I reported today was true,
but it came off a harness that could silently drift. I got clean numbers partly because
the machine was quiet. If I had not re-run the suite one last time on a busy machine, I
would have submitted a green report built on a measurement I did not understand.

## Entry 13 — 2026-09-21 · Second session: replay, and both lines

Went back and played the parts I had not reported. **Replay works** — Enter on the
completion card starts a fresh session. And I played **both branches** to the finish,
which also settles the row I had left open about whether the high road's 48 px entry
jump is findable by hand: it is, I did it.

That closes the three things the rubric names by name — route, failure/recovery, replay.
Pause, resume and manual R I still have not exercised by hand; they are machine-checked
and they appear in the film, and TEST-REPORT §7 says exactly that rather than rounding
up to a full sweep.

Worth noting against Entry 11: the first session I reported four things and Claude's
draft turned them into seven PASS rows. This time the table only grew where I actually
reported something.

---

## Entry 14 — 2026-09-21 · Someone else played it, and the trap taught them

I got a second person to play it. They had not seen the design.

They hit the spring trap, **died to it several times, and then worked out the bait
themselves** — nobody told them. Then they finished the level. Asked what they thought:
"good".

**Why this is the most useful thing in the whole report.** Every playtest row I could
fill myself was compromised by the same fact: I knew where to stand before I pressed a
key. I wrote the trap's arming rectangle. So my "worked it out, not hard" said nothing
about whether the trap is discoverable — it only said the level is completable by
someone who already understands it. The honest limitation I had been carrying was
exactly that, and it is the one thing I could not fix by testing harder myself.

Player 2 fixed it by dying. That is the loop the trap was built for: punish the obvious
play, put the reason on the death card ("It goes up when you do"), make the retry
cheap, and let the player teach themselves. Seeing it actually happen to someone else
is different from asserting it works.

**What I did not get, and will not pretend I did.** I did not count their retries. I
did not time them or watch where they hesitated. Their whole verbal feedback is one
word. So the report says "it works for two humans", not "it is well tuned", and the
film's next-improvement line now asks for instrumented death positions rather than
"find a stranger" — because the stranger part is done and something more specific is
the real next step.

**Consequence I had to deal with:** the rendered film's Verdict said "the only human
playtest was by the person who designed the level". That sentence became false the
moment Player 2 finished. Re-recorded the beat and recompiled rather than leaving a
claim in the film that the documents contradict.

---

## Human / AI contribution summary

| | Mine | Claude's |
|---|---|---|
| Character concept | chose lamp-head courier from three options; rejected beetle on collider-fit grounds | drew the option set, wrote the `_draw()` vector geometry |
| Level concept | chose the fork; chose to keep it after the probe rather than abandon it or touch tuning | proposed the option set, cut the revised coordinates |
| Diagnosis | — | wrote `probe_reach.gd`, identified the head-height/roofing cause |
| Baseline discipline | required a pre-edit baseline run | ran it, archived it |
| Tick budget | required the revert to 900 | had raised it to 1200 |
| Capture bugs | spotted the death-frame character sheet | wrote and fixed the capture script |
| Label placement | called the second fix (move to the decision point) | made both edits |
| Predictions | frozen before build, scored honestly afterwards | wrote them up |
| Documents | decided what must stay unfilled | drafted the prose |
| Playtesting | played both sessions myself; recruited and observed Player 2 | recorded only what was reported, and flagged the film line that Player 2 invalidated |
| Spring trap | required detection above the spike, no plate, no rail, and the window halved to 10 px | implemented the state machine and the geometry test |
| Reward coin | placed it on the highest ledge so the high road finally pays | implemented pickup, HUD counter, retry reset |

**Accepted** from Claude: the probe methodology, the `_draw()` geometry, the data-driven
rewrite of `session.gd`/`hud.gd`, the eight added checks.
**Modified:** the fork geometry (three iterations), the label placement, the capture
spawn positions.
**Rejected:** the spec-document detour, the raised tick budget, the first two label
positions, the trap's original 104 px-early trigger, the floor pressure plate, the
20 px bait window, and the spike guide rail.
