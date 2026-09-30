extends GutTest

const TEST_PATH := "user://test_saves/slot_test.json"


func after_each() -> void:
	GameState.new_game()
	for f: String in [TEST_PATH, TEST_PATH + ".tmp", TEST_PATH + ".bak"]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)


func test_migrates_v0_to_current() -> void:
	var migrated := SaveMigrator.migrate({"save_version": 0, "map_path": "x"})
	assert_eq(int(migrated["save_version"]), SaveMigrator.CURRENT_VERSION)
	assert_true(migrated.has("flags"))


func test_rejects_future_version() -> void:
	var migrated := SaveMigrator.migrate({"save_version": 999})
	assert_eq(migrated, {})
	assert_push_error("newer than supported")


func test_codec_rejects_garbage() -> void:
	assert_eq(SaveCodec.decode("not json"), {})
	assert_eq(SaveCodec.decode("{\"no_version\": 1}"), {})


func test_game_state_roundtrip_through_codec() -> void:
	GameState.new_game()
	GameState.inventory.add(&"coin", 42)
	GameState.set_flag(&"opened:test")
	GameState.progression(&"vu").add_xp(100)
	GameState.saved_position = Vector2(100, 200)
	GameState.map_path = "res://maps/test_house.tscn"
	var text := SaveCodec.encode(GameState.to_dict())
	var level := GameState.progression(&"vu").level

	GameState.new_game()
	GameState.load_dict(SaveCodec.decode(text))
	assert_eq(GameState.inventory.count(&"coin"), 42)
	assert_true(GameState.has_flag(&"opened:test"))
	assert_eq(GameState.progression(&"vu").level, level)
	assert_eq(GameState.pending_position, Vector2(100, 200))
	assert_eq(GameState.map_path, "res://maps/test_house.tscn")


func test_saved_position_does_not_leak_into_pending() -> void:
	GameState.new_game()
	GameState.saved_position = Vector2(5, 5)
	GameState.to_dict()
	assert_null(GameState.pending_position, "saving must not teleport the next map load")


func test_atomic_write_replaces_file() -> void:
	assert_true(SaveService.write_atomic(TEST_PATH, "first"))
	assert_true(SaveService.write_atomic(TEST_PATH, "second"))
	assert_eq(FileAccess.get_file_as_string(TEST_PATH), "second")
	assert_false(FileAccess.file_exists(TEST_PATH + ".tmp"))
	assert_false(FileAccess.file_exists(TEST_PATH + ".bak"))
