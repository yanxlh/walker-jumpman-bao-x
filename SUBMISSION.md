# SUBMISSION — Assignment 1: Extend Walker Jumpman

```
Assignment: Assignment 1 - Extend Walker Jumpman
Student: Bao Xing (bao.xing@northeastern.edu)
Project name: walker-jumpman-bao-x
GitHub repository/folder URL: https://github.com/yanxlh/walker-jumpman-bao-x
Submitted commit SHA: <the SHA of the final submission commit — see the Canvas note>
Game-source revision shown in the film: fb75763fd0d6f0343b8e7cc116b304cac244b94f
Godot version and operating system: Godot 4.7.2.stable.official.ed1daf0bf, macOS 26.5.1 (Apple M4 Pro)
Final film URL and filename: https://drive.google.com/file/d/14lLAIUfCEQjxkS8iFQW7CwSLDXWpvl8W/view?usp=sharing
                             claude-liam-walker-jumpman-bao-x-walkthrough.mp4
Final film SHA-256: 26673e971c1a685d4a8b4b1cddb703ab09af94ea91b49ca9c035c9ac307209b1
```

> **Two revisions, as the assignment allows.** The film was rendered from game-source
> commit `fb75763fd0d6f0343b8e7cc116b304cac244b94f`. The final submission commit adds only film documentation and does
> **not** change the demonstrated game source — verifiable with
> `git diff fb75763fd0d6f0343b8e7cc116b304cac244b94f <final> -- godot/`, which is empty.
>
> The submitted commit SHA is deliberately left blank here: a commit cannot contain its
> own hash. It goes in the Canvas note.

## Summary of my changes

Extension of [nikbearbrown/walker-jumpman](https://github.com/nikbearbrown/walker-jumpman)
(commit `0852e7f` in this repo, imported byte-identical).

**Character — the Lamp-Head Courier.** `player.gd::_draw()` fully rewritten as original
vector art: an oversized lamp housing over a narrow torso, a satchel counterweighting
the trailing side, and a translucent light wedge in the direction of travel. Facing,
idle, running and airborne are each readable without colour. `_physics_process`,
`tuning.gd` and the 18x28 collider are untouched, and three checks assert that.

**Level — The Key and the Door**, all at x > 960; the original section is byte-identical.
Three narrow ledges (80/64/88 px) climbed by a 48 px up-jump lead to a key that sits
above standing height. The ledge dead-ends at a barrier, so the route doubles back:
drop to a roofed corridor with no headroom to jump, clear a 56 px gap, bait a spring
trap that arms only when you leave the ground beside it, and the carried key then flies
to the lock and opens the door. The finish moved 916 -> 1696 and became that door.

**Drawing defects fixed.** The starter hard-coded the level width, the spike baseline,
the finish pole's y-range and a `/852` progress divisor; all now derive from level data,
verified with a deliberately wrong fixture.

**Verification.** 53 automated checks, 0 failures — the starter's 25 still passing with
their assertions unmodified. Geometry chosen by `tests/probe_reach.gd`, which rejected
my first layout outright. Two human playtests, the second by someone who had not seen
the design.

## Known limitations

1. **The section is a there-and-back errand, not a pair of routes.** Making the key
   mandatory replaced the earlier high/low fork with a single route that doubles back.
   Recorded in `TEST-REPORT.md` §8b and `CHANGE-BRIEF.md` R7 as a deliberate change.
2. **n = 2 playtesters**, neither session instrumented — no retry counts, no timings.
3. **Extension coverage is route-based** — one fixed input line. Off-route behaviour in
   the new section is unverified.
4. **Source only.** No Web export, no standalone application.
