extends Node2D

const LH_HERO = preload("res://scripts/lh_hero.gd")
const LH_ITEM = preload("res://scripts/lh_item.gd")
const LH_GIZMO = preload("res://scripts/lh_gizmo.gd")
const BOY_TEX = preload("res://assets/generated/male_hero.png")
const GIRL_TEX = preload("res://assets/generated/female_hero.png")
const HOME_BG = preload("res://assets/generated/cozy_home.png")
const FOREST_BG = preload("res://assets/generated/fairy_forest.png")
const STAR_BG = preload("res://assets/generated/starry_place.png")
const CYRILLIC_FONT = preload("res://assets/fonts/cyrillic_regular.tres")

const SAVE_PATH := "user://littlehistory.cfg"
const VIEW_SIZE := Vector2(1280, 720)
const PARALLAX := 0.35
const JUMP_BUFFER_MS := 150
const NO_TIME := -100000
const MOUSE_POINTER := -2
const SWITCH_Y := 626.0
const HELP_TEXT := "Управление: кнопки на экране. Переключайтесь между героями и помогайте друг другу."

var levels: Array[Dictionary] = []
var current: Dictionary = {}
var level_index := 0
var world_width := 2400.0
var playing := true
var paused_local := false
var active_id := 0
var boy: LHHero
var girl: LHHero
var camera: Camera2D
var platform_data: Array = []
var item_nodes: Array = []
var gizmo_nodes: Array = []
var switch_points: Array[Vector2] = []
var door_gizmo: LHGizmo
var switch_states: Array[bool] = []
var checkpoint := Vector2.ZERO
var unlocked_level := 0
var best_hearts: Array[int] = [0, 0, 0, 0]
var best_memories: Array[int] = [0, 0, 0, 0]
var level_hearts := 0
var level_memories := 0
var level_total_hearts := 0
var level_total_memories := 0
var touch_left := false
var touch_right := false
var touch_jump := false
var touch_crouch := false
var interact_held := false
var switch_held := false
var jump_request_ms := NO_TIME
var interaction_request := false
var pointers: Dictionary = {}
var control_buttons: Dictionary = {}
var menu_buttons: Array[Button] = []
var pair_timer := 0.0
var timed_gate_timer := 0.0
var timed_gate_open := false
var pressure_plate_position := Vector2(980.0, SWITCH_Y)
var timed_gate_position := Vector2(1220.0, 620.0)
var pit_zones: Array[Rect2] = []
var hero_hazard_cooldown := 0.0
var pair_interaction_index := 0
var message_timer := 0.0
var toast_text := ""
var ambient_time := 0.0
var hud_layer: CanvasLayer
var hud: Control
var top_panel: PanelContainer
var pause_button: Button
var hint_panel: PanelContainer
var level_label: Label
var hearts_label: Label
var memory_label: Label
var hint_label: Label
var active_label: Label
var toast_label: Label
var pause_panel: PanelContainer
var pause_help: Label
var finish_panel: PanelContainer
var finish_title: Label
var finish_body: Label
var finish_stars: Label
var finish_next: Button
var rotate_overlay: ColorRect
var bg_texture: Texture2D
var theme_color := Color("#e6b7aa")

func _ready() -> void:
	_build_level_catalog()
	_load_save()
	var requested := int(get_tree().get_meta("littlehistory_start_level", unlocked_level))
	get_tree().set_meta("littlehistory_start_level", -1)
	level_index = clampi(requested, 0, levels.size() - 1)
	_build_level(level_index)
	_build_heroes()
	_build_hud()
	_layout_hud()
	get_viewport().size_changed.connect(_layout_hud)
	get_viewport().size_changed.connect(_update_camera_zoom)
	_show_toast("Соберите сердечки и найдите путь к воротам ♥", 4.0)
	queue_redraw()

func _build_level_catalog() -> void:
	levels = [
		{"title":"Уютный дом", "subtitle":"Дом, где начинается маленькая история", "bg":HOME_BG, "theme":Color("#d9b39d"), "width":2400.0, "spawn":Vector2(150, 585), "goal":2220.0, "required":1, "switches":[Vector2(790, 585)], "pressure_plate":Vector2(980,585), "timed_gate":1220.0, "pits":[[520,620,100,30],[1580,620,110,30]], "platforms":[[0,650,2400,100],[300,560,250,24],[690,500,230,24],[1050,585,260,24],[1420,505,240,24],[1760,570,270,24]], "hearts":[Vector2(420,515),Vector2(805,455),Vector2(1160,540),Vector2(1515,460),Vector2(1860,525)], "memories":[Vector2(1230,445)]},
		{"title":"Зелёный дворик", "subtitle":"Когда рядом — даже забор становится приключением", "bg":null, "theme":Color("#91b889"), "width":2700.0, "spawn":Vector2(130, 585), "goal":2500.0, "required":2, "switches":[Vector2(830,585),Vector2(1510,585)], "pressure_plate":Vector2(1020,585), "timed_gate":1240.0, "pits":[[580,620,110,30],[1840,620,120,30]], "platforms":[[0,650,2700,100],[360,560,220,24],[700,490,190,24],[1080,570,230,24],[1390,475,240,24],[1740,560,260,24],[2110,470,220,24]], "hearts":[Vector2(440,515),Vector2(760,445),Vector2(1160,525),Vector2(1470,430),Vector2(1840,515),Vector2(2200,425)], "memories":[Vector2(1940,505)]},
		{"title":"Сказочный лес", "subtitle":"Секреты светятся только тем, кто ищет вместе", "bg":FOREST_BG, "theme":Color("#9b79a8"), "width":3000.0, "spawn":Vector2(130, 585), "goal":2800.0, "required":2, "switches":[Vector2(950,585),Vector2(2050,585)], "pressure_plate":Vector2(1180,585), "timed_gate":1430.0, "pits":[[520,620,110,30],[1600,620,120,30],[2260,620,110,30]], "platforms":[[0,650,3000,100],[300,525,230,24],[640,420,190,24],[970,535,240,24],[1320,440,220,24],[1680,540,230,24],[2040,450,230,24],[2380,535,220,24]], "hearts":[Vector2(420,480),Vector2(710,370),Vector2(1080,490),Vector2(1410,390),Vector2(1770,495),Vector2(2130,400),Vector2(2470,490)], "memories":[Vector2(1500,380),Vector2(2580,470)]},
		{"title":"Особенное место", "subtitle":"Финал, который хочется запомнить", "bg":STAR_BG, "theme":Color("#7c769e"), "width":2800.0, "spawn":Vector2(130, 585), "goal":2570.0, "required":2, "switches":[Vector2(820,585),Vector2(1700,585)], "pressure_plate":Vector2(1030,585), "timed_gate":1300.0, "pits":[[565,620,110,30],[1500,620,120,30],[2150,620,110,30]], "platforms":[[0,650,2800,100],[330,540,220,24],[670,455,220,24],[1020,545,230,24],[1370,460,220,24],[1680,550,240,24],[2050,465,250,24],[2350,545,220,24]], "hearts":[Vector2(430,495),Vector2(760,410),Vector2(1110,500),Vector2(1460,415),Vector2(1770,505),Vector2(2140,420),Vector2(2430,500)], "memories":[Vector2(1200,495),Vector2(2290,415)]}
	]

