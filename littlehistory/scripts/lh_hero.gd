extends CharacterBody2D
class_name LHHero

const SYMBOL_FONT = preload("res://assets/fonts/cyrillic_regular.tres")

var world: Node
var hero_id := 0
var active := false
var sprite: Sprite2D
var collision_shape: CollisionShape2D
var capsule: CapsuleShape2D
var anim_time := 0.0
var state := "idle"
var emotion := ""
var emotion_time := 0.0
var facing := 1.0
var was_on_floor := false
var spawn_point := Vector2.ZERO
var is_crouching := false
var coyote_time := 0.0
var jump_cooldown := 0.0

const WALK_SPEED := 260.0
const RUN_SPEED := 390.0
const ACCELERATION := 1500.0
const FRICTION := 1800.0
const JUMP_FORCE := 540.0
const GRAVITY := 1500.0
const CROUCH_SPEED := 135.0
const STAND_HEIGHT := 128.0
const CROUCH_HEIGHT := 84.0
const COYOTE_TIME := 0.10

# Поведение «второго героя»: он идёт следом за тем, кем управляет игрок.

func setup(owner_world: Node, id: int, texture: Texture2D) -> void:
	world = owner_world
	hero_id = id
	collision_layer = 2
	collision_mask = 1
	z_index = 10
	add_to_group("lh_hero")
	collision_shape = CollisionShape2D.new()
	capsule = CapsuleShape2D.new()
	capsule.radius = 28.0
	capsule.height = STAND_HEIGHT
	collision_shape.shape = capsule
	collision_shape.position = Vector2(0, -64)
	add_child(collision_shape)
	sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.position = Vector2(0, -78)
	sprite.scale = Vector2(0.064, 0.064)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	queue_redraw()

func set_spawn(point: Vector2) -> void:
	spawn_point = point
	global_position = point
	velocity = Vector2.ZERO
	if is_crouching:
		_set_crouching(false)

func set_active(value: bool) -> void:
	active = value
	z_index = 12 if value else 10
	queue_redraw()

func set_emotion(value: String, duration := 1.6) -> void:
	emotion = value
	emotion_time = duration
	queue_redraw()

func _physics_process(delta: float) -> void:
	anim_time += delta
	if emotion_time > 0.0:
		emotion_time -= delta
		if emotion_time <= 0.0:
			emotion = ""
	if world == null:
		return
	if is_on_floor():
		coyote_time = COYOTE_TIME
	else:
		coyote_time = maxf(coyote_time - delta, 0.0)
		velocity.y += GRAVITY * delta
	if world.playing and active:
		_control_by_player(delta)
	else:
		# The inactive hero stays exactly where the player left them.
		velocity.x = 0.0
	var fall_speed := velocity.y
	move_and_slide()
	if is_on_floor() and not was_on_floor and fall_speed > 260.0 and active:
		world.play_sfx(&"land")
	was_on_floor = is_on_floor()
	if global_position.y > 900.0:
		world.hero_fell(self)
	_update_state()
	queue_redraw()

func _control_by_player(delta: float) -> void:
	var crouch_pressed: bool = world.is_crouch_pressed()
	if crouch_pressed and is_on_floor():
		_set_crouching(true)
	elif not crouch_pressed and is_crouching:
		_set_crouching(false)
	var axis: float = world.input_axis()
	var running: bool = world.is_run_pressed()
	var target_speed := CROUCH_SPEED if is_crouching else (RUN_SPEED if running else WALK_SPEED)
	if absf(axis) > 0.05:
		velocity.x = move_toward(velocity.x, axis * target_speed, ACCELERATION * delta)
		facing = signf(axis)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	# Прыжок с «запасом» нажатия и коротким временем после схода с края.
	if world.has_jump_request() and (is_on_floor() or coyote_time > 0.0):
		if is_crouching:
			_set_crouching(false)
		if not is_crouching:
			world.consume_jump_request()
			_do_jump()

