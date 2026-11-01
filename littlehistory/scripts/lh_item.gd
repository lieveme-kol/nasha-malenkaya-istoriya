extends Area2D
class_name LHItem

const SYMBOL_FONT = preload("res://assets/fonts/cyrillic_regular.tres")

signal collected(item: LHItem)
var kind := "heart"
var title := ""
var anim_time := 0.0
var taken := false
var base_y := 0.0

func setup(item_kind: String, item_title: String = "") -> void:
	kind = item_kind
	title = item_title
	base_y = position.y
	collision_layer = 0
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 32.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _process(delta: float) -> void:
	if taken:
		return
	anim_time += delta
	# Позиция считается от базовой высоты, поэтому предмет не «уплывает» со временем.
	position.y = base_y + sin(anim_time * 2.4) * 4.0
	rotation = sin(anim_time * 1.7) * 0.04
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if taken or not body.is_in_group("lh_hero"):
		return
	taken = true
	collected.emit(self)
	queue_free()

func _draw() -> void:
	var pulse := 1.0 + sin(anim_time * 3.0) * 0.06
	if kind == "heart":
		var points := PackedVector2Array([Vector2(0, 20), Vector2(-23, -5), Vector2(-21, -17), Vector2(-12, -25), Vector2(0, -16), Vector2(12, -25), Vector2(21, -17), Vector2(23, -5)])
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(pulse, pulse))
		draw_circle(Vector2(0, -2), 34.0, Color(1.0, 0.72, 0.8, 0.16))
		draw_colored_polygon(points, Color("#ef829c"))
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[4], points[5], points[6], points[7], points[0]]), Color("#542f42"), 3.0, true)
		draw_circle(Vector2(-9, -12), 4.0, Color(1, 0.93, 0.95, 0.8))
	else:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(pulse, pulse))
		draw_circle(Vector2.ZERO, 36.0, Color(1.0, 0.86, 0.5, 0.16))
		draw_circle(Vector2.ZERO, 24.0, Color("#f5cf82"))
		draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 32, Color("#694c55"), 3.0, true)
		draw_circle(Vector2.ZERO, 13.0, Color("#fff3cc"))
		draw_string(SYMBOL_FONT, Vector2(-8, 7), "✦", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d78771"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
