# FACTCHECK — The Key and the Door

game-source revision shown in the film: `fb75763fd0d6f0343b8e7cc116b304cac244b94f`
source snapshot build_id: `18bc54e6851535d4a4271f55aaf1141b522dd41b413e45840dab2df7b5603213`
engine: Godot 4.7.2.stable.official.ed1daf0bf

Every numeric claim in the narration was re-derived from the shipped source, the
committed evidence files, or a measured run on this machine.

## Verified claims

| Beat | Claim | Verification |
|---|---|---|
| B00 | starter is "two gaps and a spike" | solids/hazards at x<=960 in `first_steps.json`: floors [0,448],[512,736],[784,960] = two gaps; one hazard [320,304,24,16] |
| B00 | the prompt is a reconstruction | stated in narration AND on screen (`segment` and `runningText`) |
| B01 | "unmodified below x=960" | `git diff 0852e7f HEAD -- godot/levels/first_steps.json`: first five solids and hazard [320,...] unchanged; all additions x>=956 |
| B01 | "fifty-three checks, twenty-five of them the starter's own, unaltered" | 44 mechanics + 9 keyboard = 53, 0 failures; baseline in `evidence/baseline/` records the original 25 |
| B01 | cherries/audio/settings/export not built | `coverage.json` lists all four as `planned` with reasons |
| B03 | the spike "looks jumpable, and it is not" | check `spring-trap-punishes-the-jump`: DYING with reason "It goes up when you do" |
| B04 | "forty-eight pixels up, then two hops" | ledge B top 272 vs floor 320 = 48; B->C and C->D are the two hops |
| B05 | "the key sits above standing height" | standing on D (top 248) the body occupies y 220–248; the key at (1320,206) spans 197–215. Check `key-not-collectable-on-foot` |
| B05 | "the ledge dead-ends at a barrier" | solid `[1352,136,12,124]`; check `barrier-dead-ends-ledge-d` stops the walk at x=1341.3; probe reports `D -> M UNREACHABLE` |
| B06 | "a corridor with no headroom" | ledge undersides at y=284/260; a jumping head reaches y≈236. Check `low-corridor-walkable-no-jump`: 400 px walked, jumps==0 |
| B06 | "one committed gap" of 56 px | floor ends 1392, merge platform starts 1448 |
| B07 | "at the dock line the key leaves him" | `key.dock_x = 1600` in the level data; check `key-docks-and-opens-the-door` |
| B07 | "the door opens; now the level can be finished" | completion is gated on `door_open and goal.overlaps_body(player)`. Checks `door-locked-without-key` and `open-door-finishes` |
| B08 | "R counts no death" | starter check `manual-restart-not-death`, unaltered |
| B09 | standing y 292–320 | collider 18x28 at offset (0,-14); feet at 320 |
| B09 | jump apex y 236–264 | measured rise 56.07 px (starter BUILD-REPORT, reproduced by `fixed-jump-and-no-double`) |
| B09 | arming rectangle y 244–284 | `rising_hazards[0].arm_zone = [1558,244,38,40]` |
| B09 | "walking never arms it, leaving the ground always will" | 284 < 292 (no overlap grounded); 244..264 overlaps the apex band. Checks `trap-not-armed-by-walking`, `spring-trap-punishes-the-jump` |
| B10 | every probe window on screen | verbatim from a real run of `godot/tests/probe_reach.gd`: 70 / 56 / 58 / UNREACHABLE / 38 / 10 / clear |
| B11 | "two humans finished it, the second had never seen the design" | `TEST-REPORT.md` §7, Players 1 and 2 |
| B11 | "the key is mandatory and the ledges dead-end" | `first_steps.json`: key required by `door_open` gate; barrier `[1352,136,12,124]`; probe reports `D -> M UNREACHABLE`. Change recorded in `TEST-REPORT.md` §8b and `CHANGE-BRIEF.md` R7 |

## Judgments, not facts — flagged as such

- **B03 "looks jumpable".** A design intention. The grounded spike *is* jumpable in
  isolation; the trap is what makes the attempt fatal.
- **B11 "a there-and-back errand".** A description of the route's shape, not a
  measurement. The verifiable parts of it — the key is mandatory, the ledges dead-end —
  are each checked and listed above.

## Deliberately NOT claimed

- No claim that the level is fun or well tuned. Two playtests are reported with their
  limits: n = 2, no retry counts, no timings.
- No claim of coverage beyond the 20 features in `coverage.json`; 5 are named unbuilt.
- No claim about real-time performance. Movie Maker renders offline; `CAPTURE.md` says so.
- No claim that the B00 prompt was ever sent.

## Capture integrity

- `capture/run-01.avi` sha256 recorded in `coverage.json`; clips are cut from its
  transcode with no retiming — action plays at 1.000x.
- Every gameplay clip carries `SCRIPTED INPUT`; frozen tails carry `HELD FRAME`.
- One capture-only deviation (`test_mode = true`, suppressing the window-focus
  auto-pause and nothing else) is disclosed in `CAPTURE.md`.
