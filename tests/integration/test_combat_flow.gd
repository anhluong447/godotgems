extends GutTest
## Real scenes, manual time stepping: hitbox -> hurtbox -> health -> reactions.

const MEMBER_SCENE := preload("res://src/gameplay/entities/party/party_member.tscn")

var world: Node2D


func before_each() -> void:
	world = Node2D.new()
	add_child_autofree(world)
	DebugService.god_mode = false


func _member(id: StringName = &"vu") -> PartyMember:
	var m := MEMBER_SCENE.instantiate() as PartyMember
	m.def = Registry.character(id)
	world.add_child(m)
	m.set_physics_process(false)
	return m


func _enemy(id: StringName, at: Vector2) -> Enemy:
	var e := Enemy.create(Registry.enemy(id))
	e.position = at
	world.add_child(e)
	e.set_physics_process(false)
	return e


func _step(actor: Actor, seconds: float, dt: float = 1.0 / 60.0) -> void:
	var t := 0.0
	while t < seconds:
		actor.abilities.physics_step(dt)
		t += dt


func test_hurtbox_applies_damage_with_defense() -> void:
	var wolf := _enemy(&"wolf", Vector2.ZERO)
	var info := DamageInfo.new()
	info.attacker_atk = 21.0
	info.source_faction = Faction.Id.PARTY
	Registry.combat_config.variance = 0.0
	var crit := Registry.combat_config.crit_chance
	Registry.combat_config.crit_chance = 0.0
	assert_true(wolf.hurtbox.receive_hit(info))
	# 21 * 20 / (20 + 1) = 20
	assert_eq(wolf.health.current(), 36.0 - 20.0)
	Registry.combat_config.variance = 0.1
	Registry.combat_config.crit_chance = crit


func test_friendly_fire_is_ignored() -> void:
	var m := _member()
	var info := DamageInfo.new()
	info.attacker_atk = 50.0
	info.source_faction = Faction.Id.PARTY
	assert_false(m.hurtbox.receive_hit(info))
	assert_eq(m.health.current(), m.health.pool.maximum)


func test_killing_enemy_emits_event_and_enters_dead() -> void:
	var wolf := _enemy(&"wolf", Vector2.ZERO)
	watch_signals(EventBus)
	wolf.health.kill()
	assert_signal_emitted(EventBus, "enemy_killed")
	assert_true(wolf.state_machine.is_in(Enemy.STATE_DEAD))
	assert_false(wolf.is_in_group(&"enemies"))


func test_poise_break_staggers_enemy() -> void:
	var boar := _enemy(&"boar", Vector2.ZERO)
	var info := DamageInfo.new()
	info.attacker_atk = 1.0
	info.poise_damage = 999.0
	info.source_faction = Faction.Id.PARTY
	boar.hurtbox.receive_hit(info)
	assert_true(boar.state_machine.is_in(Enemy.STATE_STAGGER))


func test_ability_timeline_phases_and_cooldown() -> void:
	var m := _member()
	var skill: AbilityDef = m.def.skill_1
	m.energy.fill()
	assert_true(m.abilities.try_use(skill, Vector2.RIGHT, Vector2.ZERO))
	assert_eq(m.abilities.phase, AbilityComponent.Phase.WINDUP)
	assert_eq(m.energy.current, m.energy.maximum - skill.energy_cost, "energy spent")
	_step(m, skill.windup + 0.01)
	assert_eq(m.abilities.phase, AbilityComponent.Phase.ACTIVE)
	assert_true(m.hitbox.active)
	_step(m, skill.active_time + skill.recovery + 0.05)
	assert_false(m.abilities.is_busy())
	assert_false(m.hitbox.active)
	assert_false(m.abilities.is_ready(skill), "on cooldown")
	_step(m, skill.cooldown + 0.05)
	assert_true(m.abilities.is_ready(skill))


func test_ability_needs_energy() -> void:
	var m := _member()
	m.energy.set_current(0.0)
	assert_false(m.abilities.try_use(m.def.skill_2, Vector2.RIGHT, Vector2.ZERO))


func test_combo_cancel_window() -> void:
	var m := _member()
	var first: AbilityDef = m.def.combo[0]
	var second: AbilityDef = m.def.combo[1]
	assert_true(m.abilities.try_use(first, Vector2.RIGHT, Vector2.ZERO))
	assert_false(m.abilities.try_use(second, Vector2.RIGHT, Vector2.ZERO), "too early to cancel")
	_step(m, first.cancel_from + 0.01)
	assert_true(m.abilities.try_use(second, Vector2.RIGHT, Vector2.ZERO), "cancel window open")
	assert_eq(m.abilities.current, second)


func test_interrupt_cleans_up_hitbox_and_forced_motion() -> void:
	var m := _member()
	var dash: AbilityDef = m.def.skill_1
	m.abilities.try_use(dash, Vector2.RIGHT, Vector2.ZERO)
	_step(m, dash.windup + 0.01)
	assert_true(m.movement.has_forced())
	m.abilities.interrupt()
	assert_false(m.hitbox.active)
	assert_false(m.movement.has_forced())
	assert_false(m.health.is_invulnerable(), "iframes released")


func test_party_member_downed_and_revive() -> void:
	var m := _member()
	m.health.kill()
	assert_true(m.is_downed())
	assert_true(m.health.is_invulnerable())
	m.revive(0.3)
	assert_false(m.is_downed())
	assert_almost_eq(m.health.current(), m.health.pool.maximum * 0.3, 0.5)


func test_enemy_acquires_target_and_telegraphs() -> void:
	var m := _member()
	m.position = Vector2(40, 0)
	var wolf := _enemy(&"wolf", Vector2.ZERO)
	# Drive the FSM manually.
	for i: int in 30:
		wolf.state_machine.physics_update(1.0 / 60.0)
		wolf.abilities.physics_step(1.0 / 60.0)
	assert_eq(wolf.target, m)
	assert_true(wolf.state_machine.current_id() in [Enemy.STATE_TELEGRAPH, Enemy.STATE_ATTACK], "got %s" % wolf.state_machine.current_id())