# ---------------------------------------------------------------- сохранение

func _load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		unlocked_level = clampi(int(cfg.get_value("progress", "unlocked_level", 0)), 0, 3)
		for i in 4:
			best_hearts[i] = int(cfg.get_value("progress", "best_hearts_%d" % i, 0))
			best_memories[i] = int(cfg.get_value("progress", "best_memories_%d" % i, 0))

func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("progress", "unlocked_level", unlocked_level)
	for i in 4:
		cfg.set_value("progress", "best_hearts_%d" % i, best_hearts[i])
		cfg.set_value("progress", "best_memories_%d" % i, best_memories[i])
	cfg.save(SAVE_PATH)

func _total_hearts() -> int:
	var total := 0
	for value in best_hearts:
		total += value
	return total

func _total_memories() -> int:
	var total := 0
	for value in best_memories:
		total += value
	return total

# ---------------------------------------------------------------- уровень

func _build_level(index: int) -> void:
	current = levels[index]
	world_width = float(current.width)
	bg_texture = current.bg
	theme_color = current.theme
	platform_data.clear()
	item_nodes.clear()
	gizmo_nodes.clear()
	switch_points.clear()
	for child in get_children():
		if child.is_in_group("lh_stage"):
			child.queue_free()
	switch_states.clear()
	timed_gate_timer = 0.0
	timed_gate_open = false
	hero_hazard_cooldown = 0.0
	pressure_plate_position = current.get("pressure_plate", Vector2(980.0, SWITCH_Y))
	timed_gate_position = Vector2(float(current.get("timed_gate", 1220.0)), 620.0)
	pit_zones.clear()
	for pit in current.get("pits", []):
		pit_zones.append(Rect2(float(pit[0]), float(pit[1]), float(pit[2]), float(pit[3])))
	for _i in current.switches.size():
		switch_states.append(false)
	level_hearts = 0
	level_memories = 0
	level_total_hearts = current.hearts.size()
	level_total_memories = current.memories.size()
	checkpoint = current.spawn
	for p in current.platforms:
		# Split the ground collision around spike pits so the gaps are real,
		# not merely painted over a solid floor.
		if float(p[1]) >= 640.0 and float(p[3]) >= 80.0 and not pit_zones.is_empty():
			var segments: Array[Vector2] = []
			var cursor := float(p[0])
			var floor_end := float(p[0]) + float(p[2])
			for pit in pit_zones:
				var pit_start := maxf(float(pit.position.x), cursor)
				var pit_end := minf(float(pit.end.x), floor_end)
				if pit_start > cursor:
					_add_platform(Vector2(cursor, p[1]), Vector2(pit_start - cursor, p[3]))
				cursor = maxf(cursor, pit_end)
			if cursor < floor_end:
				_add_platform(Vector2(cursor, p[1]), Vector2(floor_end - cursor, p[3]))
		else:
			_add_platform(Vector2(p[0], p[1]), Vector2(p[2], p[3]))
	# Невидимые стены по краям уровня, чтобы герои не «выпадали» за карту.
	_add_wall(-20.0)
	_add_wall(world_width + 20.0)
	for i in current.hearts:
		_add_item(Vector2(i[0], i[1]), "heart", "Сердечко")
	for m in current.memories:
		_add_item(Vector2(m[0], m[1]), "memory", "Памятный предмет")
	# Механизмы стоят на земле (раньше они «висели» в воздухе).
	for idx in current.switches.size():
		var switch_pos := Vector2(float(current.switches[idx].x), SWITCH_Y)
		switch_points.append(switch_pos)
		_add_gizmo(switch_pos, "switch", "Механизм %d" % (idx + 1))
	door_gizmo = _add_gizmo(Vector2(float(current.goal), 650), "door", "Финиш")
	_add_gizmo(pressure_plate_position, "plate", "Плита второго героя")
	_add_gizmo(timed_gate_position, "timed_door", "Временной проход")
	_add_gizmo(Vector2(float(current.spawn.x) + 70.0, 650), "checkpoint", "Старт")
	queue_redraw()

