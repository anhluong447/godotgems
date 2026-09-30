extends Node
## Player preferences (not part of save slots). Stored in user://settings.cfg.

signal changed(key: StringName)

const PATH := "user://settings.cfg"
const SECTION := "settings"
const DEFAULTS := {
	&"master_volume": 0.8,
	&"music_volume": 0.7,
	&"sfx_volume": 0.8,
	&"ui_volume": 0.8,
	&"fullscreen": false,
	&"screen_shake": 1.0,
	&"text_speed": 45.0,
	&"gentle_mode": false,
}

var _values: Dictionary = DEFAULTS.duplicate()


func _ready() -> void:
	load_settings()
	apply_all()


func get_value(key: StringName) -> Variant:
	return _values.get(key, DEFAULTS.get(key))


func set_value(key: StringName, value: Variant, save: bool = true) -> void:
	_values[key] = value
	_apply(key)
	changed.emit(key)
	if save:
		save_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for key: StringName in DEFAULTS:
		_values[key] = cfg.get_value(SECTION, String(key), DEFAULTS[key])


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key: StringName in _values:
		cfg.set_value(SECTION, String(key), _values[key])
	var err := cfg.save(PATH)
	if err != OK:
		push_error("Settings: could not save (%s)" % error_string(err))


func apply_all() -> void:
	for key: StringName in _values:
		_apply(key)


func _apply(key: StringName) -> void:
	match key:
		&"master_volume":
			_set_bus_volume(&"Master", float(get_value(key)))
		&"music_volume":
			_set_bus_volume(&"Music", float(get_value(key)))
		&"sfx_volume":
			_set_bus_volume(&"SFX", float(get_value(key)))
		&"ui_volume":
			_set_bus_volume(&"UI", float(get_value(key)))
		&"fullscreen":
			if DisplayServer.get_name() == "headless":
				return
			var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if bool(get_value(key)) else DisplayServer.WINDOW_MODE_WINDOWED
			DisplayServer.window_set_mode(mode)


static func _set_bus_volume(bus_name: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(idx, linear <= 0.001)
