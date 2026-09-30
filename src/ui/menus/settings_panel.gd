class_name SettingsPanel
extends VBoxContainer
## Settings page shared by the title screen and the pause menu.
## Static labels use translation keys directly (Godot auto-translates them live).

signal back_requested

var _first_focus: Control


func _ready() -> void:
	add_theme_constant_override("separation", 3)
	_add_slider("UI_VOL_MASTER", &"master_volume", 0.0, 1.0, 0.05)
	_add_slider("UI_VOL_MUSIC", &"music_volume", 0.0, 1.0, 0.05)
	_add_slider("UI_VOL_SFX", &"sfx_volume", 0.0, 1.0, 0.05)
	_add_slider("UI_SCREEN_SHAKE", &"screen_shake", 0.0, 1.0, 0.05)
	_add_slider("UI_TEXT_SPEED", &"text_speed", 15.0, 120.0, 5.0)
	_add_check("UI_FULLSCREEN", &"fullscreen")
	_add_check("UI_GENTLE_MODE", &"gentle_mode")
	_add_language()
	var back := Button.new()
	back.text = "UI_BACK"
	back.pressed.connect(func() -> void: back_requested.emit())
	add_child(back)


func focus_first() -> void:
	if _first_focus != null:
		_first_focus.grab_focus.call_deferred()


func _row(label_key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_key
	label.custom_minimum_size = Vector2(96, 0)
	label.add_theme_font_size_override("font_size", 8)
	row.add_child(label)
	add_child(row)
	return row


func _add_slider(label_key: String, key: StringName, lo: float, hi: float, step: float) -> void:
	var slider := HSlider.new()
	slider.min_value = lo
	slider.max_value = hi
	slider.step = step
	slider.custom_minimum_size = Vector2(90, 12)
	slider.value = float(SettingsService.get_value(key))
	slider.value_changed.connect(func(v: float) -> void: SettingsService.set_value(key, v))
	_row(label_key).add_child(slider)
	if _first_focus == null:
		_first_focus = slider


func _add_check(label_key: String, key: StringName) -> void:
	var check := CheckBox.new()
	check.button_pressed = bool(SettingsService.get_value(key))
	check.toggled.connect(func(on: bool) -> void: SettingsService.set_value(key, on))
	_row(label_key).add_child(check)


func _add_language() -> void:
	var option := OptionButton.new()
	var current := str(SettingsService.get_value(&"language"))
	for i: int in SettingsService.LANGUAGES.size():
		var code := SettingsService.LANGUAGES[i]
		option.add_item(TranslationServer.get_locale_name(code) if code != "vi" else "Tiếng Việt", i)
		if code == current:
			option.select(i)
	option.item_selected.connect(func(i: int) -> void: SettingsService.set_value(&"language", SettingsService.LANGUAGES[i]))
	_row("UI_LANGUAGE").add_child(option)
