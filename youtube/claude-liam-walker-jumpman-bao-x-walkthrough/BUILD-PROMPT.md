# BUILD-PROMPT — how this reel was produced

Reproducible from the game repo and brutalist.art. Every step below was actually run.

```bash
# 0. the game under test
GAME="$HOME/Documents/csye 7270/walker-jumpman-bao-x"
REEL="$GAME/youtube/claude-liam-walker-jumpman-bao-x-walkthrough"

# 1. verify the build the film will describe
/Applications/Godot.app/Contents/MacOS/Godot --headless --path "$GAME/godot" --script res://tests/test_game.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path "$GAME/godot" --script res://tests/test_keyboard.gd
node "$GAME/scripts/record-build.cjs"          # -> evidence/build-manifest.json

# 2. isolated 4K capture copy (window override only; no gameplay change)
cp -R "$GAME/godot" /tmp/wjbx-capture && rm -rf /tmp/wjbx-capture/.godot
#    project.godot: window_width_override 1280->3840, height 720->2160
#    + capture_driver.gd, capture_main.tscn

# 3. capture, input-driven, native 3840x2160
cd /tmp/wjbx-capture && WJBX_LOG="$REEL/capture/run-01-inputs.jsonl" \
  /Applications/Godot.app/Contents/MacOS/Godot --path . res://capture_main.tscn \
  --write-movie "$REEL/capture/run-01.avi" --fixed-fps 60 -- take1

# 4. seekable master, then per-beat clips with labeled holds (see SHOTLIST.md)
ffmpeg -i "$REEL/capture/run-01.avi" -vf fps=30 -c:v libx264 -crf 15 -g 30 -an "$REEL/capture/run-01.mp4"

# 5. contracts and audio
cd ~/brutalist.art
./art godot-waikthrough --check "$REEL"
python3 runtime/scripts/generate_audio_kokoro.py "$REEL"
python3 runtime/scripts/remotion_scenes.py "$REEL"

# 6. master
./art final "$REEL" --height 2160 --fps 30 --out "$REEL/exports/landscape"
./art godot-waikthrough --check "$REEL"
```

## Order that matters

1. **Checks before capture.** The film may only describe a build whose tests pass.
2. **Capture before authoring.** Beat durations are set from measured clip lengths and
   measured Kokoro audio, not estimated and then forced.
3. **Audio before render.** Narration is the master clock; a gameplay clip is extended
   with a labeled hold when narration is longer, never slowed.
4. **Check again after render.**

## Deviations from the shipped game, in full

One: `game.test_mode = true` in the capture driver, which suppresses session.gd's
window-focus auto-pause. An offline Movie Maker render is never focused, so without it
the capture pauses two seconds in. It changes no physics, geometry, hazard or outcome.
Disclosed here, in `CAPTURE.md`, and in `FACTCHECK.md`.
