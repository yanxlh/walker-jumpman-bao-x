extends SceneTree
const Game = preload("res://game/session.gd")
const Route = preload("res://tests/route_driver.gd")
var game: Node2D
var results: Array[Dictionary] = []
var failures: int = 0

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

func check(id: String, passed: bool, observation: Dictionary) -> void:
	results.append({"id": id, "status": "PASS" if passed else "FAIL", "observed": observation})
	if not passed:
		failures += 1
	print(JSON.stringify(results.back()))

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

func run() -> void:
	await fresh()
	check("launch-grounded", game.player.is_on_floor() and game.state == Game.State.PLAYING, {"position": str(game.player.position), "engine": Engine.get_version_info().string})
	game.player.test_axis = 1
	await steps(8)
	check("speed-cap", is_equal_approx(game.player.velocity.x,160), {"velocity_x": game.player.velocity.x})
	game.player.test_axis = 0
	await steps(5)
	check("neutral-stop", is_zero_approx(game.player.velocity.x), {"velocity_x": game.player.velocity.x})
	game.player.test_control = false
	Input.action_press("move_left")
	Input.action_press("move_right")
	await steps(5)
	check("simultaneous-directions", is_zero_approx(game.player.velocity.x), {"velocity_x": game.player.velocity.x})
	Input.action_release("move_left")
	Input.action_release("move_right")
	game.player.test_control = true
	game.player.test_axis = -1
	await steps(70)
	check("left-wall", game.player.position.x >= 9 and game.player.position.x <= 11, {"x": game.player.position.x})
	await fresh()
	game.player.test_jump_pressed = true
	game.player.test_jump_held = true
	var min_y: float = game.player.position.y
	for i in range(50):
		await steps(1)
		min_y = minf(min_y, game.player.position.y)
		if i == 12:
			game.player.test_jump_pressed = true
	check("fixed-jump-and-no-double", game.player.jumps == 1 and absf((320-min_y)-53.3333) < 5, {"rise_px":320-min_y, "jumps":game.player.jumps})
	await steps(30)
	check("held-jump-no-bounce", game.player.jumps == 1 and game.player.is_on_floor(), {"jumps":game.player.jumps})
	# Actual geometry fixtures at a ledge; tick ages exercise inclusive 6 / expired 7.
	for age in [5,6,7]:
		await fresh()
		game.player.position = Vector2(478, 285)
		await steps(2)
		game.player.last_floor_tick = game.player.tick + 1 - age
		game.player.opportunity_consumed = false
		game.player.test_jump_pressed = true
		await steps(1)
		check("coyote-%d" % age, (game.player.jumps == 1) == (age <= 6), {"age":age, "jumps":game.player.jumps})
	for age in [5,6,7]:
		await fresh()
		game.player.jump_request_tick = game.player.tick + 1 - age
		await steps(1)
		check("buffer-%d" % age, (game.player.jumps == 1) == (age <= 6), {"age":age, "jumps":game.player.jumps})
	await fresh()
	game._add_solid(Rect2(32,260,64,12))
	await steps(2)
	game.player.test_jump_pressed = true
	min_y = 320
	for i in range(45):
		await steps(1)
		min_y = minf(min_y,game.player.position.y)
	check("low-ceiling", min_y >= 300-0.2 and game.player.jumps == 1 and game.player.is_on_floor(), {"minimum_feet_y":min_y,"jumps":game.player.jumps})
	await fresh()
	game.player.test_jump_pressed = true
	await steps(5)
	game.set_paused(true)
	var paused_position: Vector2 = game.player.position
	var paused_time: float = game.elapsed
	await steps(10)
	check("pause-freezes", game.player.position == paused_position and game.elapsed == paused_time, {"position":str(game.player.position),"elapsed":game.elapsed})
	game.set_paused(false)
	game.test_mode = false
	game._on_focus_lost()
	check("focus-loss-pauses", game.state == Game.State.PAUSED, {"state":game.state})
	game.test_mode = true
	await fresh()
	game.player.position = Vector2(330,310)
	await steps(4)
	check("actual-spike-collision", game.state == Game.State.DYING and game.deaths == 1, {"state":game.state,"deaths":game.deaths})
	game.resolve_contacts(true,true)
	check("duplicate-death-ignored", game.deaths == 1, {"deaths":game.deaths})
	await steps(38)
	check("respawn", game.state == Game.State.PLAYING and game.player.position.distance_to(Vector2(64,320)) < 1, {"state":game.state,"position":str(game.player.position)})
	game.restart_attempt()
	check("manual-restart-not-death", game.deaths == 1, {"deaths":game.deaths})
	var largest_retry_ticks: int = 0
	for i in range(20):
		game.resolve_contacts(true,false)
		var waited := 0
		while game.state == Game.State.DYING and waited < 65:
			await steps(1)
			waited += 1
		largest_retry_ticks = maxi(largest_retry_ticks, waited)
	check("twenty-retries", game.deaths == 21 and largest_retry_ticks <= 60, {"deaths":game.deaths,"max_retry_ticks":largest_retry_ticks})
	await fresh()
	game.resolve_contacts(true,true)
	check("death-before-finish", game.state == Game.State.DYING, {"state":game.state})
	await fresh()
	game.player.position = Vector2(415,432)
	await steps(1)
	check("fall-boundary", game.state == Game.State.DYING, {"state":game.state})
	# --- Pick a Line extension (bao-x) ---------------------------------------
	# The collider and tuning were deliberately not touched by the character
	# rewrite; these two checks are the proof, not a claim.
	await fresh()
	var shapes: Array[Node] = []
	for child in game.player.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			shapes.append(child)
	var collider: CollisionShape2D = shapes[0] if shapes.size() == 1 and shapes[0] is CollisionShape2D else null
	check("character-collider-unchanged", collider != null and collider.shape is RectangleShape2D and collider.shape.size == Vector2(18,28) and collider.position == Vector2(0,-14), {"shape_count":shapes.size(), "size":str(collider.shape.size) if collider else "n/a", "offset":str(collider.position) if collider else "n/a"})
	check("beam-adds-no-collision-body", shapes.size() == 1, {"collision_children":shapes.size(), "note":"light wedge is draw-only"})
	var tune = game.player.tuning
	check("tuning-unchanged", tune.speed == 160.0 and tune.jump_velocity == -320.0 and tune.gravity == 960.0 and tune.coyote_ticks == 6 and tune.buffer_ticks == 6, {"speed":tune.speed,"jump_velocity":tune.jump_velocity,"gravity":tune.gravity})

	# The low road is a roofed corridor: walkable end to end, but no headroom to
	# jump. That is the cost of taking it, so it must actually be traversable.
	await fresh()
	game.player.reset_at(Vector2(965, 320))
	await steps(3)
	game.player.test_axis = 1.0
	var jumps_at_entry: int = game.player.jumps
	for i in range(420):
		await steps(1)
		if game.player.position.x >= 1388.0 or game.state != Game.State.PLAYING:
			break
	check("low-corridor-walkable-no-jump", game.player.position.x >= 1388.0 and game.player.jumps == jumps_at_entry and game.state == Game.State.PLAYING, {"x":snappedf(game.player.position.x,0.01),"jumps":game.player.jumps,"state":game.state})

	# Finish actually moved: the old flag position must no longer win.
	await fresh()
	game.player.position = Vector2(916, 318)
	await steps(3)
	check("old-finish-position-no-longer-wins", game.state == Game.State.PLAYING, {"state":game.state,"old_finish_x":916})
	game.player.position = Vector2(1700, 318)
	await steps(3)
	check("relocated-finish-triggers", game.state == Game.State.COMPLETE, {"state":game.state,"finish_x":game.level.finish[0]})

	# HUD progress bar was hard-coded to /852 and saturated at the old finish.
	await fresh()
	game.player.position = Vector2(916, 318)
	await steps(1)
	var mid: float = game.hud.progress_ratio()
	game.player.position = Vector2(float(game.level.finish[0]), 318)
	await steps(1)
	check("hud-progress-tracks-relocated-finish", mid < 0.9 and is_equal_approx(game.hud.progress_ratio(), 1.0), {"ratio_at_old_finish_x":snappedf(mid,0.001),"ratio_at_new_finish":snappedf(game.hud.progress_ratio(),0.001)})
	# -------------------------------------------------------------------------

	# --- Spring trap + reward coin -------------------------------------------
	# Walking must never arm it: the zone sits above standing head height.
	await fresh()
	game.player.reset_at(Vector2(1480, 320))
	await steps(3)
	game.player.test_axis = 1.0
	for i in range(60):
		await steps(1)
		if game.player.position.x >= 1550.0 or game.state != Game.State.PLAYING:
			break
	check("trap-not-armed-by-walking", game.rising[0].phase == "down" and game.state == Game.State.PLAYING, {"phase":game.rising[0].phase,"x":snappedf(game.player.position.x,0.01),"state":game.state})

	# Bait it from the safe side, then walk under while it is up.
	await fresh()
	game.player.reset_at(Vector2(1480, 320))
	await steps(3)
	var bait_route = Route.new()
	# Spawned mid-level, so retire the earlier jump marks; otherwise the driver
	# fires all of them on the spot and launches itself into the trap.
	bait_route.next_jump = bait_route.jump_marks.size()
	var trap_peak_y: float = 320.0
	for i in range(300):
		bait_route.step(game.player)
		await steps(1)
		trap_peak_y = minf(trap_peak_y, game.rising[0].y)
		if game.player.position.x >= 1640.0 or game.state != Game.State.PLAYING:
			break
	check("spring-trap-bait-then-walk-under", game.player.position.x >= 1640.0 and game.state == Game.State.PLAYING, {"x":snappedf(game.player.position.x,0.01),"state":game.state,"spike_top_reached":trap_peak_y,"baited":bait_route.baited})
	check("spring-trap-actually-rises", trap_peak_y <= float(game.level.rising_hazards[0].raised_y) + 0.5, {"spike_top_reached":trap_peak_y,"raised_y":game.level.rising_hazards[0].raised_y})

	# Jumping across it arms it into the jump band and kills.
	await fresh()
	game.player.reset_at(Vector2(1450, 320))
	await steps(3)
	game.player.test_axis = 1.0
	var trap_jumped := false
	for i in range(240):
		if not trap_jumped and game.player.position.x >= 1520.0 and game.player.is_on_floor():
			game.player.test_jump_pressed = true
			trap_jumped = true
		await steps(1)
		if game.state != Game.State.PLAYING or game.player.position.x >= 1660.0:
			break
	check("spring-trap-punishes-the-jump", game.state == Game.State.DYING and trap_jumped, {"state":game.state,"death_reason":game.death_reason,"x":snappedf(game.player.position.x,0.01),"y":snappedf(game.player.position.y,0.01)})

	# Coin sits above ledge D, the highest surface. Walking it must not collect.
	await fresh()
	game.player.reset_at(Vector2(1270, 248))
	await steps(3)
	game.player.test_axis = 1.0
	for i in range(60):
		await steps(1)
		if game.player.position.x >= 1345.0 or game.state != Game.State.PLAYING:
			break
	check("coin-not-collectable-on-foot", game.coins_taken == 0 and game.player.position.x >= 1345.0, {"coins_taken":game.coins_taken,"x":snappedf(game.player.position.x,0.01)})

	await fresh()
	game.player.reset_at(Vector2(1270, 248))
	await steps(3)
	game.player.test_axis = 1.0
	var coin_jumped := false
	for i in range(120):
		if not coin_jumped and game.player.position.x >= 1290.0 and game.player.is_on_floor():
			game.player.test_jump_pressed = true
			coin_jumped = true
		await steps(1)
		if game.coins_taken > 0 or game.state != Game.State.PLAYING:
			break
	check("coin-collected-by-jumping", game.coins_taken == 1, {"coins_taken":game.coins_taken,"state":game.state,"jumped":coin_jumped})

	# A retry must re-arm the trap and restore the coin.
	game.resolve_contacts(true, false)
	await steps(40)
	check("retry-rearms-trap-and-coin", game.coins_taken == 0 and game.rising[0].phase == "down" and is_equal_approx(game.rising[0].y, float(game.level.rising_hazards[0].rect[1])), {"coins_taken":game.coins_taken,"phase":game.rising[0].phase,"spike_y":game.rising[0].y})
	# -------------------------------------------------------------------------

	await fresh()
	var route = Route.new()
	var route_ticks := 0
	# Budget deliberately left at the starter's 900 despite the level growing
	# from 960 to 1760 px. CHANGE-BRIEF P4 predicted an overrun; measured cost is
	# 618 ticks, so the original ceiling stands and no assertion was loosened.
	while game.state == Game.State.PLAYING and route_ticks < 900:
		route.step(game.player)
		await steps(1)
		route_ticks += 1
	check("complete-real-route", game.state == Game.State.COMPLETE and game.deaths == 0 and game.coins_taken == 0, {"branch":route.branch,"state":game.state,"deaths":game.deaths,"ticks":route_ticks,"position":str(game.player.position),"jump_marks_used":route.next_jump,"coins_taken":game.coins_taken})

	# The coin is the high road's payoff: unreachable from the low floor, so the
	# two route checks above and below assert 0 and 1 respectively.
	await fresh()
	var high_route = Route.new("high")
	var high_ticks := 0
	while game.state == Game.State.PLAYING and high_ticks < 900:
		high_route.step(game.player)
		await steps(1)
		high_ticks += 1
	check("complete-high-road-route", game.state == Game.State.COMPLETE and game.deaths == 0 and game.coins_taken == 1, {"branch":high_route.branch,"state":game.state,"deaths":game.deaths,"ticks":high_ticks,"position":str(game.player.position),"jump_marks_used":high_route.next_jump,"coins_taken":game.coins_taken})
	game.start_session()
	game.start_session()
	check("replay-idempotent", game.state == Game.State.PLAYING and game.deaths == 0 and game.player.jumps == 0, {"state":game.state,"deaths":game.deaths,"jumps":game.player.jumps})
	var report := {"scope":"First Steps slice; not full GDD acceptance or human playtesting", "engine":Engine.get_version_info().string,"created_at":Time.get_datetime_string_from_system(true),"results":results,"failures":failures}
	var out := ProjectSettings.globalize_path("res://../evidence")
	DirAccess.make_dir_recursive_absolute(out)
	var file := FileAccess.open(out + "/mechanics-" + str(Time.get_unix_time_from_system()) + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("WALKER TESTS: %d checks / %d failures" % [results.size(), failures])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
