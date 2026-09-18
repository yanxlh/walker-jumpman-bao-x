# CAPTURE.md — walker-jumpman-bao-x walkthrough

## What was captured

| | |
|---|---|
| Game | walker-jumpman-bao-x (extension of nikbearbrown/walker-jumpman) |
| Game commit | `8c646723578adbd589340602c5d304cf40a2f409` |
| Source snapshot build_id | `585b05e7f6d9d55673973778ba8a269c7c68d3021de1484374e170e42f3d9cd6` |
| Engine | Godot 4.7.2.stable.official.ed1daf0bf, Compatibility/OpenGL |
| Capture method | Godot Movie Maker, `--write-movie`, `--fixed-fps 60` |
| Output | 3840 x 2160, 60 fps, native (verified with ffprobe on a probe take before the full run) |
| Logical resolution | **640 x 360** — this is a low-res 2D game crisply scaled by Godot's `canvas_items` stretch to 4K. It is not a 4K-authored canvas, and it is not an upscaled video. |
| Driver | `capture_driver.gd` (in the capture copy only) |
| Input log | `capture/run-01-inputs.jsonl` |

Movie Maker renders offline. **The frame rate in the file is not evidence of
real-time performance.**

## Isolation

Captured from an isolated copy at `/tmp/wjbx-capture`, not the shipped project.
The only differences from the shipped `godot/` tree are:

1. `window/size/window_width_override` 1280 -> 3840 and `window_height_override`
   720 -> 2160, so Movie Maker writes native 4K.
2. `capture_driver.gd` added.

**No gameplay code, tuning, level data, collision or scene was changed for the
capture.** The shipped project is untouched; `git status` in the game repo stays
clean across the capture.

## How the driver plays

`capture_driver.gd` instantiates the real main scene (`game/session.gd`) and drives
it with **real `InputEventKey` objects fed to `Input.parse_input_event`** — the same
path a physical keyboard takes, and the same technique the starter's own
`test_keyboard.gd` uses.

It does **not**:

- teleport the player or set its position
- set `state`, force completion, or award the coin
- touch `player.test_control` / `test_axis` / `test_jump_pressed` (the unit-test
  shortcuts that the starter's mechanical checks legitimately use)
- disable collision or alter any hazard

It **does** read `player.position.x`, `player.is_on_floor()`, `player.velocity.x` and
`game.state` in order to decide *when* to press a key. The capture reference permits
this ("A driver may observe position/state to choose inputs").

It asserts the expected outcome at every stage and exits non-zero on failure;
exhausting a frame budget is not treated as success.

## This is SCRIPTED INPUT, not a playtest

Every clip cut from `run-01` is labeled `SCRIPTED INPUT` on screen. It demonstrates
that the features work; it says nothing about how the game feels.

The human playtest is separate and is recorded in the game's
`TEST-REPORT.md` §7 — played by Bao Xing on 2026-09-18, completed with fewer than
five retries. That is the only playtest, and the player designed the level.

## Take 1 event log (measured, from the input log)

| t (s) | x | event |
|---|---|---|
| 0.87 | 64 | start — Enter from the menu |
| 5.10 | 723 | original section cleared (two gaps, one spike) — unchanged starter geometry |
| 8.83 | 1321 | high road: ledges B, C, D |
| 9.17 | 1374 | reward coin collected, 1/1 |
| 10.15 | 1532 | spring trap: jumping across it (the punished play) |
| 10.40 | 1572 | death — "It goes up when you do" |
| 10.97 | 64 | automatic retry, retries = 1 |
| 19.58 | 1372 | low road: roofed corridor, then the 56 px gap |
| 20.68 | 1548 | stopped short of the trap |
| 20.83 | 1553 | hopped straight up beside the spike to spring it |
| 21.60 | 1553 | walking under the raised spike |
| 22.53 | 1694 | complete — 11.6 s, 1 retry, coin 0/1 on this attempt |

Total 1442 ticks = 24.03 s at 60 fps.

Note the coin reads 0/1 at the finish: attempt 1 took the high road and collected it,
then died on the trap; the retry reset it and attempt 2 finished by the low road,
which cannot reach the coin. That is the design working, not a bug.
