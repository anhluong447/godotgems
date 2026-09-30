class_name PauseMenu
extends Control
## Pause, settings, save/load. Runs while the tree is paused.

const SAVE_SLOT := 1

var _root_box: VBoxContainer
var _settings_box: VBoxContainer
var _status: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if InputGate.reasons().has(&"console"):
			return
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	visible = true
	get_tree().paused = true
	_show_root()
	_status.text = ""
	AudioService.play_ui(&"ui_confirm")


func close() -> void:
	visible = false
	get_tree().paused = false
	AudioService.play_ui(&"ui_back")


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(220, 70)
	panel.custom_minimum_size = Vector2(200, 0)
	add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 4)
	panel.add_child(outer)
	var title := Label.new()
	title.text = "Tạm dừng"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	outer.add_child(title)

	_root_box = VBoxContainer.new()
	_root_box.add_theme_constant_override("separation", 3)
	outer.add_child(_root_box)
	_add_button(_root_box, "Tiếp tục", close)
	_add_button(_root_box, "Lưu game", _on_save)
	_add_button(_root_box, "Tải game", _on_load)
	_add_button(_root_box, "Cài đặt", _show_settings)
	_add_button(_root_box, "Thoát", func() -> void: get_tree().quit())

	_settings_box = VBoxContainer.new()
	_settings_box.add_theme_constant_override("separation", 3)
	outer.add_child(_settings_box)
	_add_slider(_settings_box, "Âm lượng tổng", &"master_volume")
	_add_slider(_settings_box, "Nhạc", &"music_volume")
	_add_slider(_settings_box, "Hiệu ứng", &"sfx_volume")
	_add_slider(_settings_box, "Rung màn hình", &"screen_shake")
	var fs := CheckBox.new()
	fs.text = "Toàn màn hình"
	fs.button_pressed = bool(SettingsService.get_value(&"fullscreen"))
	fs.toggled.connect(func(on: bool) -> void: SettingsService.set_value(&"fullscreen", on))
	_settings_box.add_child(fs)
	_add_button(_settings_box, "Quay lại", _show_root)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 8)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(_status)


func _add_button(parent: Control, text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(callback)
	b.focus_entered.connect(func() -> void: AudioService.play_ui(&"ui_move"))
	parent.add_child(b)
	return b


func _add_slider(parent: Control, text: String, key: StringName) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(90, 0)
	label.add_theme_font_size_override("font_size", 8)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(90, 12)
	slider.value = float(SettingsService.get_value(key))
	slider.value_changed.connect(func(v: float) -> void: SettingsService.set_value(key, v))
	row.add_child(slider)
	parent.add_child(row)


func _show_root() -> void:
	_root_box.visible = true
	_settings_box.visible = false
	(_root_box.get_child(0) as Button).grab_focus.call_deferred()


func _show_settings() -> void:
	_root_box.visible = false
	_settings_box.visible = true
	(_settings_box.get_child(0).get_child(1) as Control).grab_focus.call_deferred()


func _on_save() -> void:
	var ok := SaveService.save_game(SAVE_SLOT)
	_status.text = "Đã lưu vào ô %d" % SAVE_SLOT if ok else "Lưu thất bại!"


func _on_load() -> void:
	if not SaveService.has_save(SAVE_SLOT):
		_status.text = "Chưa có bản lưu"
		return
	close()
	SaveService.load_game(SAVE_SLOT)
