# PROMPTS — Pick a Line: Extending walker-jumpman

Exactly what produced each visual. Gameplay beats have **no prompt**: they are engine
capture, not generation. No paid generation service was used anywhere in this reel.

## Gameplay beats (B02–B07) — captured, not prompted

```bash
godot --path /tmp/wjbx-capture res://capture_main.tscn \
  --write-movie "$REEL/capture/run-01.avi" --fixed-fps 60 -- take1
```

Driver: `capture_driver.gd`, real `InputEventKey` via `Input.parse_input_event`.
No teleporting, no forced completion, no test-only gameplay shortcuts. See `CAPTURE.md`.

## Remotion beats — pattern + props

### B00 · `ClaudeComposerAsk`

```json
{
  "greeting": "Annyeong, Liam",
  "topic": "WALKER · GAME EXTENSION",
  "segment": "Pick a Line — illustrative reconstruction",
  "command": "Please use Walker to convert my game design document about a small, readable 2D platformer — one fixed-height jump, forgiving input windows, unlimited retries — into a playable Godot project. Then extend it: a new main character, and a new section that makes the player choose a route instead of just surviving one.",
  "runningText": "reconstructing the ask — not a transcript of the original session…",
  "folderLabel": "walker-jumpman-bao-x",
  "modelLabel": "Claude",
  "effortLabel": "High",
  "output": [
    "Starter: two gaps, a spike, a flag.",
    "Added: a courier, and a fork.",
    "49 checks, 0 failures."
  ],
  "durationSeconds": 17.344
}
```

### B01 · `BrutalistHesitantWriter`

```json
{
  "contextTitle": "WHAT WAS ACTUALLY BUILT",
  "text": "Bao built a new game.\nThe starter is untouched below x=960.\nTwo additions: a courier, and a fork.",
  "triggerWords": "a new game",
  "replacementWords": "an extension",
  "fontSize": 78,
  "lineSpacing": 2.7,
  "align": "center",
  "seed": "7270",
  "mistakeRate": 2,
  "hesitateWithin": 0,
  "hesitateBetween": 1,
  "charMs": 8,
  "durationSeconds": 19.243,
  "ink": "#3D3929",
  "accent": "#D97757",
  "bg": "#FAF9F5"
}
```

### B08 · `WalkerGodotSetup`

```json
{
  "mode": "flow",
  "title": "Two bands that never meet.",
  "sparkLine": "The trap is geometry, not timing.",
  "source": "godot/features/player/tuning.gd + levels/first_steps.json · measured on Godot 4.7.2",
  "labels": [
    "Standing",
    "Jumping",
    "The gap",
    "Arm zone",
    "Result"
  ],
  "details": [
    "collider occupies\ny 292 → 320",
    "at apex it occupies\ny 236 → 264",
    "nothing between\n264 and 292",
    "rectangle placed at\ny 244 → 284",
    "walk = never arms\njump = always arms"
  ],
  "cueSeconds": [
    0.6,
    5.0,
    9.6,
    14.2,
    19.0
  ],
  "durationSeconds": 25.323
}
```

### B09 · `WalkerGodotSetup`

```json
{
  "mode": "terminal",
  "title": "The probe rejected the first level.",
  "sparkLine": "Change the geometry, not the jump.",
  "source": "godot/tests/probe_reach.gd · real output, Godot 4.7.2.stable.official.ed1daf0bf",
  "command": "godot --headless --path godot --script res://tests/probe_reach.gd",
  "lines": [
    "floor -> B  (+48 rise)      takeoff window 70 px",
    "L1 -> over HZ1             UNREACHABLE",
    "L1 -> over HZ2             UNREACHABLE",
    "L1 -> M (56px gap)         UNREACHABLE",
    "walk-under B and C         BLOCKED at 1116.6",
    "cause: jumping head reaches y=236; ledges sat at y=272",
    "fix: re-cut geometry — tuning-unchanged still PASS"
  ],
  "selected": 4,
  "durationSeconds": 22.528
}
```

### B10 · `ClaudeVerdictArtifact`

```json
{
  "artifactTitle": "Verdict",
  "artifactHeading": "Pick a Line — extending walker-jumpman.",
  "brandLabel": "CSYE 7270 · Bao Xing",
  "artifactLines": [
    "Observed: both routes finish; trap punishes the jump, spares the walk.",
    "Observed: 49 checks pass — the starter's 25 unaltered.",
    "Untested: the only playtester designed the level.",
    "Honest: the high road pays a coin, not time — both cost 671 ticks.",
    "Next: put it in front of someone who has never seen it."
  ],
  "durationSeconds": 28.523
}
```

### B11 · `ClaudeComposerAsk`

```json
{
  "greeting": "Your turn",
  "topic": "WALKER · YOUR TURN",
  "segment": "Measure before you commit",
  "command": "Read this project's tuning values, then write a throwaway script that sweeps real takeoff positions through the real physics and tells me which of my planned jumps actually land. Do not change the jump to make my layout work.",
  "runningText": "sweeping takeoff positions through real physics…",
  "folderLabel": "walker-jumpman-bao-x",
  "modelLabel": "Claude",
  "effortLabel": "High",
  "output": [
    "It rejected a layout I believed.",
    "The fix was geometry.",
    "Never the jump."
  ],
  "durationSeconds": 26.347
}
```

### B12 · `ClaudeTitleOutro`

```json
{
  "title": "Pick a Line — Extending walker-jumpman",
  "slug": "claude-liam-walker-jumpman-bao-x-walkthrough"
}
```

## Narration

Engine: **Kokoro** (`kokoro-onnx`), local, free, no API key. Voice `am_onyx` (Liam, in for Bear).
One mp3 per beat in `mp3/`; measured durations are the master clock and are recorded as
`actual_duration_s` in `beat_sheet.json`. B12 is intentionally silent under the stock jingle
per `OUTRO-LOCK.md`.

## What was NOT used

- No text-to-video or image generation of any kind
- No stock footage, no archival material
- No paid API, no ElevenLabs (this toolkit is Kokoro-only)
- No screen recording of a desktop; the gameplay is Godot's own Movie Maker output
