extends GutTest
## Every translation key used in code/scenes must exist in assets/i18n/ui.csv with all languages.

const CSV_PATH := "res://assets/i18n/ui.csv"


func _load_table() -> Dictionary:
	var table := {}
	var f := FileAccess.open(CSV_PATH, FileAccess.READ)
	var header := f.get_csv_line()
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() < 2 or row[0].is_empty():
			continue
		table[row[0]] = row
	table["__header"] = header
	return table


func test_csv_rows_are_complete() -> void:
	var table := _load_table()
	var header: PackedStringArray = table["__header"]
	assert_eq(header[0], "keys")
	for key: String in table:
		if key == "__header":
			continue
		var row: PackedStringArray = table[key]
		assert_eq(row.size(), header.size(), "%s column count" % key)
		for i: int in range(1, row.size()):
			assert_false(row[i].strip_edges().is_empty(), "%s missing %s" % [key, header[i]])


func test_all_used_keys_exist() -> void:
	var table := _load_table()
	var key_re := RegEx.create_from_string("\"((?:UI|HUD|PROMPT|TOAST)_[A-Z0-9_]+)\"")
	var missing := PackedStringArray()
	for path: String in _files("res://src", [".gd", ".tscn"]) + _files("res://maps", [".tscn"]):
		var src := FileAccess.get_file_as_string(path)
		for m: RegExMatch in key_re.search_all(src):
			if not table.has(m.get_string(1)):
				missing.append("%s (%s)" % [m.get_string(1), path])
	assert_eq(missing, PackedStringArray(), "keys missing from ui.csv")


func test_translation_is_active() -> void:
	TranslationServer.set_locale("en")
	assert_eq(tr("UI_NEW_GAME"), "New game")
	TranslationServer.set_locale("vi")
	assert_eq(tr("UI_NEW_GAME"), "Chơi mới")


static func _files(dir_path: String, exts: Array) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for f: String in dir.get_files():
		for ext: String in exts:
			if f.ends_with(ext):
				out.append(dir_path.path_join(f))
	for sub: String in dir.get_directories():
		out.append_array(_files(dir_path.path_join(sub), exts))
	return out
