extends GutTest


func before_each() -> void:
	HitstopService.clear()


func after_each() -> void:
	HitstopService.base_time_scale = 1.0
	HitstopService.clear()
	for r: StringName in InputGate.reasons():
		InputGate.release(r)


func test_hitstop_always_restores_time_scale() -> void:
	HitstopService.request(0.02)
	assert_lt(Engine.time_scale, 1.0)
	await wait_process_frames(3)
	await get_tree().create_timer(0.05, true, false, true).timeout
	await wait_process_frames(2)
	assert_eq(Engine.time_scale, 1.0, "hitstop must never leave the game slowed")


func test_hitstop_overlapping_requests_extend() -> void:
	HitstopService.request(0.5)
	HitstopService.request(0.01)
	await get_tree().create_timer(0.05, true, false, true).timeout
	assert_true(HitstopService.is_active(), "shorter request must not cut a longer freeze")


func test_input_gate_reasons_are_independent() -> void:
	assert_true(InputGate.is_open())
	InputGate.acquire(&"dialogue")
	InputGate.acquire(&"console")
	InputGate.release(&"dialogue")
	assert_false(InputGate.is_open())
	InputGate.release(&"console")
	assert_true(InputGate.is_open())


func test_debug_command_registry() -> void:
	DebugService.register("echo_test", func(args: PackedStringArray) -> String: return " ".join(args), "test")
	assert_eq(DebugService.execute("echo_test a \"b c\""), "a b c")
	assert_string_contains(DebugService.execute("nope"), "Unknown command")
	DebugService.unregister("echo_test")
