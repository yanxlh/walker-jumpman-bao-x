extends Node2D

const Player = preload("res://features/player/player.gd")
const Hud = preload("res://ui/hud.gd")
enum State { MENU, PLAYING, PAUSED, DYING, COMPLETE }
var state: State = State.MENU
var player: CharacterBody2D
var camera: Camera2D
var hud: Control
var level: Dictionary
var hazard_areas: Array[Area2D] = []
var rising: Array[Dictionary] = []
var key: Dictionary = {}
var key_area: Area2D
var door_open: bool = false
var goal: Area2D
var deaths: int = 0
var elapsed: float = 0.0
var retry_remaining: float = 0.0
var death_reason: String = ""
var last_finish_time: float = 0.0
var test_mode: bool = false
var contact_settle_ticks: int = 0

func _ready() -> void:
	process_physics_priority = 10
	level = JSON.parse_string(FileAccess.get_file_as_string("res://levels/first_steps.json"))
	_setup_input()
	for entry in level.solids:
		_add_solid(Rect2(entry[0], entry[1], entry[2], entry[3]))
	_add_solid(Rect2(-32, 0, 32, 430))
	_add_solid(Rect2(level.width, 0, 32, 430))
	for entry in level.hazards:
		hazard_areas.append(_add_area(Rect2(entry[0], entry[1], entry[2], entry[3]), 8, true))
	for spec in level.get("rising_hazards", []):
		var rr: Array = spec.rect
		var rect := Rect2(rr[0], rr[1], rr[2], rr[3])
		rising.append({
			"area": _add_area(rect, 8, true),
			"rect": rect, "base_y": rect.position.y, "raised_y": float(spec.raised_y),
			"arm_zone": Rect2(spec.arm_zone[0], spec.arm_zone[1], spec.arm_zone[2], spec.arm_zone[3]),
			"rise": float(spec.rise), "hold": float(spec.hold), "fall": float(spec.fall),
			"phase": "down", "t": 0.0, "y": rect.position.y,
		})
	# Barriers are ordinary solids. The one at the end of ledge D is what makes the
	# high road a dead end: you go up for the key and you come back down.
	for entry in level.get("barriers", []):
		_add_solid(Rect2(entry[0], entry[1], entry[2], entry[3]))
	var kspec: Dictionary = level.get("key", {})
	if not kspec.is_empty():
		key = {
			"home": Vector2(kspec.pos[0], kspec.pos[1]),
			"dock_x": float(kspec.dock_x),
			"phase": "idle", "p": Vector2(kspec.pos[0], kspec.pos[1]), "spin": 0.0,
		}
		key_area = Area2D.new()
		key_area.position = key.home
		key_area.collision_layer = 64
		key_area.collision_mask = 2
		var kshape := CollisionShape2D.new()
		var kcircle := CircleShape2D.new()
		kcircle.radius = 9.0
		kshape.shape = kcircle
		key_area.add_child(kshape)
		add_child(key_area)
	var f: Array = level.finish
	goal = _add_area(Rect2(f[0], f[1], f[2], f[3]), 16, false)
	player = Player.new()
	add_child(player)
	player.reset_at(Vector2(level.spawn[0], level.spawn[1]))
	camera = Camera2D.new()
	camera.position = Vector2(320, 180)
	add_child(camera)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.game = self
	layer.add_child(hud)
	get_window().focus_exited.connect(_on_focus_lost)
	queue_redraw()

func _setup_input() -> void:
	var actions := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "jump": [KEY_SPACE], "pause": [KEY_ESCAPE, KEY_P], "restart": [KEY_R], "confirm": [KEY_ENTER], "menu": [KEY_M]}
	for action in actions:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for code in actions[action]:
			var event := InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action, event)

func _add_solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size / 2
	body.collision_layer = 1
	body.collision_mask = 2
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _add_area(rect: Rect2, layer: int, spikes: bool) -> Area2D:
	var area := Area2D.new()
	area.position = rect.position
	area.collision_layer = layer
	area.collision_mask = 2
	if spikes:
		# Three exact triangular trigger silhouettes; no oversized invisible box.
		# Widths derive from the hazard rect so collision matches _draw at any size.
		for i in range(3):
			var triangle := CollisionPolygon2D.new()
			var w := rect.size.x / 3.0
			var x := float(i) * w
			triangle.polygon = PackedVector2Array([Vector2(x, rect.size.y), Vector2(x + w * 0.5, 0), Vector2(x + w, rect.size.y)])
			area.add_child(triangle)
	else:
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		collision.position = rect.size / 2.0
		area.add_child(collision)
	add_child(area)
	return area