func _do_jump() -> void:
	velocity.y = -JUMP_FORCE
	coyote_time = 0.0
	set_emotion("радость", 0.35)
	world.play_sfx(&"jump")

func _update_state() -> void:
	if sprite != null:
		sprite.flip_h = facing < 0.0
	if world != null and world.pair_timer > 0.0:
		state = "объятие"
		if sprite != null:
			sprite.position.y = -78.0 + sin(anim_time * 9.0) * 3.0
			sprite.rotation = sin(anim_time * 9.0) * 0.045 * (1.0 if hero_id == 0 else -1.0)
		return
	if is_crouching:
		state = "приседание"
		if sprite != null:
			sprite.position.y = -55.0 + sin(anim_time * 4.0) * 1.2
			sprite.scale = Vector2(0.064, 0.047)
			sprite.rotation = 0.0
		return
	if not is_on_floor():
		state = "прыжок" if velocity.y < 0.0 else "приземление"
	elif absf(velocity.x) > RUN_SPEED * 0.72:
		state = "бег"
	elif absf(velocity.x) > 35.0:
		state = "ходьба"
	else:
		state = "ожидание"
	if sprite == null:
		return
	var bob := 0.0
	if state == "ожидание":
		bob = sin(anim_time * 2.2 + hero_id) * 1.8
	elif state == "ходьба" or state == "бег":
		bob = sin(anim_time * (13.0 if state == "бег" else 9.0)) * (2.4 if state == "бег" else 1.6)
	sprite.position.y = -78.0 + bob
	sprite.scale = Vector2(0.064, 0.064)
	sprite.rotation = sin(anim_time * 10.0) * 0.018 if state == "бег" else sin(anim_time * 2.0) * 0.008

func _set_crouching(value: bool) -> void:
	if value == is_crouching:
		return
	if not value and not _can_stand():
		return
	is_crouching = value
	capsule.height = CROUCH_HEIGHT if is_crouching else STAND_HEIGHT
	collision_shape.position.y = -42.0 if is_crouching else -64.0

func _can_stand() -> bool:
	if not is_crouching:
		return true
	var query := PhysicsShapeQueryParameters2D.new()
	var stand_shape := CapsuleShape2D.new()
	stand_shape.radius = capsule.radius
	stand_shape.height = STAND_HEIGHT
	query.shape = stand_shape
	query.transform = Transform2D(0.0, global_position + Vector2(0, -64))
	query.collision_mask = 1
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func _draw() -> void:
	var shadow_color := Color(0.12, 0.08, 0.12, 0.20 if active else 0.12)
	draw_set_transform(Vector2(0, 3), 0.0, Vector2(1.25, 0.32))
	draw_circle(Vector2.ZERO, 28.0, shadow_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if active:
		draw_arc(Vector2(0, 5), 36.0 + sin(anim_time * 3.0) * 2.0, 0.0, TAU, 48, Color("#f5a6b8"), 3.0, true)
		draw_circle(Vector2(0, 5), 4.0, Color("#f5a6b8"))
		# Маленькая стрелка над головой — сразу видно, кем вы управляете.
		var bob := sin(anim_time * 4.0) * 3.0
		draw_colored_polygon(PackedVector2Array([Vector2(-10, -184 + bob), Vector2(10, -184 + bob), Vector2(0, -168 + bob)]), Color("#f5a6b8"))
	if emotion != "" and emotion_time > 0.0:
		var bubble := Vector2(44 if facing > 0 else -44, -160)
		draw_circle(bubble, 19.0, Color(1.0, 0.95, 0.84, 0.96))
		draw_arc(bubble, 19.0, 0.0, TAU, 24, Color("#5b3c45"), 2.0, true)
		var symbol := "♥" if emotion == "радость" else "!"
		draw_string(SYMBOL_FONT, bubble + Vector2(-7, 8), symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#cc607f"))

func clear_input() -> void:
	velocity.x = 0.0
