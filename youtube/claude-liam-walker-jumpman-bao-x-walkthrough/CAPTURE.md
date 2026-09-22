# CAPTURE.md — walker-jumpman-bao-x walkthrough

## What was captured

| | |
|---|---|
| Game | walker-jumpman-bao-x (extension of nikbearbrown/walker-jumpman) |
| Game commit | `fb75763fd0d6f0343b8e7cc116b304cac244b94f` |
| Source snapshot build_id | `18bc54e6851535d4a4271f55aaf1141b522dd41b413e45840dab2df7b5603213` |
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

## Take event log (measured, from the input log)

| t (s) | x | event |
|---|---|---|
| 0.87 | 64 | start — Enter from the menu |
| 5.10 | 723 | original section cleared — unchanged starter geometry |
| 10.15 | 1532 | attempt 1, no key: jumping across the spring trap |
| 10.40 | 1572 | death — "It goes up when you do" |
| 10.97 | 64 | automatic retry, retries = 1 |
| 18.40 | 1182 | attempt 2: ledges B, C, D climbed |
| 19.18 | 1308 | key taken on ledge D; barrier is a dead end |
| 19.93 | 1225 | walked back left, dropped to the floor, key carried |
| 22.33 | 1553 | spring trap baited from standing |
| 23.10 | 1553 | walking under the raised spike |
| 23.75 | 1648 | key flew to the lock and fitted; the door opened |
| 24.03 | 1694 | complete — 13.1 s, 1 retry |
| 25.43 | 64 | replay from the completion card |
| 26.25 | 151 | pause · 27.23 resume · 28.13 manual R |

Total 1763 ticks = 29.40 s at 60 fps.
