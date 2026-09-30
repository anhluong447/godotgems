extends Node
## Loads every data resource under res://data/ once and indexes it by id.
## Content is added by dropping a .tres into the right folder: no code change.

const CHARACTERS_DIR := "res://data/characters"
const ENEMIES_DIR := "res://data/enemies"
const ITEMS_DIR := "res://data/items"
const ABILITIES_DIR := "res://data/abilities"
const COMBAT_CONFIG_PATH := "res://data/config/combat_config.tres"

## A data resource was changed at runtime (debug `tune`). Systems caching values re-read it.
signal resource_tuned(res: Resource)

var combat_config: CombatConfig
var _abilities: Dictionary[StringName, AbilityDef] = {}
var _characters: Dictionary[StringName, CharacterDef] = {}
var _enemies: Dictionary[StringName, EnemyDef] = {}
var _items: Dictionary[StringName, ItemDef] = {}


func _ready() -> void:
	reload()
	# DebugService is added to the tree after us.
	_register_debug_commands.call_deferred()


func reload() -> void:
	combat_config = load(COMBAT_CONFIG_PATH) as CombatConfig
	if combat_config == null:
		push_warning("Registry: missing %s, using defaults" % COMBAT_CONFIG_PATH)
		combat_config = CombatConfig.new()
	_characters.clear()
	_enemies.clear()
	_items.clear()
	_abilities.clear()
	for res: Resource in _load_dir(ABILITIES_DIR):
		if res is AbilityDef:
			_index(_abilities, res.id, res)
	for res: Resource in _load_dir(CHARACTERS_DIR):
		if res is CharacterDef:
			_index(_characters, res.id, res)
	for res: Resource in _load_dir(ENEMIES_DIR):
		if res is EnemyDef:
			_index(_enemies, res.id, res)
	for res: Resource in _load_dir(ITEMS_DIR):
		if res is ItemDef:
			_index(_items, res.id, res)


func character(id: StringName) -> CharacterDef:
	return _characters.get(id)


func enemy(id: StringName) -> EnemyDef:
	return _enemies.get(id)


func item(id: StringName) -> ItemDef:
	return _items.get(id)


func ability(id: StringName) -> AbilityDef:
	return _abilities.get(id)


func ability_ids() -> Array[StringName]:
	return _sorted_keys(_abilities)


## Any indexed resource by id (abilities, characters, enemies, items), or "combat_config".
func find_any(id: StringName) -> Resource:
	if id == &"combat_config":
		return combat_config
	for table: Dictionary in [_abilities, _characters, _enemies, _items]:
		if table.has(id):
			return table[id]
	return null


# --- Live tuning (debug) ---

func _register_debug_commands() -> void:
	DebugService.register("tune", _cmd_tune, "Read/set a data property live", "<id> [property] [value]")
	DebugService.register("tune_save", _cmd_tune_save, "Write a tuned resource back to its .tres", "<id>")
	DebugService.register("abilities", func(_a: PackedStringArray) -> String: return ", ".join(ability_ids()), "List ability ids")


func _cmd_tune(args: PackedStringArray) -> String:
	if args.is_empty():
		return "usage: tune <id> [property] [value]"
	var res := find_any(StringName(args[0]))
	if res == null:
		return "unknown id '%s'" % args[0]
	if args.size() == 1:
		return _describe(res)
	var prop := args[1]
	if not _has_property(res, prop):
		return "%s has no property '%s'" % [args[0], prop]
	if args.size() == 2:
		return "%s.%s = %s" % [args[0], prop, var_to_str(res.get(prop))]
	var raw := " ".join(args.slice(2))
	var value: Variant = str_to_var(raw)
	if value == null:
		value = raw
	var old: Variant = res.get(prop)
	if typeof(old) != TYPE_NIL and typeof(value) != typeof(old):
		# Accept "3" for a float property and similar.
		value = type_convert(value, typeof(old))
	res.set(prop, value)
	resource_tuned.emit(res)
	return "%s.%s: %s -> %s" % [args[0], prop, var_to_str(old), var_to_str(res.get(prop))]


func _cmd_tune_save(args: PackedStringArray) -> String:
	if args.is_empty():
		return "usage: tune_save <id>"
	var res := find_any(StringName(args[0]))
	if res == null or res.resource_path.is_empty():
		return "unknown id '%s'" % args[0]
	if OS.has_feature("template"):
		return "tune_save only works when running from the project (not an exported build)"
	var err := ResourceSaver.save(res, res.resource_path)
	return "saved %s" % res.resource_path if err == OK else "save failed: %s" % error_string(err)


static func _has_property(res: Resource, prop: String) -> bool:
	for p: Dictionary in res.get_property_list():
		if p["name"] == prop and int(p["usage"]) & PROPERTY_USAGE_STORAGE:
			return true
	return false


static func _describe(res: Resource) -> String:
	var lines := PackedStringArray()
	for p: Dictionary in res.get_property_list():
		var usage := int(p["usage"])
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and usage & PROPERTY_USAGE_STORAGE:
			var v: Variant = res.get(p["name"])
			if v is Resource or v is Array:
				continue
			lines.append("  %s = %s" % [p["name"], var_to_str(v)])
	return "\n".join(lines)


func character_ids() -> Array[StringName]:
	return _sorted_keys(_characters)


func enemy_ids() -> Array[StringName]:
	return _sorted_keys(_enemies)


func item_ids() -> Array[StringName]:
	return _sorted_keys(_items)


func _index(table: Dictionary, id: StringName, res: Resource) -> void:
	if id == &"":
		push_error("Registry: %s has no id" % res.resource_path)
		return
	if table.has(id):
		push_error("Registry: duplicate id '%s' (%s)" % [id, res.resource_path])
		return
	table[id] = res


static func _load_dir(dir_path: String) -> Array[Resource]:
	var out: Array[Resource] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for file: String in dir.get_files():
		# Exported builds rename resources to *.remap.
		var clean := file.trim_suffix(".remap")
		if clean.ends_with(".tres") or clean.ends_with(".res"):
			var res := load(dir_path.path_join(clean))
			if res != null:
				out.append(res)
	return out


static func _sorted_keys(table: Dictionary) -> Array[StringName]:
	var keys: Array[StringName] = []
	keys.assign(table.keys())
	keys.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return keys
