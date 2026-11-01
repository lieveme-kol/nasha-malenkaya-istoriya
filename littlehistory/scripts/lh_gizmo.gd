extends Node2D
class_name LHGizmo

const SYMBOL_FONT = preload("res://assets/fonts/cyrillic_regular.tres")

var kind := "switch"
var label := ""
var active := false
var pulse := 0.0

func setup(gizmo_kind: String, gizmo_label: String = "") -> void:
	kind = gizmo_kind
	label = gizmo_label
	queue_redraw()

func set_active(value: bool) -> void:
	active = value
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	var glow := 0.04 + (sin(pulse * 3.0) + 1.0) * 0.025
	if kind == "switch":
		draw_circle(Vector2.ZERO, 33.0, Color(0.92, 0.55, 0.66, glow + 0.1))
		draw_circle(Vector2.ZERO, 22.0, Color("#d4a0a7") if not active else Color("#f28fa8"))
		draw_arc(Vector2.ZERO, 22.0, 0, TAU, 32, Color("#563948"), 3.0, true)
		draw_circle(Vector2(0, -3 if not active else -8), 7.0, Color("#ffe6b7"))
		draw_line(Vector2(0, -15), Vector2(0, -32), Color("#563948"), 4.0, true)
	elif kind == "door":
		var c := Color("#6a4c70") if not active else Color("#edba7a")
		draw_rect(Rect2(-42, -106, 84, 106), c, true)
		draw_rect(Rect2(-42, -106, 84, 106), Color("#3b304d"), false, 5.0)
		draw_circle(Vector2(17, -51), 6.0, Color("#fff0c4"))
		if active:
			draw_arc(Vector2.ZERO, 62.0 + sin(pulse * 2.0) * 4.0, 0, TAU, 40, Color(1, 0.77, 0.53, 0.65), 3.0, true)
	elif kind == "plate":
		draw_rect(Rect2(-42, -12, 84, 12), Color("#8c7184") if not active else Color("#f2c18b"), true)
		draw_rect(Rect2(-42, -12, 84, 12), Color("#453447"), false, 3.0)
		draw_circle(Vector2(0, -18), 8.0 + sin(pulse * 4.0) * 2.0, Color("#ffe0a8"))
	elif kind == "timed_door":
		var c := Color("#6a4c70") if not active else Color("#e8a56f")
		draw_rect(Rect2(-28, -98, 56, 98), c, true)
		draw_rect(Rect2(-28, -98, 56, 98), Color("#3b304d"), false, 4.0)
		draw_string(ThemeDB.fallback_font, Vector2(-12, -48), "⌛", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#fff0c4"))
	elif kind == "checkpoint":
		draw_line(Vector2.ZERO, Vector2(0, -82), Color("#5b3c45"), 5.0, true)
		draw_colored_polygon(PackedVector2Array([Vector2(2, -82), Vector2(45, -68), Vector2(2, -53)]), Color("#f39bae") if active else Color("#bca3a8"))
		draw_circle(Vector2(0, 0), 11.0, Color("#f7d58d"))
	else:
		draw_circle(Vector2.ZERO, 58.0 + sin(pulse * 2.0) * 3.0, Color(0.98, 0.64, 0.72, 0.17))
		draw_arc(Vector2.ZERO, 45.0, 0.0, TAU, 48, Color("#ffcad0"), 5.0, true)
		draw_string(SYMBOL_FONT, Vector2(-18, 8), "♥", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("#f58ba5"))
