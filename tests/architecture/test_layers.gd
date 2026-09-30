extends GutTest
## Enforces the dependency rules in Docs/ARCHITECTURE.md by scanning source text.

const AUTOLOADS := ["EventBus", "InputGate", "Registry", "GameState", "SettingsService",
	"AudioService", "SaveService", "SceneRouter", "HitstopService", "DebugService"]


func test_core_is_pure() -> void:
	for path: String in _scripts("res://src/core"):
		var src := FileAccess.get_file_as_string(path)
		assert_false(_extends_node(src), "%s: core must not extend Node types" % path)
		assert_false(src.contains("get_tree("), "%s: core must not use the scene tree" % path)
		for a: String in AUTOLOADS:
			assert_false(_uses_identifier(src, a), "%s: core must not use autoload %s" % [path, a])


func test_definitions_are_data_only() -> void:
	for path: String in _scripts("res://src/gameplay/definitions"):
		var src := FileAccess.get_file_as_string(path)
		assert_true(src.contains("extends Resource"), "%s: definitions must be Resources" % path)
		assert_false(src.contains("get_tree("), "%s: definitions must not use the tree" % path)
		for a: String in AUTOLOADS:
			assert_false(_uses_identifier(src, a), "%s: definitions must not use autoload %s" % [path, a])


func test_ui_does_not_mutate_game_state() -> void:
	var forbidden := ["GameState.inventory.add", "GameState.inventory.remove", "GameState.set_flag", ".apply_damage(", ".take_damage("]
	for path: String in _scripts("res://src/ui"):
		var src := FileAccess.get_file_as_string(path)
		for f: String in forbidden:
			assert_false(src.contains(f), "%s: UI must not call %s" % [path, f])


func test_every_script_is_statically_typed_functions() -> void:
	var untyped := RegEx.create_from_string("(?m)^\\s*func\\s+\\w+\\([^)]*\\)\\s*:")
	for path: String in _scripts("res://src"):
		var src := FileAccess.get_file_as_string(path)
		assert_null(untyped.search(src), "%s: functions must declare a return type" % path)


static func _extends_node(src: String) -> bool:
	var re := RegEx.create_from_string("(?m)^extends\\s+(Node|Node2D|Control|CanvasItem|Area2D|CharacterBody2D|CanvasLayer)\\b")
	return re.search(src) != null


static func _uses_identifier(src: String, identifier: String) -> bool:
	var re := RegEx.create_from_string("\\b%s\\." % identifier)
	for line: String in src.split("\n"):
		if line.strip_edges().begins_with("#"):
			continue
		if re.search(line) != null:
			return true
	return false


static func _scripts(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for f: String in dir.get_files():
		if f.ends_with(".gd"):
			out.append(dir_path.path_join(f))
	for sub: String in dir.get_directories():
		out.append_array(_scripts(dir_path.path_join(sub)))
	return out