func start_session() -> void:
	if state == State.PLAYING:
		return
	deaths = 0
	restart_attempt()

func restart_attempt() -> void:
	state = State.PLAYING
	elapsed = 0.0
	retry_remaining = 0.0
	# Area2D overlaps are physics-step snapshots. Discard pre-teleport contacts
	# until the broadphase has observed the reset, preventing a phantom second death.
	contact_settle_ticks = 2
	door_open = false
	if not key.is_empty():
		key.phase = "idle"
		key.p = key.home
		key_area.monitoring = true
	for h in rising:
		h.phase = "down"
		h.t = 0.0
		h.y = h.base_y
		h.area.position.y = h.base_y
	player.reset_at(Vector2(level.spawn[0], level.spawn[1]))
	player.enabled = true
	camera.position = Vector2(320, 180)

func set_paused(value: bool) -> void:
	if value and state == State.PLAYING:
		state = State.PAUSED
		player.enabled = false
	elif not value and state == State.PAUSED:
		state = State.PLAYING
		player.enabled = true
		player.require_jump_release = true
		player.jump_request_tick = -1000

func _on_focus_lost() -> void:
	if not test_mode:
		set_paused(true)

func resolve_contacts(fatal: bool, finished: bool) -> void:
	if state != State.PLAYING:
		return
	if fatal:
		state = State.DYING
		deaths += 1
		retry_remaining = 0.55
		player.enabled = false
		player.velocity = Vector2.ZERO
	elif finished:
		state = State.COMPLETE
		last_finish_time = elapsed
		player.enabled = false
		player.velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if state == State.DYING:
		retry_remaining -= delta
		if retry_remaining <= 0:
			restart_attempt()
	elif state == State.PLAYING:
		elapsed += delta
		var fatal := player.position.y > float(level.fall_y)
		death_reason = "Missed the landing" if fatal else "Watch the spikes"
		for hazard in hazard_areas:
			fatal = fatal or hazard.overlaps_body(player)
		_advance_trap(delta)
		for h in rising:
			if h.area.overlaps_body(player):
				fatal = true
				death_reason = "It goes up when you do"
		_advance_key(delta)
		if contact_settle_ticks > 0:
			contact_settle_ticks -= 1
		else:
			# The door is the finish, and it only counts once the key has docked.
			resolve_contacts(fatal, door_open and goal.overlaps_body(player))
		camera.position.x = clampf(player.position.x + 100, 320, float(level.width) - 320)
		if not rising.is_empty() or not key.is_empty():
			queue_redraw()
	if is_instance_valid(hud):
		hud.queue_redraw()

## A small key: ring bow, shaft, two teeth. Original vector drawing.
func _draw_key(at: Vector2) -> void:
	var gold := Color("e0b23a")
	var gold_dark := Color("a8801d")
	draw_circle(at + Vector2(-5, 0), 4.5, gold_dark)
	draw_circle(at + Vector2(-5, 0), 3.0, Color("fff2c6"))
	draw_rect(Rect2(at.x - 1, at.y - 1.5, 11, 3), gold)
	draw_rect(Rect2(at.x + 6, at.y + 1, 2.5, 4), gold)
	draw_rect(Rect2(at.x + 9.5, at.y + 1, 2, 3), gold)

## Where the key sits once it is fitted to the door.
func _keyhole() -> Vector2:
	var f: Array = level.finish
	return Vector2(float(f[0]) + float(f[2]) * 0.5, float(f[1]) + float(f[3]) * 0.55)

## idle -> carried -> flying -> docked. The key is mandatory: the door will not
## open without it, and the only route to it is the high road, which dead-ends
## at a barrier so the player has to drop back down and walk to the door.
func _advance_key(delta: float) -> void:
	if key.is_empty():
		return
	key.spin += delta * 3.0
	match key.phase:
		"idle":
			# Same stale-snapshot guard the starter documents for deaths: re-enabling
			# monitoring on respawn replays the pre-reset overlap, which re-collected
			# the pickup one frame after a retry had just restored it.
			if contact_settle_ticks == 0 and key_area.monitoring and key_area.overlaps_body(player):
				key.phase = "carried"
				key_area.monitoring = false
		"carried":
			var want := player.position + Vector2(-10.0 * player.facing, -38.0)
			key.p = key.p.lerp(want, 1.0 - pow(0.001, delta))
			if player.position.x >= key.dock_x:
				key.phase = "flying"
		"flying":
			var target := _keyhole()
			key.p = key.p.move_toward(target, 460.0 * delta)
			if key.p.distance_to(target) < 1.5:
				key.p = target
				key.phase = "docked"
				door_open = true
		"docked":
			key.p = _keyhole()

