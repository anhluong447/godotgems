extends Node
## Loads every data resource under res://data/ once and indexes it by id.
## Content is added by dropping a .tres into the right folder: no code change.

const CHARACTERS_DIR := "res://data/characters"
const ENEMIES_DIR := "res://data/enemies"
const ITEMS_DIR := "res://data/items"
const COMBAT_CONFIG_PATH := "res://data/config/combat_config.tres"

var combat_config: CombatConfig
var _characters: Dictionary[StringName, CharacterDef] = {}
var _enemies: Dictionary[StringName, EnemyDef] = {}
var _items: Dictionary[StringName, ItemDef] = {}


func _ready() -> void:
	reload()


func reload() -> void:
	combat_config = load(COMBAT_CONFIG_PATH) as CombatConfig
	if combat_config == null:
		push_warning("Registry: missing %s, using defaults" % COMBAT_CONFIG_PATH)
		combat_config = CombatConfig.new()
	_characters.clear()
	_enemies.clear()
	_items.clear()
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
