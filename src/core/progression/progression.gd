class_name Progression
extends RefCounted
## Level and XP for one party member.
## XP needed to go from level L to L+1 = round(base * L ^ exponent).

signal leveled_up(new_level: int)

var level: int = 1
var xp: int = 0
var max_level: int = 30
var base_xp: float = 20.0
var exponent: float = 1.5


func _init(p_max_level: int = 30, p_base_xp: float = 20.0, p_exponent: float = 1.5) -> void:
	max_level = p_max_level
	base_xp = p_base_xp
	exponent = p_exponent


func xp_to_next() -> int:
	if level >= max_level:
		return 0
	return maxi(roundi(base_xp * pow(level, exponent)), 1)


## Returns number of levels gained.
func add_xp(amount: int) -> int:
	if amount <= 0 or level >= max_level:
		return 0
	xp += amount
	var gained := 0
	while level < max_level and xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		gained += 1
		leveled_up.emit(level)
	if level >= max_level:
		xp = 0
	return gained


func to_dict() -> Dictionary:
	return {"level": level, "xp": xp}


func load_dict(data: Dictionary) -> void:
	level = clampi(int(data.get("level", 1)), 1, max_level)
	xp = maxi(int(data.get("xp", 0)), 0)
