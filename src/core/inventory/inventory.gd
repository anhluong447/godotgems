class_name Inventory
extends RefCounted
## Item id -> count. Stack limits are passed in by the caller (from ItemDef) so this stays pure.

signal changed(item_id: StringName, count: int)
## Emitted after clear() or load_dict(): listeners should re-read everything.
signal reset

var _items: Dictionary[StringName, int] = {}


## Adds up to `max_stack`. Returns how many were actually added.
func add(item_id: StringName, amount: int = 1, max_stack: int = 999) -> int:
	if amount <= 0:
		return 0
	var have := count(item_id)
	var added := mini(amount, maxi(max_stack - have, 0))
	if added > 0:
		_items[item_id] = have + added
		changed.emit(item_id, _items[item_id])
	return added


## Removes exactly `amount` or nothing. Returns success.
func remove(item_id: StringName, amount: int = 1) -> bool:
	var have := count(item_id)
	if amount <= 0 or have < amount:
		return false
	if have == amount:
		_items.erase(item_id)
	else:
		_items[item_id] = have - amount
	changed.emit(item_id, count(item_id))
	return true


func count(item_id: StringName) -> int:
	return _items.get(item_id, 0)


func has(item_id: StringName, amount: int = 1) -> bool:
	return count(item_id) >= amount


func item_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_items.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


func is_empty() -> bool:
	return _items.is_empty()


func clear() -> void:
	_items.clear()
	reset.emit()


func to_dict() -> Dictionary:
	var out := {}
	for id: StringName in _items:
		out[String(id)] = _items[id]
	return out


func load_dict(data: Dictionary) -> void:
	_items.clear()
	for key: Variant in data:
		var n := int(data[key])
		if n > 0:
			_items[StringName(str(key))] = n
	reset.emit()
