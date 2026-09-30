class_name ResourcePool
extends RefCounted
## A bounded value such as HP, energy (Xuân Lực) or poise.

signal changed(current: float, maximum: float)
signal depleted
signal filled

var maximum: float
var current: float


func _init(p_maximum: float = 1.0, start_full: bool = true) -> void:
	maximum = maxf(p_maximum, 0.0)
	current = maximum if start_full else 0.0


func is_empty() -> bool:
	return current <= 0.0


func is_full() -> bool:
	return current >= maximum


func ratio() -> float:
	return 0.0 if maximum <= 0.0 else current / maximum


func can_afford(amount: float) -> bool:
	return current >= amount


## Removes up to `amount`. Returns the amount actually removed.
func drain(amount: float) -> float:
	if amount <= 0.0 or current <= 0.0:
		return 0.0
	var removed := minf(amount, current)
	_set_current(current - removed)
	return removed


## All-or-nothing spend. Returns false (and spends nothing) if not enough.
func spend(amount: float) -> bool:
	if not can_afford(amount):
		return false
	drain(amount)
	return true


func restore(amount: float) -> float:
	if amount <= 0.0 or current >= maximum:
		return 0.0
	var added := minf(amount, maximum - current)
	_set_current(current + added)
	return added


func fill() -> void:
	_set_current(maximum)


func set_current(value: float) -> void:
	_set_current(clampf(value, 0.0, maximum))


func set_maximum(value: float, keep_ratio: bool = false) -> void:
	var r := ratio()
	maximum = maxf(value, 0.0)
	_set_current(clampf(r * maximum if keep_ratio else current, 0.0, maximum))


func _set_current(value: float) -> void:
	var was_empty := is_empty()
	var was_full := is_full()
	current = value
	changed.emit(current, maximum)
	if is_empty() and not was_empty:
		depleted.emit()
	if is_full() and not was_full:
		filled.emit()
