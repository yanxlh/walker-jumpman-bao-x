extends Control
var game: Node2D
const INK := Color("25354a")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func text_at(text: String, position: Vector2, size_px: int = 14, color: Color = INK) -> void:
	draw_string(ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func centered(text: String, y: float, font_size: int, color: Color = INK) -> void:
	var width := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	text_at(text, Vector2((640-width)/2, y), font_size, color)

## Spawn-to-finish fraction, derived from level data.
## The starter divided by the literal 852 (old finish 916 minus spawn 64), so
## the bar saturated less than halfway through a longer level. Exposed as a
## method so tests can assert it instead of re-deriving the formula.
func progress_ratio() -> float:
	if not is_instance_valid(game) or game.level.is_empty():
		return 0.0
	var start: float = float(game.level.spawn[0])
	var span: float = maxf(float(game.level.finish[0]) - start, 1.0)
	return clampf((game.player.position.x - start) / span, 0.0, 1.0)

func _draw() -> void:
	if not is_instance_valid(game):
		return
	draw_rect(Rect2(0,0,640,74), Color("f6f3ec"))
	text_at("WALKER / JUMPMAN", Vector2(22,27), 18)
	text_at("PICK A LINE", Vector2(497,27), 14)
	text_at("A/D or arrows: move     Space: jump     R: retry     Esc: pause", Vector2(22,50), 13)
	draw_rect(Rect2(22,63,596,3), Color("daddd6"))
	draw_rect(Rect2(22,63,596*progress_ratio(),3), Color("287c68"))
	draw_rect(Rect2(0,335,640,25), Color("f6f3ec"))
	text_at("No lives. Just another try.", Vector2(22,353), 13)
	var total: int = game.coins.size()
	if total > 0:
		text_at("COIN %d/%d" % [game.coins_taken, total], Vector2(352,353), 13, Color("a8841c") if game.coins_taken < total else Color("287c68"))
	text_at("RETRIES %02d     %04.1fs" % [game.deaths, game.elapsed], Vector2(440,353), 13)
	if game.state == game.State.PLAYING:
		return
	if game.state == game.State.DYING:
		draw_rect(Rect2(180,128,280,68), Color("fff9ee"))
		centered(game.death_reason, 155, 21, Color("a23e36"))
		centered("Back at the start in a moment.", 180, 13)
		return
	draw_rect(Rect2(0,74,640,261), Color(0.10,0.16,0.20,0.16))
	draw_rect(Rect2(163,103,318,159), Color("fffdf7"))
	draw_rect(Rect2(163,103,318,4), Color("ef875f"))
	var title := "First steps. Then pick a line."
	var detail := "Two gaps, then a fork: high ledges or the low floor."
	var button := "ENTER  /  START"
	if game.state == game.State.PAUSED:
		title = "Take a breath."
		detail = "R: restart attempt    M: main menu"
		button = "ENTER  /  RESUME"
	elif game.state == game.State.COMPLETE:
		title = "Course complete."
		detail = "%.1f seconds   /   %d retries   /   coin %d of %d" % [game.last_finish_time, game.deaths, game.coins_taken, game.coins.size()]
		button = "ENTER  /  PLAY AGAIN"
	centered(title, 143, 24)
	centered(detail, 177, 12)
	centered("One jump. No double jump. Unlimited retries.", 197, 12)
	draw_rect(Rect2(220,215,200,34), Color("287c68"))
	centered(button, 237, 14, Color("fffdf7"))