func _add_platform(pos: Vector2, size: Vector2) -> void:
	platform_data.append({"pos":pos, "size":size})
	var body := StaticBody2D.new()
	body.position = pos + size * 0.5
	body.collision_layer = 1
	body.add_to_group("lh_stage")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)

func _add_wall(x: float) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x, 360.0)
	body.collision_layer = 1
	body.add_to_group("lh_stage")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40.0, 2400.0)
	shape.shape = rect
	body.add_child(shape)
	add_child(body)

func _add_item(pos: Vector2, kind: String, title: String) -> void:
	var item := LH_ITEM.new()
	item.position = pos
	item.setup(kind, title)
	item.collected.connect(_on_item_collected)
	item.add_to_group("lh_stage")
	add_child(item)
	item_nodes.append(item)

func _add_gizmo(pos: Vector2, kind: String, title: String) -> LHGizmo:
	var gizmo := LH_GIZMO.new()
	gizmo.position = pos
	gizmo.setup(kind, title)
	gizmo.add_to_group("lh_stage")
	add_child(gizmo)
	gizmo_nodes.append(gizmo)
	return gizmo

func _build_heroes() -> void:
	boy = LH_HERO.new()
	boy.name = "Парень"
	boy.setup(self, 0, BOY_TEX)
	add_child(boy)
	girl = LH_HERO.new()
	girl.name = "Девушка"
	girl.setup(self, 1, GIRL_TEX)
	add_child(girl)
	_reset_heroes()
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.zoom = _mobile_camera_zoom()
	camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	camera.limit_left = 0
	camera.limit_right = int(world_width)
	camera.limit_top = 0
	camera.limit_bottom = 720
	add_child(camera)
	camera.position = boy.position + Vector2(0, -115)
	camera.reset_smoothing()

func _mobile_camera_zoom() -> Vector2:
	var view := get_viewport_rect().size
	# Keep the full 16:9 playfield visible; wider phones reveal a little more world.
	var scale := minf(view.x / VIEW_SIZE.x, view.y / VIEW_SIZE.y)
	scale = clampf(scale, 0.62, 1.0)
	return Vector2(scale, scale)

func _reset_heroes() -> void:
	boy.set_spawn(current.spawn)
	girl.set_spawn(current.spawn + Vector2(78, 0))
	boy.set_active(active_id == 0)
	girl.set_active(active_id == 1)
	boy.set_emotion("", 0.0)
	girl.set_emotion("", 0.0)

# ---------------------------------------------------------------- интерфейс

func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 20
	add_child(hud_layer)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(hud)
	# Верхняя панель: уровень, счётчики и активный герой.
	top_panel = PanelContainer.new()
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.12, 0.10, 0.18, 0.80), Color("#f5d9b8"), 2, 18))
	top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top_panel)
	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 2)
	top_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_panel.add_child(top_box)
	level_label = _hud_label("", 20)
	level_label.clip_text = true
	level_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top_box.add_child(level_label)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 14)
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_box.add_child(stats)
	hearts_label = _hud_label("♥ 0/0", 19)
	memory_label = _hud_label("✦ 0/0", 19)
	active_label = _hud_label("", 19)
	active_label.clip_text = true
	active_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stats.add_child(hearts_label)
	stats.add_child(memory_label)
	stats.add_child(active_label)
	# Кнопка паузы.
	pause_button = _menu_button("Ⅱ")
	pause_button.custom_minimum_size = Vector2(56, 56)
	pause_button.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_button.pressed.connect(toggle_pause)
	hud.add_child(pause_button)
	# Подсказка и всплывающие сообщения.
	hint_panel = PanelContainer.new()
	hint_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.12, 0.09, 0.16, 0.72), Color("#f4c7a3"), 2, 16))
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(hint_panel)
	hint_label = _hud_label("", 16)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_panel.add_child(hint_label)
	toast_label = _hud_label("", 20)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.add_theme_color_override("font_color", Color("#ffecc9"))
	toast_label.add_theme_color_override("font_outline_color", Color("#39283f"))
	toast_label.add_theme_constant_override("outline_size", 6)
	hud.add_child(toast_label)
	_build_touch_controls()
	_build_pause_panel()
	_build_finish_panel()
	# Подсказка «поверните экран» поверх всего, если экран вертикальный.
	rotate_overlay = ColorRect.new()
	rotate_overlay.color = Color(0.10, 0.07, 0.15, 0.97)
	rotate_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rotate_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	rotate_overlay.visible = false
	hud.add_child(rotate_overlay)
	var rotate_label := _hud_label("↻\nПоверните\nэкран", 16)
	rotate_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rotate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotate_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rotate_overlay.add_child(rotate_label)
	_update_hud()

func _hud_label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", CYRILLIC_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#fff0d0"))
	label.add_theme_color_override("font_outline_color", Color(0.16, 0.10, 0.18, 0.8))
	label.add_theme_constant_override("outline_size", 4)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _ctrl_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := _panel_style(fill, border, width, 16)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

func _menu_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", CYRILLIC_FONT)
	b.custom_minimum_size = Vector2(0, 52)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", Color("#fff0d0"))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _panel_style(Color(0.18, 0.13, 0.22, 0.9), Color("#e9b7a0"), 2, 16))
	b.add_theme_stylebox_override("hover", _panel_style(Color("#8f536e"), Color("#ffe0bf"), 3, 16))
	b.add_theme_stylebox_override("pressed", _panel_style(Color("#543d63"), Color("#f5bf9e"), 3, 16))
	menu_buttons.append(b)
	return b

