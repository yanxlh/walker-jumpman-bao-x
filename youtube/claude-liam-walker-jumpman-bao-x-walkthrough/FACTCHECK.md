# FACTCHECK — Pick a Line: Extending walker-jumpman

game commit: `8c646723578adbd589340602c5d304cf40a2f409`
source snapshot build_id: `585b05e7f6d9d55673973778ba8a269c7c68d3021de1484374e170e42f3d9cd6`
engine: Godot 4.7.2.stable.official.ed1daf0bf

Every numeric claim in the narration was re-derived from the shipped source, the
committed evidence files, or a measured run on this machine. Nothing below is quoted
from memory.

## Verified claims

| Beat | Claim | Verification |
|---|---|---|
| B00 | Starter is "a small Godot platformer with two gaps and a spike" | `godot/levels/first_steps.json` solids/hazards at x<=960: floors [0,448], [512,736], [784,960] = two gaps; one hazard [320,304,24,16] ✓ |
| B00 | The prompt is a reconstruction, not a transcript | Stated in narration AND on screen (`segment` = "illustrative reconstruction", `runningText` = "not a transcript of the original session") ✓ |
| B01 | "unmodified below x nine hundred and sixty" | `git diff 0852e7f HEAD -- godot/levels/first_steps.json` shows the first five solids and hazard [320,...] unchanged; all additions are x>=956 ✓ |
| B01 | "Forty-nine automated checks pass, twenty-five of them the starter's own, unaltered" | `test_game.gd` 40 + `test_keyboard.gd` 9 = 49, 0 failures. Baseline `evidence/baseline/00-baseline-mechanics.json` records the original 25; their assertions are unchanged in the current file ✓ |
| B01 | "Cherries, audio, settings and an export are still not built" | `coverage.json` lists all four as `planned` with reasons ✓ |
| B02 | "None of this was touched — the starter's own geometry, kept byte for byte" | As B01 ✓ |
| B03 | "three narrow ledges" | Solids [1008,272,80,12], [1152,272,64,12], [1264,248,88,12] — widths 80/64/88 ✓ |
| B03 | "a coin only this line can reach" | Coin at (1320,206) above ledge D (top y=248). Checks `complete-real-route` asserts coins_taken==0 on the low branch and `complete-high-road-route` asserts ==1 ✓ |
| B04 | "the last spike … springs up into the arc" | Visible on screen; check `spring-trap-punishes-the-jump` observes DYING at (1566.6, 265.5) with reason "It goes up when you do" ✓ |
| B05 | "retry counter at one" | HUD reads RETRIES 01 in the clip; input log records `automatic retry: back at spawn, retries=1` at t=10.967 ✓ |
| B06 | "A roofed corridor you cannot jump in" | Ledge undersides sit at y=284/260; a jumping player's head reaches y≈236, so any jump beneath them collides. Check `low-corridor-walkable-no-jump` walks 400 px with jumps==0 ✓ |
| B06 | "one committed gap" of 56 px | Floor ends 1392, merge platform starts 1448 ✓ |
| B07 | "R does not count as a death" | Check `manual-restart-not-death` (starter's own, unaltered) plus the driver's own assertion `game.deaths != 0 -> fail` ✓ |
| B08 | "Standing … y two ninety-two to three twenty" | Collider 18x28 at offset (0,-14); feet at position.y=320 → occupies 292..320 ✓ |
| B08 | "At the top of a jump … two thirty-six to two sixty-four" | Measured jump rise 56.07 px (starter BUILD-REPORT, reproduced by `fixed-jump-and-no-double`): 320-56.07=263.93 → 235.93..263.93 ✓ |
| B08 | "arming rectangle … at two forty-four to two eighty-four" | `rising_hazards[0].arm_zone = [1558,244,38,40]` → y 244..284 ✓ |
| B08 | "walking can never spring it; leaving the ground always will" | 284 < 292, so no overlap while grounded; 244..264 overlaps the apex band. Checks `trap-not-armed-by-walking` (phase stays "down") and `spring-trap-punishes-the-jump` ✓ |
| B09 | Probe output lines | Verbatim from a real run of `godot/tests/probe_reach.gd` against the rejected layout, recorded in `CHANGE-BRIEF.md` R1 and `TEST-REPORT.md` §5 ✓ |
| B09 | "a check named tuning-unchanged proves the jump was never touched" | Check exists and passes; `git diff 0852e7f HEAD -- godot/features/player/tuning.gd` is 0 lines ✓ |
| B10 | "both cost six hundred and seventy-one ticks" | `complete-real-route` ticks=671, `complete-high-road-route` ticks=671 ✓ |
| B10 | "the only human playtest was by the person who designed the level" | `TEST-REPORT.md` §7, played 2026-09-18 by Bao Xing, caveat stated there ✓ |

## Judgments, not facts — flagged as such

- **B04 "It looks jumpable."** A design intention and an aesthetic judgment, not a
  measurement. It is true that the grounded spike *is* jumpable in isolation (the
  measured takeoff window before the trap existed was 54 px); the trap is what makes
  the attempt fatal. Narration presents it as a setup line, not as a verified claim.
- **B06 "the whole puzzle."** Judgment about design, not evidence.
- **B10 "Next: put it in front of someone who has never seen it."** A recommendation.

## Deliberately NOT claimed

- No claim that the level is fun, fair, or discoverable. The one playtest is stated
  with its caveat, and B10 names discoverability as untested.
- No claim of a complete walkthrough beyond the 19 features in `coverage.json`; the
  5 planned features are named as not built.
- No claim about real-time performance. Movie Maker renders offline; `CAPTURE.md`
  states this.
- No claim that the B00 prompt was ever sent. It is labeled a reconstruction on screen.

## Capture integrity

- `capture/run-01.avi` sha256 recorded in `coverage.json`; clips in `media/` are cut
  from its transcode `capture/run-01.mp4` with no retiming — action plays at 1.000x.
- Every gameplay clip carries a burned-in `SCRIPTED INPUT` label; the frozen tail of
  each carries `HELD FRAME`.
- The single capture-only deviation from the shipped project (`test_mode = true`,
  which suppresses the window-focus auto-pause and nothing else) is disclosed in
  `CAPTURE.md`.
