# RIFF — what is happening, the mechanism, the trade-off

One entry per implemented feature, written after inspecting the captured frames.
Source-code facts and untested judgments are marked.

| Feature | Beat | Observed on screen | Mechanism / trade-off |
|---|---|---|---|
| `menu-and-start` | B02 @ 0.2s | Menu card is up; Enter is pressed and the card clears into play. | The start card states the whole contract before you touch anything: one jump, no double jump, unlimited retries. |
| `horizontal-movement` | B02 @ 0.27s | Right is held; the courier accelerates and the lamp wedge widens as it reaches speed. | Speed is a readout here — the light cone widening is the only running cue that does not depend on colour. |
| `fixed-height-jump` | B02 @ 0.8s | One jump, fixed height, no double jump available. | Everything downstream is built on this single unchanged number: a 56 pixel rise. |
| `starter-gaps-unchanged` | B02 @ 1.75s | Four jumps clear the starter's two gaps and its steps; geometry below x=960 is byte-identical to the starter. | Leaving this section untouched is what keeps the starter's own coyote and spike fixtures valid as regression evidence. |
| `starter-spike-hazard` | B02 @ 1.9s | The starter's three-spike cluster at x=320 is jumped and cleared. | The original hazard still reads and still kills; it is the baseline the new trap is measured against. |
| `fork-decision` | B03 @ 0.8s | The fork sign is on screen: UP three tight landings, ACROSS no headroom and one committed gap. | Both costs are stated before the player commits — an earlier build hid this inside the corridor where the courier walked over the text. |
| `high-road-ledges` | B03 @ 1.07s | A 48 px up-jump onto ledge B, then hops to C and D: three new landings that require jumps. | The measured takeoff windows are 70, 56 and 58 pixels — tight, but chosen by probe, not by feel. |
| `reward-coin` | B03 @ 3.77s | The coin above ledge D is taken in flight; the HUD counter turns green and reads COIN 1/1. | Ledge D is the highest surface in the game and only the high line reaches it, so the coin is the high road's entire payoff. |
| `spring-trap` | B04 @ 0.48s | The courier jumps to clear the last spike; the spike springs upward into the jump arc and kills it. | The trap is pure geometry: leaving the ground beside it is what arms it, so the naive play is the fatal one. |
| `death-and-reason` | B04 @ 0.8s | Death card reads 'It goes up when you do'. | The failure names its own cause, which is the difference between a trap and an ambush. |
| `automatic-retry` | B04 @ 1.37s | About half a second after the death the run restarts at spawn with RETRIES reading 01. | No lives and no menu: the cost of failure is time, not progress, which is what makes a lethal trap acceptable. |
| `low-road-corridor` | B05 @ 0.4s | The retried run crosses the original section again and re-enters the fork area on the floor. | The low line is the one you take by doing nothing, which is why its cost has to be legible. |
| `low-road-corridor` | B06 @ 0.1s | Running beneath the high ledges with LOW / NO HEADROOM printed on the slab. | A ceiling you cannot jump under is a cost you feel without being told twice. |
| `low-road-gap` | B06 @ 0.32s | A 56 px gap is cleared from the corridor onto the merge platform. | Measured takeoff window 38 pixels — the tightest required jump in the level. |
| `trap-bait-solution` | B06 @ 1.57s | The courier stops short of the spike, hops straight up to spring it, lands safe, then walks underneath the raised spike. | Baiting it is the whole puzzle: the same input that kills you in the air is the one that clears the path from the ground. |
| `finish-and-completion` | B06 @ 3.33s | The flag at x=1696 is reached; the completion card shows time, retries and coin 0/1 for this attempt. | Coin zero on a finished run is the fork being honest — this attempt took the low line and the coin was never reachable. |
| `replay` | B07 @ 0.33s | Enter on the completion card starts a fresh session with the retry counter back at 00. | Replay resets the coin and re-arms the trap, so a second run is a real second run. |
| `pause-and-resume` | B07 @ 1.15s | Escape raises the 'Take a breath.' card and freezes the run; Enter resumes from the same position. | Pause freezes the clock as well as the player, which is why the finish time stays meaningful. |
| `manual-retry` | B07 @ 3.03s | R restarts the attempt from spawn and the retry counter stays at 00. | Choosing to restart is not failing, and the counter agrees — a small honesty in the HUD. |
| `hud-progress-and-counters` | B03 @ 2.0s | The progress bar tracks spawn-to-finish and the coin and retry counters update live. | The bar is derived from level data; the starter divided by a hard-coded 852 and saturated less than halfway along this level. |

## Not built — named, not shown

| Feature | Why it is absent |
|---|---|
| `cherries` | Proposed in the starter GDD (20 optional cherries). Not built; the reward coin is a single collectible, not that system. |
| `audio` | No sound in the build. No fabricated sound effects were added for the film. |
| `settings-and-remapping` | Proposed in the starter GDD. Not built. |
| `moving-platforms` | Documented as a follow-up in the starter GDD. Not built. |
| `web-export` | Proposed shareable target in the starter design package. Not built; this is a source-only release. |

## Judgment boundary

Everything above describes what the engine did and why the code makes it do that.
**Whether any of it is fun is not assessed here.** One human has played this build —
the person who designed it — and that is recorded, with its caveat, in the game's
`TEST-REPORT.md` §7.