func _build_touch_controls() -> void:
	_add_control_button("left", "◀")
	_add_control_button("right", "▶")
	_add_control_button("jump", "ПРЫЖОК")
	_add_control_button("switch", "⇄")
	_add_control_button("interact", "✦")
	_add_control_button("crouch", "ПРИСЕСТЬ")

# Экранные кнопки не реагируют на мышь/касание сами: нажатия считает _handle_pointer(),
# поэтому можно одновременно держать «вправо» и нажимать «прыжок» (мультитач).
func _add_control_button(id: String, text: String) -> void:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.clip_text = true
	b.add_theme_font_override("font", CYRILLIC_FONT)
	b.add_theme_color_override("font_color", Color("#fff0d0"))
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	var normal := _ctrl_style(Color(0.18, 0.13, 0.22, 0.80), Color("#e9b7a0"), 2)
	var pressed := _ctrl_style(Color("#8f536e"), Color("#ffe0bf"), 3)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	hud.add_child(b)
	control_buttons[id] = b

func _place(id: String, rect: Rect2, font_size: int) -> void:
	var b: Button = control_buttons[id]
	b.custom_minimum_size = rect.size
	b.position = rect.position
	b.size = rect.size
	b.add_theme_font_size_override("font_size", font_size)

func _center_control(c: Control) -> void:
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 0.5
	c.anchor_bottom = 0.5
	c.offset_left = 0.0
	c.offset_right = 0.0
	c.offset_top = 0.0
	c.offset_bottom = 0.0
	c.grow_horizontal = Control.GROW_DIRECTION_BOTH
	c.grow_vertical = Control.GROW_DIRECTION_BOTH

