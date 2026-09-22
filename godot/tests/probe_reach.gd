extends SceneTree
## Reachability probe for the Pick a Line extension.
## Sweeps real takeoff positions through real physics and reports the usable
## landing window for every jump in the new section. This exists to answer
## CHANGE-BRIEF prediction P1/P2 with measurements instead of arithmetic.
## Diagnostic tool: it prints windows, it does not assert pass/fail.

const Game = preload("res://game/session.gd")

var game: Node2D

func _initialize() -> void:
	call_deferred("run")

## Exactly n physics ticks. The original also awaited process_frame, which lets
## any EXTRA physics ticks that Godot runs to catch up on a loaded machine slip by
## unobserved -- so steps(1) could silently advance 3-5 ticks and every tick-counted
## assertion in this file would drift. Proven on this machine: the unmodified starter
## fails fixed-jump-and-no-double 3/3 under load, and passes with this change.
func steps(n: int) -> void:
	for i in range(n):
		await physics_frame

func fresh() -> void:
	if is_instance_valid(game):
		game.queue_free()
		await process_frame
	game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.start_session()
	game.player.test_control = true
	await steps(3)

## Spawn on a surface, run right at full speed, jump at takeoff_x, report where we stop.
func hop(start: Vector2, takeoff_x: float, max_ticks: int = 200) -> Dictionary:
	await fresh()
	game.player.reset_at(start)
	await steps(3)
	game.player.test_axis = 1.0
	var jumped := false
	var airborne := false
	var peak: float = start.y
	var out := {"landed": false, "died": false}
	for i in range(max_ticks):
		if not jumped and game.player.position.x >= takeoff_x and game.player.is_on_floor():
			game.player.test_jump_pressed = true
			jumped = true
		await steps(1)
		peak = minf(peak, game.player.position.y)
		if jumped and not game.player.is_on_floor():
			airborne = true
		if game.state == Game.State.DYING:
			out.died = true
			break
		if airborne and game.player.is_on_floor():
			out.landed = true
			break
	out["x"] = snappedf(game.player.position.x, 0.01)
	out["y"] = snappedf(game.player.position.y, 0.01)
	out["rise"] = snappedf(start.y - peak, 0.01)
	return out

## Sweep takeoff positions and report which ones land on [target_lo, target_hi] at target_y.
func sweep(label: String, start: Vector2, lo: float, hi: float, target_y: float, tlo: float, thi: float) -> void:
	var good: Array[float] = []
	var x := lo
	while x <= hi:
		var r: Dictionary = await hop(start, x)
		if r.landed and not r.died and absf(r.y - target_y) < 1.0 and r.x >= tlo - 9.0 and r.x <= thi + 9.0:
			good.append(x)
		x += 2.0
	if good.is_empty():
		print("%-26s UNREACHABLE  (swept takeoff %.0f..%.0f)" % [label, lo, hi])
	else:
		print("%-26s takeoff window %.0f..%.0f  = %.0f px wide" % [label, good[0], good[-1], good[-1] - good[0] + 2.0])

## Walk right under the high ledges; report whether we get through cleanly.
func walk_under(from_x: float, to_x: float) -> void:
	await fresh()
	game.player.reset_at(Vector2(from_x, 320))
	await steps(3)
	game.player.test_axis = 1.0
	var stuck_at := -1.0
	var last: float = game.player.position.x
	for i in range(600):
		await steps(1)
		if game.player.position.x >= to_x:
			break
		if i > 20 and absf(game.player.position.x - last) < 0.05:
			stuck_at = game.player.position.x
			break
		last = game.player.position.x
	print("%-26s reached x=%.1f (target %.0f) jumps=%d %s" % [
		"walk-under B and C", game.player.position.x, to_x, game.player.jumps,
		"BLOCKED at %.1f" % stuck_at if stuck_at > 0 else "clear"])

## Stand at x, jump straight up, report (armed, survived).
func bait_sweep(lo: float, hi: float) -> void:
	var good: Array[float] = []
	var died: Array[float] = []
	var x := lo
	while x <= hi:
		await fresh()
		game.player.reset_at(Vector2(x, 320))
		await steps(4)
		if game.state != Game.State.PLAYING:
			died.append(x)
			x += 2.0
			continue
		game.player.test_axis = 0.0
		game.player.test_jump_pressed = true
		var armed := false
		for i in range(70):
			await steps(1)
			if game.rising[0].phase != "down":
				armed = true
			if game.state != Game.State.PLAYING:
				break
		if game.state != Game.State.PLAYING:
			died.append(x)
		elif armed:
			good.append(x)
		x += 2.0
	if good.is_empty():
		print("%-26s NO SAFE BAIT SPOT" % "bait-from-standing")
	else:
		print("%-26s bait window %.0f..%.0f = %.0f px wide (spike at 1568)" % ["bait-from-standing", good[0], good[-1], good[-1] - good[0] + 2.0])
	if not died.is_empty():
		print("%-26s lethal standing spots from %.0f" % ["", died[0]])

func run() -> void:
	print("\n=== REACHABILITY PROBE: The Key and the Door ===")
	print("engine ", Engine.get_version_info().string)

	# --- HIGH ROAD ---
	# Entry onto ledge B (top 272, 1008..1088) from the now-continuous floor.
	await sweep("floor -> B (+48 rise)", Vector2(860, 320), 900, 1006, 272, 1008, 1088)
	await sweep("B -> C  (flat 64px)", Vector2(1010, 272), 1010, 1088, 272, 1152, 1216)
	await sweep("C -> D  (+24, 48px)", Vector2(1154, 272), 1154, 1216, 248, 1264, 1352)
	# This one is EXPECTED to be unreachable: the barrier at x=1352 is what makes
	# ledge D a dead end. UNREACHABLE here is the barrier working, not a defect.
	await sweep("D -> M (barrier: none)", Vector2(1266, 248), 1266, 1352, 320, 1448, 1760)

	# --- AFTER THE KEY ---
	# The high road dead-ends at the barrier (x=1352), so the player drops back to
	# the low floor and walks to the door. The only jump left is GAP-L 1392..1448.
	await sweep("L1 -> M  (56px gap)", Vector2(1300, 320), 1356, 1392, 320, 1448, 1760)
	# NOTE: the old static spike at 1568 is gone -- it is now the spring trap, which
	# arms on any jump beside it, so "jump over it" is fatal by design and a takeoff
	# sweep is the wrong probe. The trap's real measurement is the bait window below.

	# --- SPRING TRAP ---
	# Sweep every standing position and hop straight up: report which spots arm
	# the trap from the safe side. That span is the bait window a human needs.
	await bait_sweep(1490, 1566)

	# --- CORRIDOR ---
	# The walk back to the door: the roofed corridor 992 -> 1392, no headroom to jump.
	await walk_under(965, 1390)
	print("=== END PROBE ===\n")
	quit(0)
