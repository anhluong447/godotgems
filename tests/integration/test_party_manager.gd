extends GutTest

const PARTY_SCRIPT := preload("res://src/gameplay/entities/party/party_manager.gd")
const INTERACTOR_SCRIPT := preload("res://src/gameplay/entities/party/interactor.gd")

var party: PartyManager
var container: Node2D


func before_each() -> void:
	GameState.new_game()
	party = PARTY_SCRIPT.new()
	var interactor := Area2D.new()
	interactor.name = "Interactor"
	interactor.set_script(INTERACTOR_SCRIPT)
	party.add_child(interactor)
	add_child_autofree(party)
	container = Node2D.new()
	add_child_autofree(container)
	party.build_from_state()
	party.place_in(container, Vector2(100, 100))


func after_each() -> void:
	for cmd: String in ["heal", "xp", "hurt", "tp"]:
		DebugService.unregister(cmd)


func test_builds_default_party_with_leader() -> void:
	assert_eq(party.members.size(), GameState.DEFAULT_PARTY.size())
	assert_eq(party.leader, party.members[0])
	assert_true(party.leader.controller is PlayerController)
	assert_true(party.members[1].controller is AIController)


func test_switch_respects_cooldown() -> void:
	assert_true(party.switch_to(1))
	assert_eq(party.leader, party.members[1])
	assert_true(party.members[0].controller is AIController)
	assert_false(party.switch_to(0), "switch cooldown")
	assert_true(party.switch_to(0, true))


func test_cannot_switch_to_downed_member() -> void:
	party.members[1].health.kill()
	assert_false(party.switch_to(1, true))


func test_leader_downed_hands_over_control() -> void:
	party.members[0].health.kill()
	assert_eq(party.leader, party.members[1])


func test_all_downed_emits_wipe() -> void:
	watch_signals(EventBus)
	for m: PartyMember in party.members:
		m.health.kill()
	assert_signal_emitted(EventBus, "party_wiped")


func test_xp_is_shared_and_levels_up() -> void:
	var before := party.members[1].health.pool.maximum
	party.grant_xp(1000)
	for m: PartyMember in party.members:
		assert_gt(m.progression.level, 1)
	assert_gt(party.members[1].health.pool.maximum, before, "stats grow with level")


func test_members_survive_map_change() -> void:
	var other := Node2D.new()
	add_child_autofree(other)
	var first := party.members[0]
	party.detach()
	party.place_in(other, Vector2.ZERO)
	assert_eq(first.get_parent(), other)
	assert_true(is_instance_valid(first))


func test_action_pressed_during_hitstop_is_buffered() -> void:
	HitstopService.request(0.3)
	var ev := InputEventAction.new()
	ev.action = &"attack"
	ev.pressed = true
	party._unhandled_input(ev)
	assert_true(party.leader.intent.actions.peek(ActorIntent.ATTACK), "tap during freeze must not be lost")
	HitstopService.clear()


func test_before_save_captures_vitals_and_position() -> void:
	party.members[0].health.pool.set_current(33.0)
	EventBus.before_save.emit()
	assert_eq(float(GameState.vitals[party.members[0].def.id]["hp"]), 33.0)
	assert_eq(GameState.saved_position, party.leader.global_position)