func _build_pause_panel() -> void:
	pause_panel = PanelContainer.new()
	pause_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.10, 0.08, 0.16, 0.97), Color("#f0b5a8"), 3, 26))
	pause_panel.visible = false
	_center_control(pause_panel)
	hud.add_child(pause_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	pause_panel.add_child(box)
	var title := _hud_label("ПАУЗА", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var resume := _menu_button("Продолжить")
	resume.pressed.connect(toggle_pause)
	box.add_child(resume)
	var restart := _menu_button("Перезапустить уровень")
	restart.pressed.connect(restart_level)
	box.add_child(restart)
	var menu := _menu_button("В главное меню")
	menu.pressed.connect(return_to_menu)
	box.add_child(menu)
	pause_help = _hud_label(HELP_TEXT, 14)
	pause_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(pause_help)

func _build_finish_panel() -> void:
	finish_panel = PanelContainer.new()
	finish_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.12, 0.08, 0.17, 0.98), Color("#f4c18f"), 3, 28))
	finish_panel.visible = false
	_center_control(finish_panel)
	hud.add_child(finish_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	finish_panel.add_child(box)
	finish_title = _hud_label("", 32)
	finish_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(finish_title)
	finish_stars = _hud_label("", 36)
	finish_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_stars.add_theme_color_override("font_color", Color("#ffd98a"))
	box.add_child(finish_stars)
	finish_body = _hud_label("", 18)
	finish_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(finish_body)
	finish_next = _menu_button("Дальше")
	finish_next.custom_minimum_size = Vector2(0, 56)
	finish_next.pressed.connect(next_level)
	box.add_child(finish_next)
	var menu := _menu_button("В меню")
	menu.pressed.connect(return_to_menu)
	box.add_child(menu)

# Раскладка считается от реального размера окна, поэтому кнопки не налезают
# друг на друга ни на ПК, ни на телефоне в горизонтальном положении.
func _update_camera_zoom() -> void:
	if camera != null:
		camera.zoom = _mobile_camera_zoom()

func _layout_hud() -> void:
	if hud == null or rotate_overlay == null:
		return
	var view := get_viewport_rect().size
	var w := view.x
	var h := view.y
	rotate_overlay.visible = w < h * 1.05
	var narrow := w < 760.0
	var compact := h < 500.0
	var m := 10.0 if narrow else 16.0
	var gap := 8.0 if narrow else 10.0
	var bh := 60.0 if (narrow or compact) else 72.0
	var fs := 16 if narrow else 18
	var y_low := h - m - bh
	if narrow:
		var usable := maxf(w - 2.0 * m - 2.0 * gap, 120.0)
		var a := clampf(usable * 0.26, 40.0, 84.0)
		var j := clampf(usable * 0.48, 70.0, 140.0)
		var y_up := y_low - gap - bh
		_place("left", Rect2(m, y_low, a, bh), fs + 2)
		_place("right", Rect2(m + a + gap, y_low, a, bh), fs + 2)
		_place("jump", Rect2(w - m - j, y_low, j, bh), fs)
		_place("switch", Rect2(m, y_up, a, bh), fs + 2)
		_place("interact", Rect2(m + a + gap, y_up, a, bh), fs + 2)
		_place("crouch", Rect2(w - m - j, y_up, j, bh), fs)
	else:
		var arrow := 84.0
		var jump_w := 150.0
		var crouch_w := 128.0
		_place("left", Rect2(m, y_low, arrow, bh), fs + 4)
		_place("right", Rect2(m + arrow + gap, y_low, arrow, bh), fs + 4)
		var jump_x := w - m - jump_w
		_place("jump", Rect2(jump_x, y_low, jump_w, bh), fs)
		var crouch_x := jump_x - gap - crouch_w
		_place("crouch", Rect2(crouch_x, y_low, crouch_w, bh), fs - 1)
		var interact_x := crouch_x - gap - arrow
		_place("interact", Rect2(interact_x, y_low, arrow, bh), fs + 4)
		_place("switch", Rect2(interact_x - gap - arrow, y_low, arrow, bh), fs + 4)
	# Верхняя панель и кнопка паузы.
	var ps := 50.0 if (narrow or compact) else 56.0
	pause_button.custom_minimum_size = Vector2(ps, ps)
	pause_button.position = Vector2(w - m - ps, m)
	pause_button.size = Vector2(ps, ps)
	var top_w := minf(w - 2.0 * m - ps - gap, 560.0)
	var lf := 15 if (narrow or compact) else 20
	level_label.add_theme_font_size_override("font_size", lf)
	hearts_label.add_theme_font_size_override("font_size", lf - 1)
	memory_label.add_theme_font_size_override("font_size", lf - 1)
	active_label.add_theme_font_size_override("font_size", lf - 1)
	top_panel.custom_minimum_size = Vector2(top_w, 0.0)
	top_panel.position = Vector2(m, m)
	top_panel.size = Vector2(top_w, 0.0)
	var top_h := maxf(top_panel.get_combined_minimum_size().y, 54.0)
	# Подсказка и сообщения — в верхней части экрана, чтобы не закрывать героев.
	var hint_w := minf(w - 2.0 * m, 760.0)
	hint_label.add_theme_font_size_override("font_size", 13 if narrow else 16)
	hint_label.custom_minimum_size = Vector2(minf(hint_w, 520.0) - 24.0, 0.0)
	hint_panel.custom_minimum_size = Vector2(minf(hint_w, 520.0), 0.0)
	hint_panel.position = Vector2((w - minf(hint_w, 520.0)) * 0.5, m + top_h + 4.0)
	hint_panel.size = Vector2(hint_w, 0.0)
	var toast_w := minf(w - 2.0 * m, 720.0)
	toast_label.add_theme_font_size_override("font_size", 16 if narrow else 20)
	toast_label.custom_minimum_size = Vector2(toast_w, 0.0)
	toast_label.size = Vector2(toast_w, 36.0)
	toast_label.position = Vector2((w - toast_w) * 0.5, hint_panel.position.y + (58.0 if narrow else 50.0) + 10.0)
	# Окна паузы и финиша всегда по центру и не шире экрана.
	var pw := minf(460.0, w - 24.0)
	pause_panel.custom_minimum_size = Vector2(pw, 0.0)
	pause_help.custom_minimum_size = Vector2(pw - 56.0, 0.0)
	pause_help.visible = h >= 560.0
	var fw := minf(640.0, w - 24.0)
	finish_panel.custom_minimum_size = Vector2(fw, 0.0)
	finish_title.custom_minimum_size = Vector2(fw - 56.0, 0.0)
	finish_body.custom_minimum_size = Vector2(fw - 56.0, 0.0)
	finish_title.add_theme_font_size_override("font_size", 22 if (narrow or compact) else 32)
	finish_body.add_theme_font_size_override("font_size", 15 if (narrow or compact) else 18)
	finish_stars.add_theme_font_size_override("font_size", 28 if (narrow or compact) else 36)
	var mb_h := 44.0 if compact else 52.0
	for b in menu_buttons:
		if b != pause_button:
			b.custom_minimum_size = Vector2(0.0, mb_h)
	finish_next.custom_minimum_size = Vector2(0.0, mb_h + 4.0)

func _show_toast(text: String, duration: float) -> void:
	toast_text = text
	message_timer = duration
	if toast_label != null:
		toast_label.text = toast_text

func _set_text(label: Label, text: String) -> void:
	if label.text != text:
		label.text = text

func _update_hud() -> void:
	if level_label == null or boy == null:
		return
	_set_text(level_label, "УРОВЕНЬ %d · %s" % [level_index + 1, current.title])
	_set_text(hearts_label, "♥ %d/%d" % [level_hearts, level_total_hearts])
	_set_text(memory_label, "✦ %d/%d" % [level_memories, level_total_memories])
	_set_text(active_label, "Ведёт: %s" % ("парень" if active_id == 0 else "девушка"))
	var hero: LHHero = boy if active_id == 0 else girl
	var near_switch := false
	for sp in switch_points:
		if hero.global_position.distance_to(sp) < 125.0:
			near_switch = true
	var hint := ""
	if near_switch:
		hint = "Оставьте второго героя на светящейся плите, затем активируйте рычаг ✦."
	elif not _all_switches_active():
		hint = "Переключитесь ⇄: один герой держит плиту, второй активирует рычаг. Проход открыт ненадолго!"
	else:
		hint = "Механизмы включены — идите к светящимся воротам вместе и нажмите ✦."
	_set_text(hint_label, hint)

# ---------------------------------------------------------------- цикл

func _process(delta: float) -> void:
	ambient_time += delta
	if pair_timer > 0.0:
		pair_timer -= delta
	if timed_gate_timer > 0.0:
		timed_gate_timer = maxf(0.0, timed_gate_timer - delta)
		if timed_gate_timer <= 0.0:
			timed_gate_open = false
			var gate_node := gizmo_nodes[gizmo_nodes.size() - 2] as LHGizmo
			if gate_node != null:
				gate_node.set_active(false)
			_show_toast("Временной проход закрылся", 1.5)
	if hero_hazard_cooldown > 0.0:
		hero_hazard_cooldown = maxf(0.0, hero_hazard_cooldown - delta)
	if playing and hero_hazard_cooldown <= 0.0:
		_check_pit_hazards()
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			toast_label.text = ""
	if camera != null and playing:
		var target := boy.position if active_id == 0 else girl.position
		camera.position = target + Vector2(0, -115)
	var plate_node := gizmo_nodes[gizmo_nodes.size() - 3] as LHGizmo if gizmo_nodes.size() >= 3 else null
	if plate_node != null:
		var partner_now: LHHero = girl if active_id == 0 else boy
		plate_node.set_active(partner_now.global_position.distance_to(pressure_plate_position) <= 90.0)
	if interaction_request:
		interaction_request = false
		_interact()
	_update_hud()
	queue_redraw()

func _check_pit_hazards() -> void:
	for hero in [boy, girl]:
		for pit in pit_zones:
			# The spike trench is dangerous only when the hero is at ground level.
			if hero.global_position.x >= pit.position.x and hero.global_position.x <= pit.end.x and hero.global_position.y > 545.0:
				hero_fell(hero)
				hero_hazard_cooldown = 0.8
				play_sfx(&"invalid")
				_show_toast("Шипы! Перепрыгните яму", 1.4)
				return

func _input(event: InputEvent) -> void:
	_handle_pointer(event)

func _handle_pointer(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			pointers[touch.index] = touch.position
		else:
			pointers.erase(touch.index)
		_refresh_controls()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		pointers[drag.index] = drag.position
		_refresh_controls()
	elif event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		# События мыши, созданные из касаний, пропускаем: касания обрабатываются выше.
		if click.button_index != MOUSE_BUTTON_LEFT or click.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if click.pressed:
			pointers[MOUSE_POINTER] = click.position
		else:
			pointers.erase(MOUSE_POINTER)
		_refresh_controls()
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if motion.device != InputEvent.DEVICE_ID_EMULATION and pointers.has(MOUSE_POINTER):
			pointers[MOUSE_POINTER] = motion.position
			_refresh_controls()

func _refresh_controls() -> void:
	if control_buttons.is_empty() or rotate_overlay == null:
		return
	var held := {}
	if playing and not paused_local and not rotate_overlay.visible:
		for id in pointers:
			var p: Vector2 = pointers[id]
			for key in control_buttons:
				var b: Button = control_buttons[key]
				if b.get_global_rect().has_point(p):
					held[key] = true
	touch_left = held.has("left")
	touch_right = held.has("right")
	touch_crouch = held.has("crouch")
	var jump_now := held.has("jump")
	if jump_now and not touch_jump:
		_request_jump()
	touch_jump = jump_now
	var interact_now := held.has("interact")
	if interact_now and not interact_held:
		interaction_request = true
	interact_held = interact_now
	var switch_now := held.has("switch")
	if switch_now and not switch_held:
		switch_hero()
	switch_held = switch_now
	for key in control_buttons:
		var btn: Button = control_buttons[key]
		btn.set_pressed_no_signal(held.has(key))

func _release_pointers() -> void:
	pointers.clear()
	_refresh_controls()

func _request_jump() -> void:
	if playing and not paused_local:
		jump_request_ms = Time.get_ticks_msec()

func input_axis() -> float:
	var axis := 0.0
	if touch_left:
		axis -= 1.0
	if touch_right:
		axis += 1.0
	return clampf(axis, -1.0, 1.0)

func is_run_pressed() -> bool:
	return false

func is_crouch_pressed() -> bool:
	return touch_crouch

func has_jump_request() -> bool:
	return Time.get_ticks_msec() - jump_request_ms <= JUMP_BUFFER_MS

func consume_jump_request() -> bool:
	var had := has_jump_request()
	jump_request_ms = NO_TIME
	return had

func play_sfx(cue: StringName) -> void:
	GameAudio.play(cue)

# ---------------------------------------------------------------- геймплей

func switch_hero() -> void:
	if not playing or paused_local:
		return
	active_id = 1 - active_id
	boy.set_active(active_id == 0)
	girl.set_active(active_id == 1)
	var current_hero := "парень" if active_id == 0 else "девушка"
	boy.set_emotion("удивление", 0.45)
	girl.set_emotion("удивление", 0.45)
	_show_toast("Теперь управляется %s" % current_hero, 1.5)

func is_timed_gate_blocking(hero: LHHero) -> bool:
	if timed_gate_open:
		return false
	return absf(hero.global_position.x - timed_gate_position.x) < 38.0 and hero.global_position.y > 520.0

func hero_fell(hero: LHHero) -> void:
	if not playing:
		return
	hero.global_position = checkpoint
	hero.velocity = Vector2.ZERO
	hero.set_emotion("грусть", 1.0)
	_show_toast("Не страшно — возвращаемся к контрольной точке", 2.0)

func _interact() -> void:
	if not playing or paused_local:
		return
	var hero: LHHero = boy if active_id == 0 else girl
	var partner: LHHero = girl if active_id == 0 else boy
	# Совместная головоломка: один герой удерживает плиту, второй включает рычаг.
	if hero.global_position.distance_to(switch_points[0]) < 105.0 and not timed_gate_open:
		if partner.global_position.distance_to(pressure_plate_position) <= 90.0:
			timed_gate_open = true
			if switch_states.size() > 0:
				switch_states[0] = true
				(gizmo_nodes[0] as LHGizmo).set_active(true)
			timed_gate_timer = 6.0
			var gate_node := gizmo_nodes[gizmo_nodes.size() - 2] as LHGizmo
			if gate_node != null:
				gate_node.set_active(true)
			play_sfx(&"stage_clear")
			_show_toast("Проход открыт на 6 секунд! Быстрее! ⇄", 2.0)
			return
	# Сначала механизмы и ворота, и только потом объятия: иначе, когда второй герой
	# стоит рядом, механизм невозможно было бы включить.
	for i in switch_points.size():
		if hero.global_position.distance_to(switch_points[i]) < 105.0:
			_toggle_switch(i, hero)
			return
	var goal_pos := Vector2(float(current.goal), 620.0)
	if hero.global_position.distance_to(goal_pos) < 150.0:
		if not _all_switches_active():
			play_sfx(&"invalid")
			_show_toast("Сначала включите все механизмы (%d/%d)" % [_active_switch_count(), switch_states.size()], 2.0)
		elif partner.global_position.distance_to(goal_pos) > 230.0:
			play_sfx(&"invalid")
			_show_toast("Дождитесь второго героя — к воротам нужно прийти вдвоём ♥", 2.2)
		else:
			complete_level()
		return
	if hero.global_position.distance_to(partner.global_position) < 150.0:
		var moments := ["Объятие", "Держатся за руки", "Танец на месте", "Сели рядом и улыбаются"]
		pair_timer = 2.2
		boy.set_emotion("радость", 2.2)
		girl.set_emotion("радость", 2.2)
		play_sfx(&"checkpoint")
		_show_toast("Совместный момент: %s ♥" % moments[pair_interaction_index], 1.8)
		pair_interaction_index = (pair_interaction_index + 1) % moments.size()
		return
	_show_toast("Рядом нет ничего, с чем можно взаимодействовать", 1.2)

func _toggle_switch(i: int, hero: LHHero) -> void:
	switch_states[i] = not switch_states[i]
	var gizmo := gizmo_nodes[i] as LHGizmo
	if gizmo != null:
		gizmo.set_active(switch_states[i])
	hero.set_emotion("радость", 0.8)
	play_sfx(&"confirm")
	var all_on := _all_switches_active()
	if door_gizmo != null:
		door_gizmo.set_active(all_on)
	if all_on:
		play_sfx(&"stage_clear")
		_show_toast("Путь открыт! Идите к воротам вместе ♥", 2.4)
	else:
		_show_toast("Механизм %d %s (%d/%d)" % [i + 1, "включён" if switch_states[i] else "выключен", _active_switch_count(), switch_states.size()], 1.5)

func _active_switch_count() -> int:
	var count := 0
	for state in switch_states:
		if state:
			count += 1
	return count

func _all_switches_active() -> bool:
	for state in switch_states:
		if not state:
			return false
	return true

func _on_item_collected(item: LHItem) -> void:
	if item.kind == "heart":
		level_hearts += 1
		play_sfx(&"coin")
		_spawn_pop(item.global_position, "♥", Color("#ff8fb0"))
		_show_toast("Сердечко найдено! ♥  %d/%d" % [level_hearts, level_total_hearts], 1.25)
	else:
		level_memories += 1
		play_sfx(&"checkpoint")
		_spawn_pop(item.global_position, "✦", Color("#ffe08a"))
		_show_toast("Памятный предмет сохранён в истории ✦", 1.8)
	_update_hud()

func _spawn_pop(world_pos: Vector2, text: String, color: Color) -> void:
	var pop := Label.new()
	pop.text = text
	pop.add_theme_font_override("font", CYRILLIC_FONT)
	pop.add_theme_font_size_override("font_size", 30)
	pop.add_theme_color_override("font_color", color)
	pop.add_theme_color_override("font_outline_color", Color(0.16, 0.10, 0.18, 0.9))
	pop.add_theme_constant_override("outline_size", 6)
	pop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop.z_index = 50
	pop.position = world_pos + Vector2(-12, -48)
	add_child(pop)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(pop, "position:y", pop.position.y - 70.0, 0.9)
	tween.tween_property(pop, "modulate:a", 0.0, 0.9)
	tween.chain().tween_callback(pop.queue_free)

func complete_level() -> void:
	if not playing:
		return
	playing = false
	_release_pointers()
	boy.set_emotion("радость", 6.0)
	girl.set_emotion("радость", 6.0)
	pair_timer = 6.0
	play_sfx(&"success")
	unlocked_level = maxi(unlocked_level, mini(level_index + 1, 3))
	best_hearts[level_index] = maxi(best_hearts[level_index], level_hearts)
	best_memories[level_index] = maxi(best_memories[level_index], level_memories)
	_save_progress()
	var total_items := level_total_hearts + level_total_memories
	var got_items := level_hearts + level_memories
	var stars := 1
	if got_items >= total_items:
		stars = 3
	elif float(got_items) >= float(total_items) * 0.6:
		stars = 2
	finish_stars.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	if level_index == levels.size() - 1:
		finish_title.text = "Ваша маленькая история завершена ♥"
		finish_body.text = "Всего собрано сердечек: %d, памятных предметов: %d.\nВы прошли весь путь вместе — и это главное." % [_total_hearts(), _total_memories()]
		finish_next.text = "Сыграть сначала"
	else:
		finish_title.text = "Уровень пройден!"
		finish_body.text = "%s\nСердечки: %d/%d · памятные предметы: %d/%d" % [current.title, level_hearts, level_total_hearts, level_memories, level_total_memories]
		finish_next.text = "Следующий уровень"
	# Короткая пауза, чтобы герои успели порадоваться, и только потом — окно итогов.
	await get_tree().create_timer(0.9).timeout
	if not is_inside_tree():
		return
	finish_panel.visible = true

func next_level() -> void:
	finish_panel.visible = false
	if level_index >= levels.size() - 1:
		level_index = 0
	else:
		level_index += 1
	playing = true
	active_id = 0
	pair_timer = 0.0
	_build_level(level_index)
	_reset_heroes()
	camera.limit_right = int(world_width)
	camera.position = boy.position + Vector2(0, -115)
	camera.reset_smoothing()
	_update_hud()
	_show_toast("%s — %s" % [current.title, current.subtitle], 3.0)

func restart_level() -> void:
	# Раньше после перезапуска из паузы герои оставались «замороженными».
	_set_paused(false)
	finish_panel.visible = false
	playing = true
	pair_timer = 0.0
	_build_level(level_index)
	_reset_heroes()
	camera.limit_right = int(world_width)
	camera.position = boy.position + Vector2(0, -115)
	camera.reset_smoothing()
	_update_hud()
	_show_toast("Уровень перезапущен", 1.4)

func toggle_pause() -> void:
	_set_paused(not paused_local)

func _set_paused(value: bool) -> void:
	if value and (not playing or finish_panel.visible):
		return
	paused_local = value
	pause_panel.visible = value
	boy.set_physics_process(not value)
	girl.set_physics_process(not value)
	_release_pointers()

func return_to_menu() -> void:
	_save_progress()
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

# ---------------------------------------------------------------- рисование

func _draw() -> void:
	var view := get_viewport_rect().size
	var cam_x := view.x * 0.5
	if camera != null:
		cam_x = camera.get_screen_center_position().x
	var view_left := cam_x - view.x * 0.5
	if bg_texture != null:
		_draw_parallax_background(view, view_left)
	else:
		_draw_courtyard(Rect2(0, 0, world_width, VIEW_SIZE.y))
	# Мягкая затемняющая вуаль у земли — героям легче читаться на фоне.
	draw_rect(Rect2(0, 565, world_width, 155), Color(0.12, 0.09, 0.16, 0.10))
	for p in platform_data:
		var r := Rect2(p.pos, p.size)
		if r.size.y < 60.0:
			draw_rect(Rect2(r.position.x + 4.0, r.end.y, r.size.x - 8.0, 10.0), Color(0.05, 0.03, 0.08, 0.16), true)
		draw_rect(r, Color("#56485f"), true)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 9)), theme_color.lightened(0.22), true)
		draw_line(r.position + Vector2(6, 6), r.position + Vector2(r.size.x - 6, 6), Color(1, 0.9, 0.75, 0.42), 2.0)
		for x in range(int(r.position.x + 20), int(r.end.x - 10), 42):
			draw_line(Vector2(x, r.position.y + 14), Vector2(x + 15, r.end.y - 5), Color(0.08, 0.06, 0.11, 0.18), 2.0)
	# Ямы с шипами: опасные зоны видны заранее.
	for pit in pit_zones:
		draw_rect(pit, Color("#34283e"), true)
		draw_rect(Rect2(pit.position, Vector2(pit.size.x, 5)), Color("#e5a0a0"), true)
		var count := int(pit.size.x / 22.0)
		for n in count:
			var x := pit.position.x + 8.0 + float(n) * 22.0
			draw_colored_polygon(PackedVector2Array([Vector2(x, pit.position.y + 2), Vector2(x + 10, pit.position.y - 20), Vector2(x + 20, pit.position.y + 2)]), Color("#d9d1d8"))
	# Табличка над воротами.
	var goal_x := float(current.goal)
	draw_string(CYRILLIC_FONT, Vector2(goal_x - 110.0, 524.0), "ОСОБЕННЫЙ МОМЕНТ", HORIZONTAL_ALIGNMENT_CENTER, 220.0, 14, Color("#fff0c8"))
	# Светлячки: лёгкая атмосфера, привязанная к экрану.
	for i in 16:
		var fx := view_left + fmod(float(i) * 173.0 + ambient_time * (6.0 + float(i % 5) * 2.0), view.x + 40.0)
		var fy := 140.0 + fmod(float(i) * 91.0, 380.0) + sin(ambient_time * 0.8 + float(i)) * 14.0
		var alpha := 0.28 + 0.2 * sin(ambient_time * 1.7 + float(i) * 1.3)
		draw_circle(Vector2(fx, fy), 2.2 + float(i % 3) * 0.6, Color(1.0, 0.92, 0.7, alpha))

