# SOURCES

walker-jumpman-bao-x · Bao Xing (bao.xing@northeastern.edu) · CSYE 7270

---

## Starter

**[nikbearbrown/walker-jumpman](https://github.com/nikbearbrown/walker-jumpman)** by
Nik Bear Brown. This project is an **extension of that starter**, not a new game. The
starter supplied:

- the Godot project skeleton, `main.tscn`, and `project.godot`
- `features/player/player.gd` physics (movement, fixed jump, coyote/buffer windows) and
  `tuning.gd`
- `game/session.gd` state machine, level loader, retry and completion logic
- `ui/hud.gd`
- the original level section at x ≤ 960 (two gaps, one spike cluster, two steps)
- `tests/test_game.gd` (25 checks), `tests/test_keyboard.gd` (9 checks),
  `tests/capture_game.gd`, `tests/route_driver.gd`
- `scripts/record-build.cjs`, `walker-jumpman.command`
- the design package: GDD.md, GAME-BRIEF.md, LEVEL-DESIGN.md, PRODUCTION-PLAN.md,
  PLAYTEST-PLAN.md, ASSET-PLAN.md, DESIGN-REVIEW.md, DESIGN-STATUS.json, BUILD-REPORT.md

Commit `0852e7f` in this repository is the starter, imported with file contents
byte-identical. Everything after it is mine. The starter's own documents are retained
unedited; they describe the starter's state, not this extension's.

## What I added

| Area | Change |
|---|---|
| `features/player/player.gd` | `_draw()` fully rewritten — the Lamp-Head Courier. Physics, collider and tuning untouched. |
| `levels/first_steps.json` | Extension geometry at x > 960; spring trap, mandatory key, dead-end barrier; finish moved 916 → 1696 and turned into a locked door; width 960 → 1760. Original geometry unchanged. |
| `game/session.gd` | Spike and finish drawing made data-driven; level width, grid, background and parallax derived from data; hazard collision width derived from the rect; spring-trap state machine, key state machine and door gating; new signage. |
| `ui/hud.gd` | `progress_ratio()` extracted and derived from level data instead of the literal 852; retitled. |
| `tests/route_driver.gd` | Rewritten as a seven-phase machine: the route now reverses direction to fetch the key, so a forward-only jump-mark list no longer describes it. |
| `tests/test_game.gd` | 19 checks added. One starter-era check (`relocated-finish-triggers`) rewritten because the finish is now a locked door; it asserts the locked state first. |
| `tests/probe_reach.gd` | **New.** Reachability probe. |
| `tests/capture_game.gd` | 8 captures added; grounded-frame and HUD-visibility handling. |
| `scripts/record-build.cjs` | Project name, scope, and full screenshot enumeration. |
| Documents | `CHANGE-BRIEF.md`, `TEST-REPORT.md`, `FRICTIONAL.md`, `SOURCES.md`, `README.md`, `film/` — all new. |

## Assets

**All visual assets are original vector drawing in GDScript** (`draw_rect`,
`draw_colored_polygon`, `draw_line`, `draw_string`). There are no image files in the
game, no sprite sheets, and no imported art.

- The Lamp-Head Courier is drawn procedurally in `player.gd::_draw()`. I wrote no
  imported art and used no paid generation service.
- The starter's `design/level-overview.png` / `.svg` are the **starter's** diagrams of
  the starter's proposed course. They are retained as received and **do not depict my
  extension**.
- Fonts are Godot's built-in `ThemeDB.fallback_font`.
- No recovered `jumping-man-godot` art is present in or required by this repository.

**No paid asset generation, no purchased API credits, no third-party media.**

## Tools

| Tool | Version | Use |
|---|---|---|
| Godot Engine | 4.7.2.stable.official.ed1daf0bf | engine, headless test runs, rendered captures |
| Node.js | v25.8.2 | `scripts/record-build.cjs` |
| git | 2.51.0 | version control |
| Claude Code (Opus 5) | — | see below |
| Brutalist `godot-waikthrough` | vendored at `~/brutalist.art` | film workflow, used to render the delivered film |

## AI contribution

Claude Code was used throughout, as the assignment expects. Specifically:

**Claude wrote:** the `_draw()` vector geometry for the courier; `probe_reach.gd`; the
data-driven rewrites in `session.gd` and `hud.gd`; the eight added checks; the capture
additions; the prose drafts of these documents.

**Claude diagnosed:** the head-height/roofing conflict that made the first fork layout
impossible — I would not have found this by inspection.

**I decided:** that the spring trap should arm off a geometry test against the player's
collider box rather than an Area2D, so the rule reads in one line and is testable
without the physics broadphase; that the trap's arming zone belongs directly above the
spike and the bait window should be 10 px; that the coin should become a mandatory key
with a dead-end barrier on the high road, making it a there-and-back detour rather than
a fork; the character concept (and rejected two others on collider-fit grounds);
the level concept; to keep the fork and re-cut geometry rather than touch `tuning.gd`;
to run and archive a pre-edit baseline; to revert the tick budget to the starter's 900;
the final label placement; which sections of `TEST-REPORT.md` and `FRICTIONAL.md` must
stay unfilled until a human plays the build.

**I rejected:** a spec-document/implementation-plan detour before coding; the raised
1200-tick route budget; two earlier label positions; the first character-sheet capture
pass (all four frames were death screens).

Per-entry attribution is in `FRICTIONAL.md`. Commit bodies distinguish my decisions
from Claude's implementation where it is not obvious.

## Film

Beat sheet, script and narration prompts: `film/`. AI narration is permitted by the
assignment. The film **is rendered**: `claude-liam-walker-jumpman-bao-x-walkthrough.mp4`,
3840x2160, 3:40. Reel and all its documents are in
`youtube/claude-liam-walker-jumpman-bao-x-walkthrough/`.

## Collaborators

**Playtester (Player 2), 2026-09-21.** A second person, not the author, played the
build without having seen the design. They met the spring trap, died to it several
times, worked out the bait solution unaided, and finished the level; asked for an
impression, they said "good". Their actual result and its limits are recorded in
`TEST-REPORT.md` §7 — including what was *not* captured (retry count, timings,
hesitation points). They are not named here because no name was supplied for
publication; nothing beyond what they actually did has been attributed to them.

No other person contributed code, design, documents or the film.
