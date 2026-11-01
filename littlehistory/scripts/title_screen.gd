extends Control

const HOME_BG = preload("res://assets/generated/cozy_home.png")
const BOY_TEX = preload("res://assets/generated/male_hero.png")
const GIRL_TEX = preload("res://assets/generated/female_hero.png")
const CYRILLIC_FONT = preload("res://assets/fonts/cyrillic_regular.tres")
const SAVE_PATH := "user://littlehistory.cfg"
const KEYS_HELP := "Клавиши: A/D или ←/→ — идти, Shift — бежать, Пробел/W/↑ — прыжок, S/↓ — присесть, Tab — сменить героя, E — действие, Esc — пауза.\n\nВторой герой идёт следом за вами. Чтобы пройти уровень, включите все механизмы и придите к воротам вдвоём."

var saved_level := 0
var dialog: PanelContainer
var pulse := 0.0
var narrow_layout := false
var compact_layout := false
var layout_dirty := false

func _ready() -> void:
	saved_level = _saved_level()
	set_process(true)
	_build_ui()
	get_viewport().size_changed.connect(func(): layout_dirty = true)
	GameAudio.begin_title()
	queue_redraw()

func _saved_level() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		return clampi(int(cfg.get_value("progress", "unlocked_level", 0)), 0, 3)
	return 0

func _process(delta: float) -> void:
	pulse += delta
	if layout_dirty:
		layout_dirty = false
		_rebuild_ui()
	queue_redraw()

func _rebuild_ui() -> void:
	dialog = null
	for child in get_children():
		child.queue_free()
	_build_ui()

func _draw() -> void:
	var view := get_viewport_rect().size
	# Фон масштабируется с сохранением пропорций и обрезается по краям.
	var tex_size := HOME_BG.get_size()
	var fit := maxf(view.x / tex_size.x, view.y / tex_size.y)
	var dest := tex_size * fit
	draw_texture_rect(HOME_BG, Rect2((view - dest) * 0.5, dest), false)
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.08, 0.06, 0.12, 0.22), true)
	draw_circle(Vector2(view.x * 0.83, view.y * 0.16), 120.0 + sin(pulse) * 4.0, Color(1.0, 0.78, 0.54, 0.12))
	for i in 12:
		var x := fposmod(40.0 + float(i) * 122.0 + pulse * (4.0 + float(i % 4)), view.x + 20.0)
		var y := 100.0 + fmod(float(i * 47), maxf(1.0, view.y - 180.0)) + sin(pulse * 0.9 + float(i)) * 8.0
		draw_circle(Vector2(x, y), 2.5, Color(1, 0.9, 0.72, 0.34))

