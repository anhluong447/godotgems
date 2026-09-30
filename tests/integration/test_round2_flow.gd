extends GutTest
## Attack tokens, item use, live tuning, save slot metadata.

const MEMBER_SCENE := preload("res://src/gameplay/entities/party/party_member.tscn")
const PARTY_SCRIPT := preload("res://src/gameplay/entities/party/party_manager.gd")
const INTERACTOR_SCRIPT := preload("res://src/gameplay/entities/party/interactor.gd")
const TEST_SAVE_DIR := "user://test_saves_round2"

var world: Node2D


func before_each() -> void:
	GameState.new_game()
	world = Node2D.new()
	add_child_autofree(world)


func after_each() -> void:
	for cmd: String in ["heal", "xp", "hurt", "tp"]:
		DebugService.unregister(cmd)


func test_attack_director_limits_simultaneous_attackers() -> void:
	var director := AttackDirector.new()
	world.add_child(director)
	var m := MEMBER_SCENE.instantiate() as PartyMember
	m.def = Registry.character(&"vu")
	world.add_child(m)
	m.set_physics_process(false)
	var wolves: Array[Enemy] = []
	for i: int in 5:
		var e := Enemy.create(Registry.enemy(&"wolf"))
		e.position = Vector2(30, 0).rotated(TAU * i / 5.0)
		world.add_child(e)
		e.set_physics_process(false)
		wolves.append(e)
	var max_attacking := 0
	for frame: int in 90:
		var attacking := 0
		for e: Enemy in wolves:
			e.state_machine.physics_update(1.0 / 60.0)
			e.abilities.physics_step(1.0 / 60.0)
			if e.state_machine.current_id() in [Enemy.STATE_TELEGRAPH, Enemy.STATE_ATTACK]:
				attacking += 1
		max_attacking = maxi(max_attacking, attacking)
	assert_gt(max_attacking, 0, "someone attacked")
	assert_true(max_attacking <= Registry.combat_config.max_simultaneous_attackers,
		"at most %d attackers, saw %d" % [Registry.combat_config.max_simultaneous_attackers, max_attacking])


func test_token_released_when_enemy_staggers() -> void:
	var director := AttackDirector.new()
	world.add_child(director)
	var e := Enemy.create(Registry.enemy(&"boar"))
	world.add_child(e)
	e.set_physics_process(false)
	assert_true(e.request_attack_token())
	e.state_machine.transition_to(Enemy.STATE_TELEGRAPH, {"ability": null})
	e.state_machine.transition_to(Enemy.STATE_STAGGER)
	assert_eq(director.tokens.in_use(), 0)


func _party() -> PartyManager:
	var party: PartyManager = PARTY_SCRIPT.new()
	var interactor := Area2D.new()
	interactor.name = "Interactor"
	interactor.set_script(INTERACTOR_SCRIPT)
	party.add_child(interactor)
	add_child_autofree(party)
	party.build_from_state()
	party.place_in(world, Vector2.ZERO)
	return party


func test_item_use_request_heals_and_consumes() -> void:
	var party := _party()
	GameState.inventory.add(&"herb", 2)
	party.leader.health.pool.set_current(10.0)
	EventBus.item_use_requested.emit(&"herb")
	assert_eq(GameState.inventory.count(&"herb"), 1)
	assert_eq(party.leader.health.current(), 40.0, "herb heals 30")


func test_item_use_does_not_waste_on_full_hp() -> void:
	var party := _party()
	GameState.inventory.add(&"herb", 1)
	assert_false(party.use_item(&""))
	assert_eq(GameState.inventory.count(&"herb"), 1)


func test_quick_use_picks_healing_item() -> void:
	var party := _party()
	GameState.inventory.add(&"coin", 5)
	GameState.inventory.add(&"herb", 1)
	assert_eq(party.best_healing_item().id, &"herb")
	GameState.inventory.remove(&"herb", 1)
	assert_null(party.best_healing_item(), "coins do not heal")


func test_tune_command_changes_live_data() -> void:
	var bite := Registry.ability(&"wolf_bite")
	var old := bite.windup
	var out := DebugService.execute("tune wolf_bite windup 0.9")
	assert_string_contains(out, "->")
	assert_eq(bite.windup, 0.9)
	DebugService.execute("tune wolf_bite windup %s" % old)
	assert_eq(bite.windup, old)
	assert_string_contains(DebugService.execute("tune wolf_bite nope 1"), "no property")


class FakeHost:
	extends Node
	var loads: Array[String] = []

	func load_map(path: String, _spawn: StringName) -> void:
		loads.append(path)


func test_map_requests_during_transition_are_queued() -> void:
	var host := FakeHost.new()
	add_child_autofree(host)
	SceneRouter.register_host(host)
	SceneRouter.change_map("a", &"", 0.0)
	SceneRouter.change_map("b", &"", 0.0)
	SceneRouter.change_map("c", &"", 0.0)
	for i: int in 10:
		await wait_process_frames(1)
	assert_eq(host.loads, ["a", "c"] as Array[String], "latest request runs after the current one")
	SceneRouter._host = null


func test_slot_meta_and_latest_slot() -> void:
	var real_dir := SaveService.dir
	SaveService.dir = TEST_SAVE_DIR
	for s: int in SaveService.all_slots():
		SaveService.delete_slot(s)
	assert_eq(SaveService.latest_slot(), -1)
	GameState.map_display_name = "Test Map"
	assert_true(SaveService.save_game(2))
	var meta := SaveService.slot_meta(2)
	assert_eq(meta.get("map_name"), "Test Map")
	assert_eq(SaveService.slot_meta(3), {})
	assert_eq(SaveService.latest_slot(), 2)
	assert_true(SaveService.read_into_state(2))
	SaveService.delete_slot(2)
	SaveService.dir = real_dir
