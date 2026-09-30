extends Node
## Blocks gameplay input while something else owns it (dialogue, console, transitions).
## Each owner acquires with its own reason, so they never release each other's locks.

signal changed(is_open: bool)

var _locks: Dictionary[StringName, bool] = {}


func acquire(reason: StringName) -> void:
	var was_open := is_open()
	_locks[reason] = true
	if was_open:
		changed.emit(false)


func release(reason: StringName) -> void:
	if _locks.erase(reason) and is_open():
		changed.emit(true)


func is_open() -> bool:
	return _locks.is_empty()


func reasons() -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(_locks.keys())
	return out
