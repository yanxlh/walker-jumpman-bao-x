extends SceneTree
const Game = preload("res://game/session.gd")
const Route = preload("res://tests/route_driver.gd")
var game: Node2D
var output: String

func _initialize() -> void:
	call_deferred("run")

func step() -> void:
	await physics_frame
	await process_frame

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(output + "/" + label + ".png")
	assert(error == OK)
	print("Captured rendered game viewport: " + label)

func run() -> void:
	output = ProjectSettings.globalize_path("res://../evidence/screens")
	DirAccess.make_dir_recursive_absolute(output)
	game = Game.new()
	game.test_mode = true
	root.add_child(game)
	for i in range(3): await step()
	await capture("01-menu")
	game.start_session()
	game.player.test_control = true
	game.player.test_axis = 1
	# Walk from a safe landing into the spike trigger, not an invented failure card.
	game.player.position = Vector2(275, 320)
	for i in range(90):
		await step()
		if game.state == Game.State.DYING: break
	assert(game.state == Game.State.DYING)
	await capture("02-failure")
	game.state = Game.State.MENU
	game.start_session()
	var route = Route.new()
	var gap_captured := false
	for i in range(900):
		route.step(game.player)
		await step()
		if not gap_captured and game.player.position.x > 463 and game.player.position.y < 300:
			await capture("03-jump")
			gap_captured = true
		if game.state != Game.State.PLAYING: break
	assert(game.state == Game.State.COMPLETE, "Input route did not complete")
	await capture("04-complete")
	print("VISUAL ROUTE (low road): completed with %d deaths" % game.deaths)

	# --- Pick a Line extension evidence (bao-x) ------------------------------
	# Character state sheet. The engine camera is zoomed 4x for these four frames
	# ONLY so the 18x28 courier is inspectable; gameplay is never played zoomed.
	# Each frame is a real rendered viewport of a real pose, not an illustration.
	# Spawn on platform S3 (784..960), which carries no hazard, so the poses are
	# clean stills rather than death frames.
	for pose in [["05-char-idle-right", 0.0, false, 820.0], ["06-char-run-right", 1.0, false, 800.0], ["07-char-run-left", -1.0, false, 930.0], ["08-char-jump-right", 1.0, true, 800.0]]:
		game.state = Game.State.MENU
		game.start_session()
		game.player.test_control = true
		game.hud.visible = false
		game.player.reset_at(Vector2(pose[3], 320))
		for i in range(6): await step()
		game.player.test_axis = pose[1]
		for i in range(20): await step()
		if pose[2]:
			game.player.test_jump_pressed = true
			for i in range(14): await step()
		# Freeze the session and the body so the pose survives the capture frame.
		game.set_physics_process(false)
		game.player.set_physics_process(false)
		game.camera.zoom = Vector2(4, 4)
		game.camera.position = game.player.position + Vector2(0, -14)
		game.player.queue_redraw()
		await capture(pose[0])
		game.camera.zoom = Vector2.ONE
		game.hud.visible = true
		game.set_physics_process(true)
		game.player.set_physics_process(true)

	# Level landmarks, captured at normal zoom during a real run.
	for shot in [["09-fork-decision", 980.0], ["10-high-road-ledges", 1200.0], ["11-low-corridor", 1200.0], ["12-finish-relocated", 1660.0]]:
		game.state = Game.State.MENU
		game.start_session()
		var r = Route.new("high" if shot[0] == "10-high-road-ledges" else "low")
		for i in range(900):
			r.step(game.player)
			await step()
			# Wait for a grounded frame so landmark shots show a landing, not a blur.
			if (game.player.position.x >= shot[1] and game.player.is_on_floor()) or game.state != Game.State.PLAYING:
				break
		game.set_physics_process(false)
		game.player.set_physics_process(false)
		await capture(shot[0])
		game.set_physics_process(true)
		game.player.set_physics_process(true)
	print("VISUAL EVIDENCE: 12 rendered viewport captures written")
	game.queue_free()
	await process_frame
	quit()
