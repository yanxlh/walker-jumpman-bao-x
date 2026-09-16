extends CharacterBody2D

const Tuning = preload("res://features/player/tuning.gd")
var tuning = Tuning.new()
var enabled: bool = false
var tick: int = 0
var last_floor_tick: int = -1000
var jump_request_tick: int = -1000
var opportunity_consumed: bool = false
var require_jump_release: bool = true
var facing: float = 1.0
var jumps: int = 0
var test_control: bool = false
var test_axis: float = 0.0
var test_jump_pressed: bool = false
var test_jump_held: bool = false

func _ready() -> void:
	name = "Player"
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 1.0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(18, 28)
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = Vector2(0, -14)
	add_child(collider)

func reset_at(spawn: Vector2) -> void:
	position = spawn
	velocity = Vector2.ZERO
	last_floor_tick = -1000
	jump_request_tick = -1000
	opportunity_consumed = false
	require_jump_release = true
	test_jump_pressed = false
	jumps = 0
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	tick += 1
	var axis := test_axis if test_control else Input.get_axis("move_left", "move_right")
	var held := test_jump_held if test_control else Input.is_action_pressed("jump")
	var pressed := test_jump_pressed if test_control else Input.is_action_just_pressed("jump")
	test_jump_pressed = false
	if not held:
		require_jump_release = false
	if is_on_floor() and velocity.y >= 0.0:
		last_floor_tick = tick
		opportunity_consumed = false
	if pressed and not require_jump_release:
		jump_request_tick = tick
	var rate: float = tuning.acceleration if not is_zero_approx(axis) else tuning.deceleration
	velocity.x = move_toward(velocity.x, axis * tuning.speed, rate * delta)
	if not is_zero_approx(axis):
		facing = signf(axis)
	velocity.y = minf(velocity.y + tuning.gravity * delta, tuning.terminal_velocity)
	if not opportunity_consumed and tick - last_floor_tick <= tuning.coyote_ticks and tick - jump_request_tick <= tuning.buffer_ticks:
		velocity.y = tuning.jump_velocity
		opportunity_consumed = true
		jump_request_tick = -1000
		jumps += 1
	move_and_slide()
	position.x = maxf(position.x, 10.0)
	queue_redraw()

## The Lamp-Head Courier. Original vector drawing; no imported art.
##
## Replaces the starter's stacked-rectangle runner. The silhouette is top-heavy
## and asymmetric: an oversized lamp housing juts forward over a narrow torso,
## with a satchel counterweighting the trailing side. Four states are readable
## without relying on colour:
##   facing  - housing, satchel and beam all mirror on `facing`
##   idle    - narrow beam, level legs, housing horizontal
##   running - beam widens, torso leans into travel, legs stride
##   airborne- housing tips nose-down, beam sweeps toward the floor, legs tuck
##
## Every solid part stays inside the untouched 18x28 collider (x -9..9,
## y -28..0). The beam is translucent decoration with no collision shape;
## see TEST-REPORT.md "character-collider-unchanged" and "beam-has-no-body".
func _draw() -> void:
	var ink := Color("22303f")
	var shell := Color("35617f")
	var shell_lit := Color("4f89ad")
	var brass := Color("e0982f")
	var brass_dark := Color("9c6a1f")
	var glass := Color("fff6d8")
	# Menu/paused frames run before move_and_slide, so is_on_floor() is false
	# there; treat a disabled player as grounded so it does not pose mid-air.
	var grounded := is_on_floor() or not enabled
	var moving := absf(velocity.x) > 8.0 and grounded
	var f := facing
	var stride: float = sin(float(tick) * 0.7) * 2.0 if moving else 0.0
	var tilt: float = 0.0 if grounded else 4.0
	var lean: float = 1.0 * f if moving else 0.0

	# Light beam: decorative only, drawn first so the body sits on top of it.
	var spread: float = 6.5 if moving else 4.0
	if not grounded:
		spread = 5.5
	var reach: float = 15.0 if grounded else 12.0
	var origin := Vector2(7.0 * f + lean, -22.0 + tilt)
	var tip := origin + Vector2(reach * f, tilt * 2.2)
	draw_colored_polygon(PackedVector2Array([origin, tip + Vector2(0, -spread - 3.0), tip + Vector2(0, spread + 3.0)]), Color(1.0, 0.95, 0.74, 0.13))
	draw_colored_polygon(PackedVector2Array([origin, tip + Vector2(0, -spread), tip + Vector2(0, spread)]), Color(1.0, 0.95, 0.74, 0.30))

	# Legs: striding on the ground, tucked and splayed in the air.
	if grounded:
		draw_rect(Rect2(-5.0 - lean, -6.0, 4.0, 6.0 + stride), ink)
		draw_rect(Rect2(1.0 - lean, -6.0, 4.0, 6.0 - stride), ink)
	else:
		draw_rect(Rect2(-6.0, -6.0, 4.0, 4.0), ink)
		draw_rect(Rect2(2.0, -5.0, 4.0, 3.0), ink)

	# Satchel on the trailing side: the asymmetry that sells the facing.
	draw_colored_polygon(PackedVector2Array([Vector2(-4.5 * f, -19.0), Vector2(-8.5 * f, -17.0), Vector2(-8.5 * f, -9.0), Vector2(-4.5 * f, -10.5)]), brass_dark)

	# Torso: narrow column that tips into the direction of travel.
	draw_colored_polygon(PackedVector2Array([Vector2(-5.0 + lean, -21.0), Vector2(5.0 + lean, -21.0), Vector2(4.0, -6.0), Vector2(-4.0, -6.0)]), ink)
	draw_colored_polygon(PackedVector2Array([Vector2(-3.5 + lean, -19.5), Vector2(3.5 + lean, -19.5), Vector2(2.8, -7.5), Vector2(-2.8, -7.5)]), shell)
	draw_colored_polygon(PackedVector2Array([Vector2(0.4 + lean, -19.5), Vector2(3.5 + lean, -19.5), Vector2(2.8, -7.5), Vector2(0.4, -7.5)]), shell_lit)
	draw_rect(Rect2(-4.6 + lean, -13.5, 9.2, 2.4), brass)

	# Lamp housing: the feature that changes the silhouette.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5.0 * f + lean, -27.4), Vector2(2.0 * f + lean, -28.0),
		Vector2(7.0 * f + lean, -25.0 + tilt), Vector2(7.0 * f + lean, -19.2 + tilt),
		Vector2(2.0 * f + lean, -18.6), Vector2(-5.0 * f + lean, -20.2)]), ink)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3.6 * f + lean, -26.2), Vector2(1.8 * f + lean, -26.7),
		Vector2(5.8 * f + lean, -24.2 + tilt), Vector2(5.8 * f + lean, -20.0 + tilt),
		Vector2(1.8 * f + lean, -19.8), Vector2(-3.6 * f + lean, -21.3)]), brass)
	draw_colored_polygon(PackedVector2Array([
		Vector2(5.6 * f + lean, -24.1 + tilt), Vector2(8.0 * f + lean, -23.3 + tilt),
		Vector2(8.0 * f + lean, -20.7 + tilt), Vector2(5.6 * f + lean, -19.9 + tilt)]), glass)
	draw_line(Vector2(-3.0 * f + lean, -25.2), Vector2(1.4 * f + lean, -25.6), brass_dark, 1.2)