## Collider box of the player, in world space. The trap tests against this
## rather than an Area2D so the arming rule is plain geometry.
func _player_box() -> Rect2:
	return Rect2(player.position.x - 9.0, player.position.y - 28.0, 18.0, 28.0)

## Spring-loaded spike. Armed while DOWN; being airborne over it launches it to
## raised_y, where it occupies the jump band (y 240..256) but leaves 36 px of
## headroom on the floor. So it cannot be jumped over while up, only walked under.
## Bait it, then go underneath.
func _advance_trap(delta: float) -> void:
	for h in rising:
		match h.phase:
			"down":
				# Position match against the player's own collider box -- no
				# trigger body and no plate. The zone sits directly above the
				# spike and only inside the jump band, so walking never arms it.
				if _player_box().intersects(h.arm_zone):
					h.phase = "rising"
					h.t = 0.0
			"rising":
				h.t += delta
				var kr: float = clampf(h.t / h.rise, 0.0, 1.0)
				h.y = lerpf(h.base_y, h.raised_y, kr)
				if kr >= 1.0:
					h.phase = "up"
					h.t = 0.0
			"up":
				h.y = h.raised_y
				h.t += delta
				if h.t >= h.hold:
					h.phase = "falling"
					h.t = 0.0
			"falling":
				h.t += delta
				var kf: float = clampf(h.t / h.fall, 0.0, 1.0)
				h.y = lerpf(h.raised_y, h.base_y, kf)
				if kf >= 1.0:
					h.phase = "down"
					h.y = h.base_y
					h.t = 0.0
		h.area.position.y = h.y

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("confirm"):
		if state in [State.MENU, State.COMPLETE]:
			start_session()
		elif state == State.PAUSED:
			set_paused(false)
	elif event.is_action_pressed("pause"):
		set_paused(state != State.PAUSED)
	elif event.is_action_pressed("restart") and state in [State.PLAYING, State.PAUSED, State.DYING]:
		restart_attempt()
	elif event.is_action_pressed("menu") and state in [State.PAUSED, State.COMPLETE]:
		state = State.MENU
		player.enabled = false
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Rect2(220, 215, 200, 34).has_point(hud.get_local_mouse_position()):
			if state in [State.MENU, State.COMPLETE]:
				start_session()
			elif state == State.PAUSED:
				set_paused(false)

