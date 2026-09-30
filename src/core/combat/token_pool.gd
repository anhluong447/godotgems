class_name TokenPool
extends RefCounted
## Limits how many holders may do something at once (e.g. enemies attacking the party).
## Holders are identified by instance id; acquiring twice is idempotent.

var capacity: int
var _holders: Dictionary[int, bool] = {}


func _init(p_capacity: int = 2) -> void:
	capacity = maxi(p_capacity, 0)


func try_acquire(holder_id: int) -> bool:
	if _holders.has(holder_id):
		return true
	if _holders.size() >= capacity:
		return false
	_holders[holder_id] = true
	return true


func release(holder_id: int) -> void:
	_holders.erase(holder_id)


func holds(holder_id: int) -> bool:
	return _holders.has(holder_id)


func in_use() -> int:
	return _holders.size()


## Drops holders that no longer exist (freed enemies that never released).
func prune(is_alive: Callable) -> void:
	for id: int in _holders.keys():
		if not is_alive.call(id):
			_holders.erase(id)


func clear() -> void:
	_holders.clear()
