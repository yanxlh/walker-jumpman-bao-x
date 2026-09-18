> **SUPERSEDED — planning artefact, not the delivered film.**
> Written before the Brutalist skill was available. The film that shipped is documented in
> `../youtube/claude-liam-walker-jumpman-bao-x-walkthrough/`. See `film/README.md`.
> Placeholders like `<<…>>` below were never resolved because this version was not rendered.

# Film beat sheet — walker-jumpman-bao-x

**Status: STAGED, NOT RENDERED.** The Brutalist `godot-waikthrough` skill with the
`walker` modifier is not installed on this machine. Rendering follows the skill's
native 4K landscape workflow and quality checks once the course-provided version is
available. Nothing below may be rendered by substituting a different pipeline without
saying so on screen and in the README.

**Revision demonstrated:** commit at time of render (see README) · build ID
`9b98509592…` · Godot 4.7.2.stable.official.ed1daf0bf
**Narration:** AI (Liam), permitted by the assignment. Labelled in the outro.
**Format:** landscape, native 4K. Duration follows the explanation — target ~4:30, no
padding to hit a runtime.

---

## Labelling rules (non-negotiable)

Every frame falls into exactly one of these, and the label is burned in:

| Label | Applies to |
|---|---|
| *(none)* | Real gameplay, real time, keyboard-driven |
| `SCRIPTED INPUT` | Anything driven by `route_driver.gd` / `capture_game.gd` |
| `HELD FRAME` | A frozen capture held on screen while narration continues |
| `CAMERA ZOOM 4×` | The character sheet frames (05–08) — the game is never played zoomed |
| `FIXTURE — NOT SHIPPED` | The P5 data-driven proof (13), which uses deliberately wrong level data |
| `TERMINAL — REAL OUTPUT` | Test runs, transcribed verbatim |

No completion may be faked. No defect may be hidden by changing the game for the film.
If the human playtest has not happened by render time, the film says so.

---

## Beats

| # | Time | Beat | On screen | Label |
|---|---|---|---|---|
| 1 | 0:00 | **Walker opening** | Title card: walker-jumpman-bao-x · Pick a Line | — |
| 2 | 0:08 | **The starter** | `git log` showing commit `0852e7f`; starter running, original rectangle runner, original finish at x=916 | TERMINAL — REAL OUTPUT |
| 3 | 0:25 | **Summary of the ask** | One card: new character, new section, keep the controls | — |
| 4 | 0:38 | **The character** | Four-pose sheet (05–08); then the courier in live play | CAMERA ZOOM 4× on the sheet only |
| 5 | 0:58 | **Collider proof** | `player.gd` diff scrolled; then terminal: `character-collider-unchanged`, `beam-adds-no-collision-body`, `tuning-unchanged` all PASS | TERMINAL — REAL OUTPUT |
| 6 | 1:15 | **The fork** | Live play arriving at x≈960, sign visible, both lines on screen | — |
| 7 | 1:30 | **High road** | Live play: up onto B, hop to C, hop to D — the two-plus new landings | — |
| 8 | 1:48 | **Failure and recovery** | Live play: a real missed landing → drop to the low road, run continues; then a real spike death → auto-retry card → restart | — |
| 9 | 2:10 | **CAUSE AND EFFECT (main)** | See below | mixed |
| 10 | 2:55 | **Low road + completion** | Live play: roofed corridor, the committed 56 px gap, final spike, flag | — |
| 11 | 3:15 | **What I tested** | Terminal: 42 checks / 0 failures; probe window table | TERMINAL — REAL OUTPUT |
| 12 | 3:35 | **Verdict** | Three lines, see script | — |
| 13 | 4:00 | **Your turn** | The probe idea, generalised | — |
| 14 | 4:15 | **Outro** | Human/AI split, revision ID, limitations | — |

---

## Beat 9 — the cause-and-effect spine

This is the beat the rubric actually grades. Two linked demonstrations, source change
→ behaviour on screen.

**9a — One number changes whether the corridor is jumpable.**

1. Show `levels/first_steps.json`, highlight ledge B: `[1008, 272, 80, 12]`.
2. Show the arithmetic on screen: jump rise is **56 px**, so a jumping player's feet
   reach y ≈ 264 and their **head reaches y ≈ 236**. Ledge bottom is at **284**.
3. Live: walk the corridor. Press jump repeatedly. Nothing happens — the head is
   already against the ledge. **This is the low road's actual cost.**
4. Cut to `probe_reach.gd` output from the layout this replaced:
   `L1 -> over HZ1 UNREACHABLE`, `walk-under B and C BLOCKED at 1116.6`.
5. Narration point: the first design put spikes under those ledges and asked the player
   to jump them. That is not a tuning problem, it is impossible. The fix was geometry,
   not a bigger jump — and `tuning-unchanged` on screen proves the jump was not touched.

**9b — One divisor changes what the HUD tells you.**

1. Show the starter line: `clampf((player.position.x - 64) / 852, 0, 1)`.
2. Show it running on the extended level: bar full at x=916, less than half way along.
3. Show the replacement `progress_ratio()` deriving the span from level data.
4. Show the check output: `0.522` at the old finish x, `1.0` at the new one.

**Optional 9c if the cut has room:** the P5 fixture (13) — finish forced to
`y=208, h=112`, pole follows. Label `FIXTURE — NOT SHIPPED`.

---

## Evidence inventory

| Asset | Path |
|---|---|
| Character sheet | `evidence/screens/05-08-char-*.png` |
| Fork / ledges / corridor / finish | `evidence/screens/09-12-*.png` |
| P5 data-driven proof | `evidence/screens/13-p5-datadriven-fixture.png` |
| Starter baseline receipts | `evidence/baseline/00-baseline-*.json` |
| Current receipts | `evidence/mechanics-*.json`, `evidence/keyboard-*.json` |
| Build manifest + source hashes | `evidence/build-manifest.json` |
| Probe output | rerun live for the film; do not re-use a stale paste |

## Capture list still to record at render time

Live keyboard gameplay, no scripted input:

1. Arrival at the fork with the sign readable
2. High road B → C → D, clean
3. A **real** missed landing onto the low road (do not stage it with scripted input)
4. A **real** spike death and the auto-retry
5. Low road corridor + jump-press with no effect (for beat 9a)
6. The 56 px gap and completion
7. Replay from the completion card
