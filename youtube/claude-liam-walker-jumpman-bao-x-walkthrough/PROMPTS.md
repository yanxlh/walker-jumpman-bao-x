# PROMPTS — The Key and the Door: Extending walker-jumpman

Exactly what produced each visual. Gameplay beats have **no prompt**: they are engine
capture, not generation. No paid generation service was used anywhere in this reel.

## Gameplay beats (B02–B08) — captured, not prompted

```bash
godot --path /tmp/wjbx-capture res://capture_main.tscn \
  --write-movie "$REEL/capture/run-01.avi" --fixed-fps 60
```

Driver: `capture_driver.gd`, real `InputEventKey` via `Input.parse_input_event`.
No teleporting, no forced completion, no key awarded, no door opened by fiat, and no
test-only gameplay shortcuts. See `CAPTURE.md`.

## Remotion beats — pattern + props

### B00 · `ClaudeComposerAsk`

```json
{
  "greeting": "Annyeong, Liam",
  "topic": "WALKER · GAME EXTENSION",
  "segment": "The Key and the Door — illustrative reconstruction",
  "command": "Please use Walker to convert my game design document about a small, readable 2D platformer — one fixed-height jump, forgiving input windows, unlimited retries — into a playable Godot project. Then extend it: a new main character, and a new section built around a locked door and the key that opens it.",
  "runningText": "reconstructing the ask — not a transcript of the original session…",
  "folderLabel": "walker-jumpman-bao-x",
  "modelLabel": "Claude",
  "effortLabel": "High",
  "output": [
    "Starter: two gaps, a spike, a flag.",
    "Added: a courier, a key, a door.",
    "53 checks, 0 failures."
  ],
  "durationSeconds": 17.344
}
```

### B01 · `BrutalistHesitantWriter`

```json
{
  "contextTitle": "WHAT WAS ACTUALLY BUILT",
  "text": "Bao built a new game.\nThe starter is untouched below x=960.\nAdded: a courier, a key, a locked door.",
  "triggerWords": "a new game",
  "replacementWords": "an extension",
  "fontSize": 74,
  "lineSpacing": 2.7,
  "align": "center",
  "seed": "7270",
  "mistakeRate": 2,
  "hesitateWithin": 0,
  "hesitateBetween": 1,
  "charMs": 8,
  "durationSeconds": 19.733,
  "ink": "#3D3929",
  "accent": "#D97757",
  "bg": "#FAF9F5"
}
```

### B09 · `WalkerGodotSetup`

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

### B10 · `WalkerGodotSetup`

```json
{
  "mode": "terminal",
  "title": "Every landing chosen by measurement.",
  "sparkLine": "Change the geometry, not the jump.",
  "source": "godot/tests/probe_reach.gd · real output, Godot 4.7.2.stable.official.ed1daf0bf",
  "command": "godot --headless --path godot --script res://tests/probe_reach.gd",
  "lines": [
    "floor -> B  (+48 rise)      takeoff window 70 px",
    "B -> C      (flat 64px)     takeoff window 56 px",
    "C -> D      (+24, 48px)     takeoff window 58 px",
    "D -> M      (barrier)       UNREACHABLE   <- by design",
    "L1 -> M     (56px gap)      takeoff window 38 px",
    "bait-from-standing          bait window 10 px",
    "walk-under B and C          clear, 0 jumps"
  ],
  "selected": 3,
  "durationSeconds": 21.419
}
```

### B11 · `ClaudeVerdictArtifact`

```json
{
  "artifactTitle": "Verdict",
  "artifactHeading": "The Key and the Door — extending walker-jumpman.",
  "brandLabel": "CSYE 7270 · Bao Xing",
  "artifactLines": [
    "Observed: trap punishes the jump, spares the walk; the key needs a jump.",
    "Observed: the door will not open without the key. 53 checks pass.",
    "Tested cold: a second player died to the trap, then solved it unaided.",
    "By design: key mandatory, ledges dead-end — a there-and-back errand.",
    "Thin: n = 2, no counts, no timings. Next: log where deaths happen."
  ],
  "durationSeconds": 33.835
}
```

### B12 · `ClaudeComposerAsk`

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
    "Human: the courier, the key-and-door call, the geometry re-cut.",
    "Claude Code: the drawing, the probe, the state machines, the checks.",
    "Narration is AI. Build shown: commit fb75763 · Godot 4.7.2."
  ],
  "durationSeconds": 46.933
}
```

### B13 · `ClaudeTitleOutro`

```json
{
  "title": "The Key and the Door — Extending walker-jumpman",
  "slug": "claude-liam-walker-jumpman-bao-x-walkthrough"
}
```

## Narration

Engine: **Kokoro** (`kokoro-onnx`), local, free, no API key. Voice `am_onyx` (Liam, in
for Bear). One mp3 per beat in `mp3/`; measured durations are the master clock and are
recorded as `actual_duration_s` in `beat_sheet.json`. B13 is intentionally silent.

## What was NOT used

- No text-to-video or image generation of any kind
- No stock footage, no archival material
- No paid API, no ElevenLabs (this toolkit is Kokoro-only)
- No screen recording of a desktop; the gameplay is Godot's own Movie Maker output
