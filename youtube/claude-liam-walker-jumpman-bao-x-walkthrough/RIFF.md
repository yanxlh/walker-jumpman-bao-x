# RIFF — what is happening, the mechanism, the trade-off

One entry per implemented feature, written after inspecting the captured frames.

| Feature | Beat | Observed on screen | Mechanism / trade-off |
|---|---|---|---|
| `menu-and-start` | B02 @ 0.2s | Menu card is up; Enter clears it into play. | The start card states the contract before you touch anything: one jump, no double jump, unlimited retries. |
| `horizontal-movement` | B02 @ 0.3s | Right is held; the courier accelerates and the lamp wedge widens. | Speed is a readout here — the widening cone is the running cue that does not depend on colour. |
| `fixed-height-jump` | B02 @ 0.85s | One jump, fixed height, no double jump. | Every landing downstream is built on this single unchanged number: a 56 px rise. |
| `starter-section-unchanged` | B02 @ 1.8s | Four jumps clear the starter's two gaps and its steps; geometry below x=960 is byte-identical. | Leaving it untouched is what keeps the starter's own coyote, spike and fall fixtures valid as regression evidence. |
| `spring-trap` | B03 @ 4.75s | The courier jumps to clear the last spike; the spike springs up into the arc and kills it. | Pure geometry: leaving the ground beside it is what arms it, so the naive play is the fatal one. |
| `death-and-reason` | B03 @ 5.2s | Death card reads 'It goes up when you do'. | The failure names its own cause, which is the difference between a trap and an ambush. |
| `automatic-retry` | B03 @ 5.6s | About half a second later the run restarts at spawn with RETRIES 01. | No lives and no menu: failure costs time, not progress — which is what makes a lethal trap acceptable. |
| `high-ledges` | B04 @ 4.1s | A 48 px up-jump onto ledge B, then hops to C and D. | Measured takeoff windows 70, 56 and 58 px — chosen by probe, not by feel. |
| `key-requires-a-jump` | B05 @ 0.6s | A jump on ledge D takes the key; the HUD turns to KEY HELD. | Standing on D the body occupies y 220–248 and the key spans 197–215, so walking under it is provably not enough. |
| `key-follows-the-player` | B05 @ 0.9s | The key trails the courier as it turns and walks back. | Carrying it visibly is what makes the door's demand legible before you reach the door. |
| `barrier-dead-end` | B05 @ 1.2s | The ledge ends in a barrier marked DEAD END; the courier turns and drops back to the floor. | The barrier is what converts a second route into a there-and-back errand — and it is why the level no longer asks you to choose. |
| `no-headroom-corridor` | B06 @ 0.4s | Running beneath the high ledges with WALK BACK / NO HEADROOM on the slab. | A ceiling you cannot jump under is a cost you feel without being told twice. |
| `committed-gap` | B06 @ 1.35s | A 56 px gap cleared onto the merge platform. | Measured takeoff window 38 px — the tightest required jump in the level. |
| `trap-bait-solution` | B06 @ 2.3s | The courier stops short, hops straight up to spring the spike, then walks underneath it. | The same input that kills you in the air is the one that clears the path from the ground. |
| `key-docks-and-opens-door` | B07 @ 0.55s | The key leaves the courier, flies to the lock and seats; LOCKED becomes OPEN. | The dock line at x=1600 is the moment the errand pays off — the carried object becomes the thing that changes the level. |
| `door-is-the-finish` | B07 @ 1.5s | The courier walks into the open door; Course complete. | The finish moved from a flag at 916 to a door at 1696, and it will not accept you without the key. |
| `replay` | B08 @ 0.35s | Enter on the completion card starts a fresh session; retries reset and the key is restored. | Replay re-locks the door and re-arms the trap, so a second run is a real second run. |
| `pause-and-resume` | B08 @ 1.45s | Escape raises the pause card and freezes the run; Enter resumes from the same position. | Pause freezes the clock as well as the player, which is why the finish time stays meaningful. |
| `manual-retry` | B08 @ 3.05s | R restarts the attempt from spawn and the retry counter stays at 00. | Choosing to restart is not failing, and the counter agrees. |
| `hud-key-and-progress` | B05 @ 0.8s | The HUD switches from KEY -- to KEY HELD, and the progress bar tracks spawn to door. | The bar is derived from level data; the starter divided by a hard-coded 852 and saturated less than halfway along this level. |

## Not built — named, not shown

| Feature | Why it is absent |
|---|---|
| `cherries` | Proposed in the starter GDD (20 optional cherries). Not built. |
| `audio` | No sound in the build. No fabricated sound effects were added for the film. |
| `settings-and-remapping` | Proposed in the starter GDD. Not built. |
| `moving-platforms` | Documented as a follow-up in the starter GDD. Not built. |
| `web-export` | Proposed shareable target in the starter design package. Not built; source-only release. |

## Judgment boundary

Everything above describes what the engine did and why the code makes it do that.
Two humans have played this build; their findings and limits are in the game's
`TEST-REPORT.md` §7.
