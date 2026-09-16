# Narration script — walker-jumpman-bao-x

**STAGED, NOT RENDERED.** Numbers marked `<<…>>` must be re-read from the actual run at
render time, not copied from here. If the human playtest still has not happened, the
line in Verdict that says so **stays in**.

Voice: Liam (AI narration, permitted). Plain, specific, no hype.

---

### 1 · Opening

> This is walker-jumpman-bao-x. It is not a new game. It is Nik Bear Brown's
> walker-jumpman with a new character and a new section bolted on, and I want to show
> you exactly where the seam is.

### 2 · The starter  `TERMINAL — REAL OUTPUT`

> Commit 0852e7f is the starter, imported byte-identical. A blocky runner, two gaps,
> one spike cluster, a flag at x=916. Twenty-five checks pass before I touch anything —
> that is the baseline, and it matches the starter's own build report.

### 3 · The ask

> Give it a new visual identity. Extend the level with real decisions. Keep the
> controls, the jump, the collider, and the retry loop exactly as they were.

### 4 · The character  `CAMERA ZOOM 4×`

> The Lamp-Head Courier. The starter's runner is a rectangle; this one is top-heavy and
> asymmetric — an oversized lamp housing forward, a satchel counterweighting behind, and
> a light wedge in the direction of travel.
>
> Four states, readable without colour. Idle: narrow beam, level legs. Running: the beam
> widens and the torso leans into it. Airborne: the housing tips nose-down and the legs
> tuck. Facing flips all three.

### 5 · Collider proof  `TERMINAL — REAL OUTPUT`

> Only the draw call changed. Physics, tuning and the eighteen-by-twenty-eight collider
> are untouched — and I am not asking you to take that on trust. Three checks assert it:
> the collider is still one rectangle at the same offset, the light beam added no
> collision body, and every tuning value is unchanged.

### 6 · The fork

> Here is the new section. The floor keeps going, and three ledges appear overhead. The
> sign states both costs before you commit: up is three tight landings, across is no
> headroom and one committed gap.

### 7 · High road

> Forty-eight pixels up onto the first ledge, then two hops. Eighty, sixty-four,
> eighty-eight pixels wide. The measured takeoff window for that first jump is seventy
> pixels — I will come back to how I know that.

### 8 · Failure and recovery

> Miss the second ledge and you are not dead — you are demoted. You land on the low road
> and the run continues, but now you have to do the hard version.
>
> The spikes still kill, and the retry is the starter's: no lives, no lecture, back at
> the start in about half a second. I did not touch that.

### 9a · Cause and effect — the corridor  ← **the important beat**

> Now the part I got wrong first.
>
> Ledge B sits at y=272 and is twelve pixels thick, so its underside is at 284. The jump
> rise is fifty-six pixels, which puts a jumping player's feet at 264 and their **head at
> 236**. Watch.
>
> *(live: walk the corridor, mash jump, nothing happens)*
>
> You cannot jump under there. Your head is already against the ledge.
>
> My first design put spike clusters under those ledges and asked you to jump them. Here
> is what the reachability probe said about it:
>
> *(cut to: `L1 -> over HZ1 UNREACHABLE` / `walk-under B and C BLOCKED at 1116.6`)*
>
> Every low-road jump impossible. And the two constraints cannot be reconciled: high-road
> hops have to be within about a hundred and seven pixels to be jumpable, and a low-road
> jump arc needs about a hundred and seven pixels with *nothing above it*. Stacked roads
> that both require jumping cannot exist at this tuning.
>
> The easy fix would have been a bigger jump. I did not do that — `tuning-unchanged` is
> still passing on screen. I re-cut the geometry instead, and the roof became the point:
> the low road is a corridor you can walk but cannot jump in. That is what it costs you.

### 9b · Cause and effect — the HUD

> Smaller one, same shape. The starter computed progress as x minus sixty-four, over
> eight hundred and fifty-two — the old finish minus the spawn, hard-coded. On a level
> that now runs to 1696, that bar fills up less than halfway along and sits there.
>
> Deriving the span from level data instead: the check reads **<<0.522>>** at the old
> finish position, and 1.0 at the real one.

### 10 · Low road and completion

> The corridor, the committed fifty-six pixel gap, one shared spike cluster, the flag.
> Both lines reach it.

### 11 · What I tested  `TERMINAL — REAL OUTPUT`

> Forty-two checks, zero failures. Twenty-five of them are the starter's, still passing
> with their assertions unmodified — nothing deleted, nothing relaxed. Eight are new.
> Both branches complete with zero deaths in **<<618>>** ticks, under the starter's
> original nine-hundred-tick ceiling, which I left alone after measuring rather than
> raising to be safe.

### 12 · Verdict

> One. The character is new in shape, not just colour, and the collider it has to live
> inside is provably unchanged.
>
> Two. The extension is real and both lines reach the finish — but the high road saves
> no time. Both branches run the same six hundred and eighteen ticks, because jumps do
> not change horizontal speed. It is a precision-versus-nerve choice, not a shortcut,
> and calling it a shortcut would be a lie.
>
> Three. **<<No human has played this build yet.>>** Forty-two machine checks say the
> mechanics work. None of them says it is any good. *(If the playtest has happened by
> render time, replace this line with the actual finding — including retries taken — and
> do not soften it.)*

### 13 · Your turn

> If you extend someone else's level: before you commit to a layout, write the throwaway
> script that sweeps takeoff positions through the real physics and tells you which
> jumps actually land. Mine rejected my first design outright and told me why. I had
> already hand-computed that layout and believed it.
>
> And when the geometry does not work, change the geometry. The moment you reach for the
> jump strength, you are no longer extending the game — you are editing it to agree
> with you.

### 14 · Outro

> Starter: nikbearbrown/walker-jumpman, commit 0852e7f. Revision demonstrated:
> **<<commit>>**, build **<<9b98509592…>>**, Godot 4.7.2.
>
> I chose the character, chose the fork, and chose to re-cut the geometry rather than
> touch the tuning. Claude Code wrote the vector drawing, the reachability probe, the
> data-driven rewrites and the added checks, and diagnosed the head-height conflict that
> I would not have found by looking.
>
> Narration is AI. The gameplay is not — every clip except the labelled ones is real
> keyboard input, and nothing was re-cut to hide a defect.
