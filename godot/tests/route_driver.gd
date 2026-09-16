extends RefCounted
## Fixed input route through the real level. No position/velocity edits.
##
## The starter shipped one five-mark route ending at the old finish (x=916).
## The level now forks at x~1000 and finishes at x=1696, so the fixture takes a
## branch and carries the run to the relocated flag. Calling Route.new() with no
## argument still yields the original five marks plus the low road, so the
## starter's own `complete-real-route` check keeps its meaning.
##
##   "low"  - stay on the floor, walk the roofed no-jump corridor, jump the
##            56 px gap onto the merge platform, clear the last spike.
##   "high" - hop ledges B -> C -> D, drop onto the merge platform, clear the
##            last spike.
##
## Every mark below sits inside a takeoff window measured on this engine by
## tests/probe_reach.gd. The measured windows at the time of writing were:
##   floor->B 924..992 | B->C 1034..1088 | C->D 1160..1216
##   D->M 1300..1352   | gap 1356..1392  | spike 1500..1552

const ORIGINAL: Array[float] = [138.0, 292.0, 424.0, 548.0, 712.0]
const LOW_TAIL: Array[float] = [1360.0, 1505.0]
const HIGH_TAIL: Array[float] = [940.0, 1040.0, 1170.0, 1310.0, 1505.0]

var jump_marks: Array[float] = []
var next_jump: int = 0
var branch: String = "low"

func _init(which: String = "low") -> void:
	branch = which
	jump_marks = ORIGINAL.duplicate()
	jump_marks.append_array(HIGH_TAIL if which == "high" else LOW_TAIL)

func step(player: CharacterBody2D) -> void:
	player.test_control = true
	player.test_axis = 1.0
	player.test_jump_held = false
	if next_jump < jump_marks.size() and player.position.x >= jump_marks[next_jump] and player.is_on_floor():
		player.test_jump_pressed = true
		next_jump += 1