# Фон растягивается пропорционально (раньше картинка 16:9 растягивалась на весь
# уровень и выглядела сплющенной) и сдвигается медленнее камеры — получается глубина.
func _draw_parallax_background(view: Vector2, view_left: float) -> void:
	var tex_size := bg_texture.get_size()
	var scroll_range := maxf(world_width - view.x, 0.0)
	var bg_w := view.x + scroll_range * PARALLAX
	var s := maxf(bg_w / tex_size.x, VIEW_SIZE.y / tex_size.y)
	var dest_size := tex_size * s
	var origin := Vector2(view_left * (1.0 - PARALLAX), -(dest_size.y - VIEW_SIZE.y) * 0.5)
	draw_texture_rect(bg_texture, Rect2(origin, dest_size), false)

func _draw_courtyard(rect: Rect2) -> void:
	draw_rect(rect, Color("#bfe0c2"), true)
	draw_circle(Vector2(210, 140), 90, Color("#f7d28f"))
	for i in 8:
		var hill_x := float(i) * 380.0
		draw_colored_polygon(PackedVector2Array([Vector2(hill_x, 520),Vector2(hill_x+180,330),Vector2(hill_x+360,520)]), Color("#93ba94"))
	for x in range(120, int(world_width), 320):
		var trunk := Vector2(x, 535)
		draw_rect(Rect2(trunk.x - 13, trunk.y - 120, 26, 120), Color("#7b594e"), true)
		draw_circle(trunk + Vector2(-35,-130), 52, Color("#6f9b77"))
		draw_circle(trunk + Vector2(30,-145), 58, Color("#80ab78"))
		draw_circle(trunk + Vector2(4,-180), 45, Color("#a8c887"))
	for x in range(90, int(world_width), 90):
		draw_circle(Vector2(x, 620 + sin(x) * 3), 5, Color("#f3a0ad"))
		draw_circle(Vector2(x + 8, 614 + sin(x) * 3), 5, Color("#f6d17f"))