func _draw() -> void:
	if level.is_empty():
		return
	var font := ThemeDB.fallback_font
	var ink := Color("25354a")
	# All visual assets are original Godot vector drawing, not recovered art.
	# Everything below derives from the level data. The starter hard-coded the
	# level width, the spike baseline and the finish pole's y-range, so moving
	# data alone drew hazards and the flag in the wrong place.
	var width: float = float(level.width)
	draw_rect(Rect2(-400, -200, width + 800, 900), Color("f6f3ec"))
	for x in range(0, int(width) + 1, 32):
		draw_line(Vector2(x, 80), Vector2(x, 320), Color("e7e5df"), 1)
	for y in range(96, 321, 32):
		draw_line(Vector2(0, y), Vector2(width, y), Color("e7e5df"), 1)
	for x in range(100, int(width) + 200, 370):
		draw_colored_polygon(PackedVector2Array([Vector2(x-90,320),Vector2(x+50,180),Vector2(x+190,320)]), Color("e4e8e3"))
	for entry in level.solids:
		var r := Rect2(entry[0], entry[1], entry[2], entry[3])
		draw_rect(r, ink)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 4)), Color("438e7d"))
		# Hatching only fits on the thick floor slabs, not the thin high-road ledges.
		if r.size.y >= 24:
			for x in range(int(r.position.x)+12, int(r.end.x), 24):
				draw_line(Vector2(x, r.position.y+12), Vector2(x+7, r.position.y+19), Color("405166"), 1)
	for entry in level.hazards:
		var hz := Rect2(entry[0], entry[1], entry[2], entry[3])
		var spike_w := hz.size.x / 3.0
		for i in range(3):
			var sx: float = hz.position.x + float(i) * spike_w
			draw_colored_polygon(PackedVector2Array([Vector2(sx,hz.end.y),Vector2(sx+spike_w*0.5,hz.position.y),Vector2(sx+spike_w,hz.end.y)]), Color("d24e42"))
	# Spring-loaded spike. Nothing marks it on the floor and no guide rail is
	# drawn: the trap arms off the player's own position, and the sign is the
	# only tell.
	for h in rising:
		var base: Rect2 = h.rect
		var sw := base.size.x / 3.0
		for i in range(3):
			var sx: float = base.position.x + float(i) * sw
			draw_colored_polygon(PackedVector2Array([Vector2(sx, h.y + base.size.y), Vector2(sx + sw * 0.5, h.y), Vector2(sx + sw, h.y + base.size.y)]), Color("d24e42"))
		# Cap on the underside so a raised spike reads as an overhead hazard.
		if h.y < base.position.y - 1.0:
			draw_rect(Rect2(base.position.x - 2, h.y + base.size.y, base.size.x + 4, 3), Color("8f3a31"))

	# Barrier: the dead end that turns the high road into a there-and-back detour.
	for entry in level.get("barriers", []):
		var br := Rect2(entry[0], entry[1], entry[2], entry[3])
		draw_rect(br, ink)
		for y in range(int(br.position.y) + 8, int(br.end.y), 16):
			draw_line(Vector2(br.position.x + 1, y), Vector2(br.end.x - 1, y + 7), Color("8b5b3c"), 2)

	# The door. Shut until the key is fitted; the finish only counts once it opens.
	var fin := Rect2(level.finish[0], level.finish[1], level.finish[2], level.finish[3])
	draw_rect(Rect2(fin.position - Vector2(4, 6), fin.size + Vector2(8, 6)), ink)
	if door_open:
		# Swung inward: a dark opening with the leaf folded against the jamb.
		draw_rect(fin, Color("1b2733"))
		draw_colored_polygon(PackedVector2Array([
			fin.position, fin.position + Vector2(7, 5),
			Vector2(fin.position.x + 7, fin.end.y - 5), Vector2(fin.position.x, fin.end.y)]), Color("6f4b2e"))
		draw_string(ThemeDB.fallback_font, Vector2(fin.position.x - 10, fin.position.y - 16), "OPEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("287c68"))
	else:
		draw_rect(fin, Color("8b5b3c"))
		draw_rect(Rect2(fin.position + Vector2(3, 4), fin.size - Vector2(6, 8)), Color("74482c"))
		draw_circle(_keyhole(), 3.0, Color("2b1c10"))
		draw_rect(Rect2(_keyhole() + Vector2(-1, 1), Vector2(2, 6)), Color("2b1c10"))
		draw_string(ThemeDB.fallback_font, Vector2(fin.position.x - 14, fin.position.y - 16), "LOCKED", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a23e36"))

	# The key. Mandatory, and only the high road reaches it.
	if not key.is_empty() and key.phase != "docked":
		var bob: float = sin(key.spin * 2.0) * 1.5 if key.phase == "idle" else 0.0
		_draw_key(key.p + Vector2(0, bob))
	elif not key.is_empty():
		_draw_key(key.p)
	draw_string(font, Vector2(33, 251), "01 / GET MOVING", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ink)
	draw_string(font, Vector2(33, 273), "Read the landing. Then jump.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ink)
	draw_string(font, Vector2(474, 227), "02 / MIND THE GAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ink)
	draw_string(font, Vector2(838, 214), "03 / GET THE KEY", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ink)
	# Both costs are stated at the decision point. An earlier revision printed
	# "NO ROOM TO JUMP" inside the corridor at y=314, where the courier walked
	# straight through the text; moving it to y=348 hid it under the HUD footer
	# (y 335..360). Telling the player before they commit is the actual fix.
	draw_string(font, Vector2(838, 236), "The door is locked. The key is up there.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ink)
	draw_string(font, Vector2(838, 256), "Ledges dead-end: take it, then drop back.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ink)
	draw_string(font, Vector2(1012, 224), "KEY ROUTE / TIGHT LANDINGS", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("287c68"))
	draw_string(font, Vector2(1300, 130), "DEAD END", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("a23e36"))
	draw_string(font, Vector2(1100, 333), "WALK BACK / NO HEADROOM", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("6d818c"))
	draw_string(font, Vector2(1396, 214), "04 / SPRING TRAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ink)
	draw_string(font, Vector2(1396, 236), "Jump beside it and it springs.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ink)
	draw_string(font, Vector2(1396, 256), "Bait it, then walk under.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ink)
	draw_string(font, Vector2(1256, 178), "THE KEY", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("a8841c"))
	draw_string(font, Vector2(1636, 190), "05 / THE DOOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ink)
