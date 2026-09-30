extends GutTest


func test_stat_block_base_and_modifiers() -> void:
	var s := StatBlock.new({&"atk": 10.0})
	assert_eq(s.get_stat(&"atk"), 10.0)
	s.add_modifier(&"sword", &"atk", 5.0)
	assert_eq(s.get_stat(&"atk"), 15.0)
	s.add_modifier(&"buff", &"atk", 0.0, 0.5)
	assert_eq(s.get_stat(&"atk"), 22.5, "(10 + 5) * 1.5")
	s.remove_modifier(&"sword")
	assert_eq(s.get_stat(&"atk"), 15.0)


func test_stat_block_never_negative() -> void:
	var s := StatBlock.new({&"def": 2.0})
	s.add_modifier(&"curse", &"def", -10.0)
	assert_eq(s.get_stat(&"def"), 0.0)


func test_stat_block_emits_changed() -> void:
	var s := StatBlock.new()
	watch_signals(s)
	s.set_base(&"spd", 100.0)
	assert_signal_emitted(s, "changed")


func test_resource_pool_spend_is_all_or_nothing() -> void:
	var p := ResourcePool.new(100.0)
	assert_true(p.spend(30.0))
	assert_eq(p.current, 70.0)
	assert_false(p.spend(80.0))
	assert_eq(p.current, 70.0)


func test_resource_pool_drain_and_restore_clamp() -> void:
	var p := ResourcePool.new(50.0)
	assert_eq(p.drain(80.0), 50.0)
	assert_true(p.is_empty())
	assert_eq(p.restore(100.0), 50.0)
	assert_true(p.is_full())


func test_resource_pool_signals() -> void:
	var p := ResourcePool.new(10.0)
	watch_signals(p)
	p.drain(10.0)
	assert_signal_emitted(p, "depleted")
	p.fill()
	assert_signal_emitted(p, "filled")


func test_resource_pool_set_maximum_keep_ratio() -> void:
	var p := ResourcePool.new(100.0)
	p.set_current(50.0)
	p.set_maximum(200.0, true)
	assert_eq(p.current, 100.0)
	p.set_maximum(50.0, false)
	assert_eq(p.current, 50.0, "clamped to new max")


func test_progression_levels_up_and_carries_xp() -> void:
	var prog := Progression.new(30, 20.0, 1.5)
	assert_eq(prog.xp_to_next(), 20)
	var gained := prog.add_xp(25)
	assert_eq(gained, 1)
	assert_eq(prog.level, 2)
	assert_eq(prog.xp, 5)


func test_progression_respects_max_level() -> void:
	var prog := Progression.new(3, 1.0, 1.0)
	prog.add_xp(1000)
	assert_eq(prog.level, 3)
	assert_eq(prog.xp_to_next(), 0)
	assert_eq(prog.add_xp(10), 0)


func test_progression_roundtrip() -> void:
	var prog := Progression.new()
	prog.add_xp(50)
	var copy := Progression.new()
	copy.load_dict(prog.to_dict())
	assert_eq(copy.level, prog.level)
	assert_eq(copy.xp, prog.xp)
