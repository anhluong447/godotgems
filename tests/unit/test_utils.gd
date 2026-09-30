extends GutTest


func test_cooldown_ticks_to_ready() -> void:
	var cd := Cooldown.new(1.0)
	assert_true(cd.is_ready())
	cd.start()
	assert_false(cd.is_ready())
	assert_almost_eq(cd.ratio(), 1.0, 0.001)
	cd.tick(0.5)
	assert_almost_eq(cd.ratio(), 0.5, 0.001)
	cd.tick(0.6)
	assert_true(cd.is_ready())


func test_action_buffer_expires() -> void:
	var b := ActionBuffer.new(0.2)
	b.press(&"attack")
	assert_true(b.peek(&"attack"))
	b.tick(0.25)
	assert_false(b.peek(&"attack"))


func test_action_buffer_consume_once() -> void:
	var b := ActionBuffer.new(0.2)
	b.press(&"dodge")
	assert_true(b.consume(&"dodge"))
	assert_false(b.consume(&"dodge"))


func test_command_line_tokenize() -> void:
	assert_eq(CommandLine.tokenize("spawn wolf 3"), PackedStringArray(["spawn", "wolf", "3"]))
	assert_eq(CommandLine.tokenize("  say \"hello world\"  x "), PackedStringArray(["say", "hello world", "x"]))
	assert_eq(CommandLine.tokenize(""), PackedStringArray())


func test_inventory_add_remove_and_stack_limit() -> void:
	var inv := Inventory.new()
	assert_eq(inv.add(&"coin", 5), 5)
	assert_eq(inv.add(&"herb", 30, 20), 20, "clamped to max_stack")
	assert_true(inv.remove(&"coin", 2))
	assert_eq(inv.count(&"coin"), 3)
	assert_false(inv.remove(&"coin", 10), "not enough")
	assert_eq(inv.count(&"coin"), 3)
	assert_true(inv.remove(&"coin", 3))
	assert_false(inv.has(&"coin"))


func test_inventory_roundtrip_and_sorted_ids() -> void:
	var inv := Inventory.new()
	inv.add(&"zeta", 1)
	inv.add(&"alpha", 2)
	var copy := Inventory.new()
	copy.load_dict(inv.to_dict())
	assert_eq(copy.count(&"alpha"), 2)
	assert_eq(copy.item_ids(), [&"alpha", &"zeta"] as Array[StringName])


func test_inventory_bulk_changes_emit_reset() -> void:
	var inv := Inventory.new()
	watch_signals(inv)
	inv.load_dict({"coin": 3})
	assert_signal_emitted(inv, "reset", "UI must refresh after loading a save")
	inv.clear()
	assert_signal_emit_count(inv, "reset", 2)


func test_loot_table_rolls() -> void:
	var item := ItemDef.new()
	item.id = &"coin"
	var always := LootEntry.new()
	always.item = item
	always.chance = 1.0
	always.min_count = 2
	always.max_count = 2
	var never := LootEntry.new()
	never.item = item
	never.chance = 0.0
	var table := LootTable.new()
	table.entries = [always, never]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var drops := table.roll(rng)
	assert_eq(drops.size(), 1)
	assert_eq(drops[0]["count"], 2)
