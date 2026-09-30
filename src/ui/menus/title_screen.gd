class_name TitleScreen
extends Control
## Entry scene: content warning (first run), continue / new game / load / settings / quit.

var _menu: VBoxContainer
var _warning: VBoxContainer
var _slots: SlotList
var _settings: SettingsPanel
var _panel: PanelContainer
var _continue: Button
var _status: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_title()
	_build_panel()
	if bool(SettingsService.get_value(&"content_warning_seen")):
		_show(_menu)
	else:
		_show(_warning)


func _build_background() -> void:
	var bg := TextureRect.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.98, 0.78, 0.62))
	gradient.set_color(1, Color(0.36, 0.52, 0.42))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 16
	tex.height = 64
	bg.texture = tex
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# Falling spring petals.
	var petals := CPUParticles2D.new()
	petals.amount = 40
	petals.lifetime = 9.0
	petals.preprocess = 9.0
	petals.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	petals.emission_rect_extents = Vector2(360, 4)
	petals.position = Vector2(320, -10)
	petals.direction = Vector2(0.3, 1)
	petals.spread = 20.0
	petals.gravity = Vector2(6, 8)
	petals.initial_velocity_min = 8.0
	petals.initial_velocity_max = 20.0
	petals.angular_velocity_min = -90.0
	petals.angular_velocity_max = 90.0
	petals.scale_amount_min = 1.5
	petals.scale_amount_max = 3.0
	petals.color = Color(1.0, 0.8, 0.86, 0.9)
	add_child(petals)


func _build_title() -> void:
	var title := Label.new()
	title.text = "UI_GAME_TITLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 42)
	title.size = Vector2(640, 40)
	title.add_theme_font_override("font", Fx.BOLD_FONT)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	title.add_theme_color_override("font_outline_color", Color(0.35, 0.18, 0.15))
	title.add_theme_constant_override("outline_size", 6)
	add_child(title)
	var subtitle := Label.new()
	subtitle.text = "UI_GAME_SUBTITLE"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(0, 86)
	subtitle.size = Vector2(640, 16)
	subtitle.add_theme_font_size_override("font_size", 9)
	subtitle.add_theme_color_override("font_color", Color(0.25, 0.15, 0.12))
	add_child(subtitle)
	var version := Label.new()
	version.text = "v%s" % ProjectSettings.get_setting("application/config/version", "0.0.0")
	version.position = Vector2(640 - 60, 360 - 16)
	version.add_theme_font_size_override("font_size", 7)
	add_child(version)


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(200, 0)
	add_child(_panel)
	var outer := VBoxContainer.new()
	_panel.add_child(outer)

	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 3)
	outer.add_child(_menu)
	_continue = _add_button(_menu, "UI_CONTINUE", _on_continue)
	_add_button(_menu, "UI_NEW_GAME", _on_new_game)
	_add_button(_menu, "UI_LOAD", func() -> void: _show(_slots))
	_add_button(_menu, "UI_SETTINGS", func() -> void: _show(_settings))
	_add_button(_menu, "UI_QUIT", func() -> void: get_tree().quit())

	_warning = VBoxContainer.new()
	_warning.add_theme_constant_override("separation", 6)
	outer.add_child(_warning)
	var w_title := Label.new()
	w_title.text = "UI_CW_TITLE"
	w_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w_title.add_theme_font_size_override("font_size", 12)
	w_title.add_theme_color_override("font_color", Color(1, 0.75, 0.5))
	_warning.add_child(w_title)
	var body := Label.new()
	body.text = "UI_CW_BODY"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(300, 0)
	body.add_theme_font_size_override("font_size", 8)
	_warning.add_child(body)
	var gentle := CheckBox.new()
	gentle.text = "UI_GENTLE_MODE"
	gentle.button_pressed = bool(SettingsService.get_value(&"gentle_mode"))
	gentle.toggled.connect(func(on: bool) -> void: SettingsService.set_value(&"gentle_mode", on))
	_warning.add_child(gentle)
	_add_button(_warning, "UI_CW_ACCEPT", _on_warning_accepted)

	_slots = SlotList.new()
	_slots.back_requested.connect(func() -> void: _show(_menu))
	_slots.slot_chosen.connect(_start_from_slot)
	outer.add_child(_slots)
	_settings = SettingsPanel.new()
	_settings.back_requested.connect(func() -> void: _show(_menu))
	outer.add_child(_settings)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 8)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(_status)


func _add_button(parent: Control, key: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = key
	b.pressed.connect(callback)
	b.focus_entered.connect(func() -> void: AudioService.play_ui(&"ui_move"))
	parent.add_child(b)
	return b


func _show(page: Control) -> void:
	for p: Control in [_menu, _warning, _slots, _settings]:
		p.visible = p == page
	_status.text = ""
	if page == _menu:
		_continue.disabled = SaveService.latest_slot() < 0
		var first := _menu.get_child(1 if _continue.disabled else 0) as Button
		first.grab_focus.call_deferred()
	elif page == _warning:
		(_warning.get_child(_warning.get_child_count() - 1) as Button).grab_focus.call_deferred()
	elif page == _slots:
		_slots.open(SlotList.Mode.LOAD)
	elif page == _settings:
		_settings.focus_first()
	_layout.call_deferred(page == _warning)


func _layout(centered: bool) -> void:
	_panel.reset_size()
	var view := get_viewport_rect().size
	var y := (view.y - _panel.size.y) * 0.5 if centered else maxf(120.0, view.y - _panel.size.y - 24.0)
	_panel.position = Vector2(((view.x - _panel.size.x) * 0.5), y).floor()


func _on_warning_accepted() -> void:
	SettingsService.set_value(&"content_warning_seen", true)
	AudioService.play_ui(&"ui_confirm")
	_show(_menu)


func _on_new_game() -> void:
	AudioService.play_ui(&"ui_confirm")
	GameState.new_game()
	SceneRouter.change_scene(SceneRouter.GAME_SCENE)


func _on_continue() -> void:
	var slot := SaveService.latest_slot()
	if slot >= 0:
		_start_from_slot(slot)


func _start_from_slot(slot: int) -> void:
	if not SaveService.read_into_state(slot):
		_status.text = "UI_LOAD_FAILED"
		return
	AudioService.play_ui(&"ui_confirm")
	SceneRouter.change_scene(SceneRouter.GAME_SCENE)
