class_name SaveMigrator
extends RefCounted
## Upgrades old save dictionaries step by step to CURRENT_VERSION.
## To add a version: bump CURRENT_VERSION and add `_migrate_<old>_to_<new>`.

const CURRENT_VERSION := 1


static func migrate(data: Dictionary) -> Dictionary:
	var out := data.duplicate(true)
	var version := int(out.get("save_version", 0))
	if version > CURRENT_VERSION:
		push_error("Save version %d is newer than supported %d" % [version, CURRENT_VERSION])
		return {}
	while version < CURRENT_VERSION:
		var method := "_migrate_%d_to_%d" % [version, version + 1]
		out = call_static(method, out)
		version += 1
		out["save_version"] = version
	return out


static func call_static(method: String, data: Dictionary) -> Dictionary:
	match method:
		"_migrate_0_to_1":
			return _migrate_0_to_1(data)
	push_error("Missing save migration: %s" % method)
	return data


## v0 was the pre-release format without `flags`.
static func _migrate_0_to_1(data: Dictionary) -> Dictionary:
	if not data.has("flags"):
		data["flags"] = {}
	return data
