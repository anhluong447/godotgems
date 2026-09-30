extends Node
## Save slots on disk. Writes are atomic: data goes to a temp file which then
## replaces the old save, so a crash mid-write never corrupts a slot.

signal saved(slot: int)
signal loaded(slot: int)

## Overridable so tests never touch real saves.
var dir: String = "user://saves"
const SLOT_COUNT := 3
const AUTOSAVE_SLOT := 0


func slot_path(slot: int) -> String:
	return dir.path_join("autosave.json" if slot == AUTOSAVE_SLOT else "slot_%d.json" % slot)


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func save_game(slot: int) -> bool:
	EventBus.before_save.emit()
	var data := GameState.to_dict()
	data["meta"] = {
		"saved_at": Time.get_datetime_string_from_system(),
		"playtime": GameState.playtime,
		"map_path": GameState.map_path,
		"map_name": GameState.map_display_name,
	}
	var ok := write_atomic(slot_path(slot), SaveCodec.encode(data))
	if ok:
		saved.emit(slot)
	return ok


## In-game load: replace GameState and move to the saved map.
func load_game(slot: int) -> bool:
	if not read_into_state(slot):
		return false
	EventBus.after_load.emit()
	SceneRouter.change_map(GameState.map_path, GameState.spawn_id)
	loaded.emit(slot)
	return true


## Replace GameState with a slot's data without touching the scene (title screen).
func read_into_state(slot: int) -> bool:
	var data := read_slot(slot)
	if data.is_empty():
		push_warning("SaveService: slot %d is empty or invalid" % slot)
		return false
	GameState.load_dict(data)
	return true


## Metadata for slot lists: {} if empty, else { saved_at, playtime, map_name, ... }.
func slot_meta(slot: int) -> Dictionary:
	var data := read_slot(slot)
	return data.get("meta", {"map_name": "?"}) if not data.is_empty() else {}


## Most recently written slot, or -1 if there are no saves.
func latest_slot() -> int:
	var best := -1
	var best_time := -1
	for slot: int in range(0, SLOT_COUNT + 1):
		if has_save(slot):
			var t := FileAccess.get_modified_time(slot_path(slot))
			if t > best_time:
				best_time = t
				best = slot
	return best


## All slots shown in menus: autosave first, then manual slots.
static func all_slots() -> Array[int]:
	var out: Array[int] = [AUTOSAVE_SLOT]
	for i: int in range(1, SLOT_COUNT + 1):
		out.append(i)
	return out


func read_slot(slot: int) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	return SaveCodec.decode(FileAccess.get_file_as_string(path))


func delete_slot(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(slot_path(slot))


static func write_atomic(path: String, text: String) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("SaveService: cannot write %s (%s)" % [tmp, error_string(FileAccess.get_open_error())])
		return false
	f.store_string(text)
	f.close()
	var backup := path + ".bak"
	if FileAccess.file_exists(path):
		DirAccess.rename_absolute(path, backup)
	var err := DirAccess.rename_absolute(tmp, path)
	if err != OK:
		push_error("SaveService: rename failed (%s)" % error_string(err))
		if FileAccess.file_exists(backup):
			DirAccess.rename_absolute(backup, path)
		return false
	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(backup)
	return true
