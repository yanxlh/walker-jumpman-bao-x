# walker-jumpman-bao-x — Pick a Line

**Bao Xing** · CSYE 7270 · Godot **4.7.2.stable.official.ed1daf0bf** · GDScript

An extension of **[nikbearbrown/walker-jumpman](https://github.com/nikbearbrown/walker-jumpman)**
by Nik Bear Brown — not a new game. The starter is commit `0852e7f` in this repository,
imported with file contents byte-identical. Everything after it is mine.

My additions: a new main character (**the Lamp-Head Courier**) and a new playable
section (**Pick a Line**, a high/low fork) with the finish relocated past it.

![The Lamp-Head Courier at the fork, deciding between the high ledges and the low corridor](evidence/screens/09-fork-decision.png)

---

## Run it

Requires Godot 4.7.2 installed at `/Applications/Godot.app`. No .NET runtime, no
external assets, no paid services.

```bash
./walker-jumpman.command
```

Or open `godot/project.godot` in the Godot editor, or:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path godot
```

## Controls

Unchanged from the starter.

| Key | Action |
|---|---|
| **A / D** or **← / →** | Move |
| **Space** | Jump (fixed height, no double jump) |
| **Enter** | Start / resume / play again |
| **R** | Retry |
| **Esc** or **P** | Pause |
| **M** | Main menu (from pause or completion) |

Retries are unlimited. There are no lives.

---

## What I changed

### The character — Lamp-Head Courier

The starter's runner is a stack of rectangles with one eye. Mine is a courier with an
oversized angular lamp housing jutting forward over a narrow torso, counterweighted by
a satchel on the trailing side, throwing a translucent light wedge in the direction of
travel. The silhouette changes from *rectangle* to *top-heavy and asymmetric*.

Four states are readable **without relying on colour**:

| | Cue |
|---|---|
| Facing | housing, satchel and beam all mirror |
| Idle | narrow beam, level legs, housing horizontal |
| Running | beam widens, torso leans into travel, legs stride |
| Airborne | housing tips nose-down, beam sweeps to the floor, legs tuck |

Only `_draw()` was rewritten. **`_physics_process`, `tuning.gd` and the 18 × 28 collider
are untouched**, and three automated checks assert that rather than claiming it.

<p align="center">
<img src="evidence/screens/06-char-run-right.png" width="45%" alt="Courier running right, camera zoomed 4x for inspection">
<img src="evidence/screens/08-char-jump-right.png" width="45%" alt="Courier airborne, lamp tipped down, camera zoomed 4x for inspection">
</p>

*Running and airborne. Camera zoomed 4× for these inspection frames only — the game is
never played zoomed.*

### The level — Pick a Line

A new section at **x > 960**. The original section is byte-identical, so the starter's
coyote (478,285), spike (330,310) and fall-boundary (415,432) fixtures remain valid
regression evidence.

```
                                    D━━━━━
                       C━━━━━                    (y=248)
          B━━━━━                                 (y=272)
 ORIGINAL ═══════════════════════════════┓ 56px ┏━━━━━━▲━━━⚑
  x ≤ 960     low road: roofed, no headroom      gap    spikes  finish 1696
```

At the end of the original floor the route forks:

- **High road** — three narrow ledges (80 / 64 / 88 px) reached by a 48 px up-jump.
  No spikes, and the last ledge drops you clear of the gap. Tight landings.
- **Low road** — keep running. The ledges overhead form a **roofed corridor you cannot
  jump in**, and it ends at a committed 56 px gap.

Both lines merge onto a final platform with one shared spike cluster before the flag.
Missing ledge B or C drops you onto the low road and the run continues; missing D
drops you into the gap.

Finish moved 916 → 1696. Level width 960 → 1760.

### Drawing bugs fixed

The starter hard-coded coordinates that silently break when level data moves:

- spikes drawn at literal `y = 320 / 304`, ignoring the hazard rect
- finish pole drawn between literal `y = 320` and `250`
- grid looped to literal `961`; background `Rect2(-400,-200,1800,900)`; parallax at `x = [100,470,770]`
- HUD progress divided by the literal `852` (old finish − spawn)

All now derive from level data. Verified with a deliberately wrong fixture, because
the relocated finish kept the original y-range and would otherwise have rendered
correctly *by accident* — `evidence/screens/13-p5-datadriven-fixture.png`.

---

## Verification

**42 automated checks, 0 failures** — 25 starter checks still passing with their
assertions unmodified, plus 8 new, plus 9 keyboard checks.

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/test_game.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/test_keyboard.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/probe_reach.gd
node scripts/record-build.cjs
```

Both branches complete with zero deaths in **618 ticks**, under the starter's original
900-tick ceiling, which was deliberately left unchanged.

Geometry was chosen by measurement. `tests/probe_reach.gd` sweeps real takeoff
positions through real physics; it **rejected my first layout**, proving that a jumping
player's head reaches y ≈ 236 while the ledges sat at y = 272–284, so parallel roads
that both require jumping are unbuildable at this tuning. I revised the geometry rather
than the jump.

Full detail: **[TEST-REPORT.md](TEST-REPORT.md)** · predictions frozen before building:
**[CHANGE-BRIEF.md](CHANGE-BRIEF.md)** · honest log: **[FRICTIONAL.md](FRICTIONAL.md)** ·
credits: **[SOURCES.md](SOURCES.md)**

---

## Known limitations

1. **No human has played this build.** `TEST-REPORT.md` §7 is deliberately empty. An
   automated input route is not a playtest.
2. **The film is not yet rendered.** The required Brutalist `godot-waikthrough` skill is
   not installed on this machine (checked `~/.claude/skills` and the plugin cache). The
   beat sheet, script and gameplay evidence are staged in [`film/`](film/); rendering is
   blocked until the course-provided skill is available.
3. **The high road saves no time.** Both branches take exactly 618 ticks — horizontal
   speed is constant and jumps do not change it. The fork trades precision against
   nerve; it is not a shortcut.
4. **The high road is entry-committed.** Once on the low road the window back up onto
   ledge B is 4 px. Kept deliberately, but it was a consequence discovered by
   measurement, not an original intention.
5. **Missing ledge D kills you**, unlike B and C. Recorded in the change brief before
   implementation.
6. **Extension coverage is route-based.** One fixed input line per branch. Off-route
   behaviour in the new section is unverified.
7. **Source only.** No Web export, no standalone application.

## Film

**Not yet rendered — see limitation 2.**

| | |
|---|---|
| Filename | *pending* |
| SHA-256 | *pending* |
| Link | *pending — course media storage* |

Beat sheet and script: [`film/BEAT-SHEET.md`](film/BEAT-SHEET.md),
[`film/SCRIPT.md`](film/SCRIPT.md).

## Repository layout

```
godot/                  the playable Godot project
  features/player/      player.gd (courier), tuning.gd (untouched)
  game/session.gd       state machine + data-driven drawing
  levels/               first_steps.json — original + extension geometry
  ui/hud.gd
  tests/                test_game.gd, test_keyboard.gd, probe_reach.gd, capture_game.gd, route_driver.gd
evidence/               test receipts, baseline/, screens/, build-manifest.json
film/                   beat sheet, script, narration prompts
scripts/record-build.cjs
CHANGE-BRIEF.md  TEST-REPORT.md  FRICTIONAL.md  SOURCES.md
STARTER-README.md + GDD.md, GAME-BRIEF.md, ...   the starter's own documents, unedited
```

The starter's design documents describe the **starter's** state and proposed course.
They are retained as received and do not describe this extension.
