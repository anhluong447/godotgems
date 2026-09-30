class_name StatBlock
extends RefCounted
## Base stats plus stackable modifiers. final = (base + sum(add)) * (1 + sum(mult)).

signal changed

const MAX_HP: StringName = &"max_hp"
const ATK: StringName = &"atk"
const DEF: StringName = &"def"
const SPD: StringName = &"spd"
const MAX_ENERGY: StringName = &"max_energy"
const ENERGY_REGEN: StringName = &"energy_regen"

var _base: Dictionary[StringName, float] = {}
## modifier_id -> { "stat": StringName, "add": float, "mult": float }
var _modifiers: Dictionary[StringName, Dictionary] = {}


func _init(base: Dictionary = {}) -> void:
	for key: Variant in base:
		_base[StringName(key)] = float(base[key])


func get_base(stat: StringName) -> float:
	return _base.get(stat, 0.0)


func set_base(stat: StringName, value: float) -> void:
	_base[stat] = value
	changed.emit()


func add_base(stat: StringName, amount: float) -> void:
	set_base(stat, get_base(stat) + amount)


func get_stat(stat: StringName) -> float:
	var add := 0.0
	var mult := 0.0
	for mod: Dictionary in _modifiers.values():
		if mod["stat"] == stat:
			add += float(mod["add"])
			mult += float(mod["mult"])
	return maxf((get_base(stat) + add) * (1.0 + mult), 0.0)


func add_modifier(id: StringName, stat: StringName, add: float = 0.0, mult: float = 0.0) -> void:
	_modifiers[id] = {"stat": stat, "add": add, "mult": mult}
	changed.emit()


func remove_modifier(id: StringName) -> void:
	if _modifiers.erase(id):
		changed.emit()


func has_modifier(id: StringName) -> bool:
	return _modifiers.has(id)
