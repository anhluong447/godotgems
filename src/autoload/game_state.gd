extends Node
## The persistent session model: everything that goes into a save file.
## It is passive: other systems read and write it, it never reaches into the scene tree.
## Future story systems (weeks, anchors, gate) will add their own sections here.

const DEFAULT_MAP := "res://maps/test_field.tscn"
const DEFAULT_SPAWN: StringName = &"start"
const DEFAULT_PARTY: Array[StringName] = [&"vu", &"binh_an"]

var inventory: Inventory = Inventory.new()
var flags: Dictionary = {}
var party_order: Array[StringName] = []
var progress: Dictionary[StringName, Progression] = {}
## character id -> { "hp": float, "energy": float }. Captured on save, applied on load.
var vitals: Dictionary[StringName, Dictionary] = {}
var map_path: String = DEFAULT_MAP
## Display name of the current map (runtime; copied into save metadata).
var map_display_name: String = ""
var spawn_id: StringName = DEFAULT_SPAWN
## Leader position captured right before saving (written by the party on EventBus.before_save).
var saved_position: Variant = null
## Exact position restored from a save. Consumed once by the map host.
var pending_position: Variant = null
var playtime: float = 0.0


func _ready() -> void:
	new_game()


func _process(delta: float) -> void:
	if not get_tree().paused:
		playtime += delta


func new_game() -> void:
	inventory.clear()
	flags.clear()
	vitals.clear()
	party_order = DEFAULT_PARTY.duplicate()
	progress.clear()
	for id: StringName in party_order:
		progress[id] = _new_progression()
	map_path = DEFAULT_MAP
	spawn_id = DEFAULT_SPAWN
	saved_position = null
	pending_position = null
	playtime = 0.0


func progression(character_id: StringName) -> Progression:
	if not progress.has(character_id):
		progress[character_id] = _new_progression()
	return progress[character_id]


# --- Flags ---

func set_flag(key: StringName, value: Variant = true) -> void:
	flags[String(key)] = value


func get_flag(key: StringName, default: Variant = null) -> Variant:
	return flags.get(String(key), default)


func has_flag(key: StringName) -> bool:
	return flags.has(String(key)) and bool(flags[String(key)])


# --- Serialization ---

func to_dict() -> Dictionary:
	var prog := {}
	for id: StringName in progress:
		prog[String(id)] = progress[id].to_dict()
	var vit := {}
	for id: StringName in vitals:
		vit[String(id)] = vitals[id]
	var ids: Array[String] = []
	for id: StringName in party_order:
		ids.append(String(id))
	return {
		"save_version": SaveMigrator.CURRENT_VERSION,
		"map_path": map_path,
		"spawn_id": String(spawn_id),
		"position": [saved_position.x, saved_position.y] if saved_position is Vector2 else null,
		"inventory": inventory.to_dict(),
		"flags": flags.duplicate(true),
		"party_order": ids,
		"progress": prog,
		"vitals": vit,
		"playtime": playtime,
	}


func load_dict(data: Dictionary) -> void:
	new_game()
	map_path = str(data.get("map_path", DEFAULT_MAP))
	spawn_id = StringName(str(data.get("spawn_id", DEFAULT_SPAWN)))
	var pos: Variant = data.get("position")
	pending_position = Vector2(float(pos[0]), float(pos[1])) if pos is Array and pos.size() == 2 else null
	inventory.load_dict(data.get("inventory", {}))
	flags = (data.get("flags", {}) as Dictionary).duplicate(true)
	var order: Array = data.get("party_order", [])
	if not order.is_empty():
		party_order.clear()
		for id: Variant in order:
			party_order.append(StringName(str(id)))
	var prog: Dictionary = data.get("progress", {})
	for key: Variant in prog:
		progression(StringName(str(key))).load_dict(prog[key])
	var vit: Dictionary = data.get("vitals", {})
	for key: Variant in vit:
		vitals[StringName(str(key))] = vit[key]
	playtime = float(data.get("playtime", 0.0))


func _new_progression() -> Progression:
	return Progression.new(30, 20.0, 1.5)