func _build_ui() -> void:
	var view := get_viewport_rect().size
	if view.x < view.y * 1.05:
		_build_rotate_hint()
		return
	compact_layout = view.y < 560.0
	narrow_layout = view.x < 700.0
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var edge_x := 16 if narrow_layout else 46
	var edge_y := 10 if compact_layout else (18 if narrow_layout else 34)
	margin.add_theme_constant_override("margin_left", edge_x)
	margin.add_theme_constant_override("margin_right", edge_x)
	margin.add_theme_constant_override("margin_top", edge_y)
	margin.add_theme_constant_override("margin_bottom", edge_y)
	add_child(margin)
	var layout: BoxContainer = VBoxContainer.new() if narrow_layout else HBoxContainer.new()
	layout.add_theme_constant_override("separation", 12 if narrow_layout else 28)
	margin.add_child(layout)
	var left_card := PanelContainer.new()
	left_card.custom_minimum_size = Vector2(minf(460.0, view.x - 2.0 * edge_x), 0)
	left_card.add_theme_stylebox_override("panel", _style(Color(0.12, 0.08, 0.16, 0.92), Color("#f2c5a3"), 3, 28))
	layout.add_child(left_card)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6 if compact_layout else 10)
	left_card.add_child(left)
	var title_size := 30 if compact_layout else (34 if narrow_layout else (44 if view.x < 1100.0 else 47))
	if not compact_layout:
		var eyebrow := _label("АВТОРСКОЕ РОМАНТИЧЕСКОЕ ПРИКЛЮЧЕНИЕ", 14, Color("#f6c1a4"))
		eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		left.add_child(eyebrow)
	var title_label := _label("Наша маленькая\nистория", title_size, Color("#fff0cf"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_outline_color", Color("#4b304a"))
	title_label.add_theme_constant_override("outline_size", 8)
	left.add_child(title_label)
	var subtitle := _label("Два героя. Четыре места.\nОдна маленькая история, которую вы создаёте вместе.", 14 if (compact_layout or narrow_layout) else 18, Color("#f7dbc2"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(subtitle)
	left.add_child(HSeparator.new())
	var play := _button("ИГРАТЬ", Vector2(0, 44 if compact_layout else (48 if narrow_layout else 58)), true)
	play.pressed.connect(func(): _start_game(0))
	left.add_child(play)
	# «Продолжить» показываем только если уже есть прогресс.
	if saved_level > 0:
		var continue_button := _button("ПРОДОЛЖИТЬ  ·  УРОВЕНЬ %d" % (saved_level + 1), Vector2(0, 40 if compact_layout else (44 if narrow_layout else 52)), false)
		continue_button.pressed.connect(func(): _start_game(saved_level))
		left.add_child(continue_button)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	left.add_child(row)
	var row_h := 38 if compact_layout else (42 if narrow_layout else 46)
	var settings := _button("Настройки", Vector2(0, row_h), false)
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.pressed.connect(_show_settings)
	row.add_child(settings)
	var about := _button("Об игре", Vector2(0, row_h), false)
	about.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	about.pressed.connect(_show_about)
	row.add_child(about)
	if not compact_layout:
		var controls := _label("Герои управляются кнопками на экране или клавишами (A/D, пробел, Tab, E).\nСобирайте сердечки и решайте задачи вдвоём.", 13 if narrow_layout else 14, Color("#d8b7ba"))
		controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		left.add_child(controls)
		var footer := _label("Прогресс сохраняется автоматически  ·  офлайн", 12 if narrow_layout else 13, Color("#b692a1"))
		footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		left.add_child(footer)
	# На узких экранах галерею героев не показываем — ей просто не хватает места.
	if narrow_layout:
		return
	var gallery_card := PanelContainer.new()
	gallery_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gallery_card.add_theme_stylebox_override("panel", _style(Color(0.15, 0.10, 0.18, 0.84), Color("#dca6a1"), 2, 28))
	layout.add_child(gallery_card)
	var gallery := VBoxContainer.new()
	gallery.add_theme_constant_override("separation", 8)
	gallery_card.add_child(gallery)
	var gallery_title := _label("ГАЛЕРЕЯ ГЕРОЕВ", 15 if compact_layout else 17, Color("#f8cfaf"))
	gallery_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gallery.add_child(gallery_title)
	var portraits := HBoxContainer.new()
	portraits.alignment = BoxContainer.ALIGNMENT_CENTER
	portraits.add_theme_constant_override("separation", 12)
	portraits.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gallery.add_child(portraits)
	_add_portrait(portraits, BOY_TEX, "Парень\nспокойный и с юмором")
	_add_portrait(portraits, GIRL_TEX, "Девушка\nозорная и смелая")
	if not compact_layout:
		var note := _label("Два героя — одна история.\nМеняйте героя кнопкой ⇄.", 17, Color("#efd0bf"))
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gallery.add_child(note)

func _build_rotate_hint() -> void:
	var label := _label("↻\nПоверните\nэкран", 16, Color("#fff0cf"))
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)

func _add_portrait(parent: Container, texture: Texture2D, caption: String) -> void:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(110, 150) if compact_layout else Vector2(170, 330)
	frame.add_theme_stylebox_override("panel", _style(Color(0.34, 0.18, 0.28, 0.55), Color("#f0c09f"), 2, 22))
	box.add_child(frame)
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2(90, 120) if compact_layout else Vector2(160, 300)
	frame.add_child(image)
	var text := _label(caption, 12 if compact_layout else 15, Color("#fff0d0"))
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(text)
	parent.add_child(box)

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", CYRILLIC_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.18, 0.10, 0.18, 0.6))
	label.add_theme_constant_override("outline_size", 3)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

func _button(text: String, min_size: Vector2, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", CYRILLIC_FONT)
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", 20 if primary else 16)
	button.add_theme_color_override("font_color", Color("#fff0d0"))
	button.add_theme_stylebox_override("normal", _style(Color("#6c465e") if primary else Color(0.23, 0.15, 0.25, 0.88), Color("#edb79e"), 2, 16))
	button.add_theme_stylebox_override("hover", _style(Color("#a45f75"), Color("#ffe0bd"), 3, 16))
	button.add_theme_stylebox_override("pressed", _style(Color("#4d385d"), Color("#f5c398"), 3, 16))
	return button

func _start_game(start_level: int) -> void:
	# begin_game() нужно вызывать прямо из нажатия кнопки — так браузер разрешает звук.
	GameAudio.begin_game()
	get_tree().set_meta("littlehistory_start_level", clampi(start_level, 0, 3))
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _show_settings() -> void:
	_show_dialog("Настройки", KEYS_HELP, _build_sound_controls())

func _show_about() -> void:
	_show_dialog("Об игре", "«Наша маленькая история» — маленькое приключение о том, как вдвоём проще находить путь.\n\nСобирайте сердечки, ищите памятные предметы, активируйте механизмы и не забывайте переключаться между героями.\n\nВизуальный стиль создан с нуля по мотивам предоставленного стилевого референса; персонажи оригинальные.")

func _build_sound_controls() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var check := CheckButton.new()
	check.text = "Звук включён"
	check.add_theme_font_override("font", CYRILLIC_FONT)
	check.add_theme_font_size_override("font_size", 18)
	check.add_theme_color_override("font_color", Color("#fff0d0"))
	check.button_pressed = not GameAudio.muted
	check.toggled.connect(func(on: bool): GameAudio.set_muted(not on))
	box.add_child(check)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = GameAudio.volume
	slider.custom_minimum_size = Vector2(0, 28)
	slider.value_changed.connect(func(value: float): GameAudio.set_volume(value))
	box.add_child(slider)
	return box

func _show_dialog(title_text: String, body_text: String, extra: Control = null) -> void:
	if dialog != null:
		dialog.queue_free()
	var view := get_viewport_rect().size
	var dialog_w := minf(600.0, view.x - 24.0)
	dialog = PanelContainer.new()
	dialog.anchor_left = 0.5
	dialog.anchor_right = 0.5
	dialog.anchor_top = 0.5
	dialog.anchor_bottom = 0.5
	dialog.offset_left = 0.0
	dialog.offset_right = 0.0
	dialog.offset_top = 0.0
	dialog.offset_bottom = 0.0
	dialog.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dialog.grow_vertical = Control.GROW_DIRECTION_BOTH
	dialog.custom_minimum_size = Vector2(dialog_w, 0)
	dialog.add_theme_stylebox_override("panel", _style(Color(0.10, 0.07, 0.15, 0.98), Color("#efb69e"), 3, 26))
	add_child(dialog)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10 if compact_layout else 14)
	dialog.add_child(box)
	var title := _label(title_text, 24 if compact_layout else 28, Color("#fff0d0"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	# Длинный текст прокручивается и не вылезает за экран.
	var extra_h := 90.0 if extra != null else 0.0
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(dialog_w - 60.0, clampf(view.y - 260.0 - extra_h, 90.0, 300.0))
	box.add_child(scroll)
	var body := _label(body_text, 15 if compact_layout else 18, Color("#f0d1c4"))
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	if extra != null:
		box.add_child(extra)
	var close := _button("Закрыть", Vector2(0, 44 if compact_layout else 52), false)
	close.pressed.connect(func():
		if dialog != null:
			dialog.queue_free()
			dialog = null)
	box.add_child(close)
