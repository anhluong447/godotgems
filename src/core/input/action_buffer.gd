class_name ActionBuffer
extends RefCounted
## Remembers pressed actions for a short window so inputs made slightly early still count
## (combo chaining, dodge during recovery). Pure: time is advanced via tick().

var window: float
var _pending: Dictionary[StringName, float] = {}


func _init(p_window: float = 0.15) -> void:
	window = p_window


func press(action: StringName, custom_window: float = -1.0) -> void:
	_pending[action] = window if custom_window < 0.0 else custom_window


func tick(delta: float) -> void:
	for action: StringName in _pending.keys():
		_pending[action] -= delta
		if _pending[action] <= 0.0:
			_pending.erase(action)


func peek(action: StringName) -> bool:
	return _pending.has(action)


## Returns true once per press, then forgets it.
func consume(action: StringName) -> bool:
	if _pending.has(action):
		_pending.erase(action)
		return true
	return false


func clear() -> void:
	_pending.clear()
