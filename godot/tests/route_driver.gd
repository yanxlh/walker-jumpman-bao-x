extends RefCounted
## Fixed input route through the real level. No position/velocity edits.
##
## The level is no longer a fork. The door at x=1696 is locked, the only key is
## above ledge D, and ledge D dead-ends at a barrier — so there is one route and
## it doubles back:
##
##   1. RUN   the starter's original section, unchanged (5 jumps)
##   2. CLIMB the ledges B -> C -> D (3 jumps)
##   3. GRAB  jump on D to reach the key, which sits above standing height
##   4. BACK  walk LEFT off D and fall to the low floor — the barrier blocks right
##   5. GAP   run right, jump the 56 px gap onto the merge platform
##   6. BAIT  stop short of the spring trap, hop to spring it, walk under
##   7. DOOR  the carried key flies to the door at x=1600 and fits; walk in
##
## Every mark sits inside a takeoff window measured by tests/probe_reach.gd.

const CLIMB_MARKS: Array[float] = [138.0, 292.0, 424.0, 548.0, 712.0, 940.0, 1040.0, 1170.0]
const GRAB_X := 1288.0      ## on ledge D, jump to reach the key at (1320, 206)
const OFF_D_X := 1258.0     ## walk left past D's left edge (1264) to fall off
const GAP_X := 1360.0       ## takeoff for the 56 px gap (window 1356..1392)
const BAIT_X := 1546.0      ## stop short of the spike (bait window 1550..1558)

var jump_marks: Array[float] = CLIMB_MARKS.duplicate()
var next_jump: int = 0
var phase: String = "climb"
var branch: String = "key-route"
var grabbed: bool = false
var settle: int = 0

func _init(_which: String = "key-route") -> void:
	pass

## `game` is read only to observe key phase and floor height; no state is written.
func step(player: CharacterBody2D, game: Node2D = null) -> void:
	player.test_control = true
	player.test_jump_held = false
	var has_key: bool = game != null and not game.key.is_empty() and game.key.phase != "idle"

	match phase:
		"climb":
			player.test_axis = 1.0
			if next_jump < jump_marks.size():
				if player.position.x >= jump_marks[next_jump] and player.is_on_floor():
					player.test_jump_pressed = true
					next_jump += 1
			elif player.is_on_floor() and player.position.y < 260.0:
				phase = "grab"

		"grab":
			# On ledge D. Jump to collect the key, then turn around.
			player.test_axis = 1.0
			if has_key:
				phase = "back"
			elif not grabbed and player.position.x >= GRAB_X and player.is_on_floor():
				player.test_jump_pressed = true
				grabbed = true

		"back":
			# Barrier blocks the right. Walk left off D and drop to the low floor.
			player.test_axis = -1.0
			if player.position.y > 300.0 and player.is_on_floor():
				phase = "gap"
				settle = 4

		"gap":
			player.test_axis = 1.0
			if settle > 0:
				settle -= 1
			elif player.position.x >= GAP_X and player.is_on_floor():
				player.test_jump_pressed = true
				phase = "cross"

		"cross":
			player.test_axis = 1.0
			if player.position.x >= BAIT_X:
				player.test_axis = 0.0
				phase = "bait"

		"bait":
			player.test_axis = 0.0
			if player.is_on_floor() and absf(player.velocity.x) < 1.0:
				player.test_jump_pressed = true
				phase = "wait"
				settle = 46

		"wait":
			player.test_axis = 0.0
			settle -= 1
			if settle <= 0:
				phase = "door"

		"door":
			player.test_axis = 1.0
