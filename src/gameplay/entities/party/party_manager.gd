class_name PartyManager
extends Node
## Owns the party roster: building members from GameState, leader switching,
## downed/wipe rules, XP sharing. Members persist across maps (they are
## reparented into each map's Entities node).

signal leader_changed(leader: PartyMember)

const MEMBER_SCENE := preload("res://src/gameplay/entities/party/party_member.tscn")

@onready var interactor: Interactor = $Interactor

var members: Array[PartyMember] = []
var leader: PartyMember = null

var _player_controller: PlayerController = PlayerController.new()
var _switch_cooldown: Cooldown = Cooldown.new(1.0)


func _ready() -> void:
	_switch_cooldown = Cooldown.new(Registry.combat_config.switch_cooldown)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.before_save.connect(_on_before_save)
	EventBus.after_load.connect(build_from_state)
	Registry.resource_tuned.connect(_on_resource_tuned)
	EventBus.item_use_requested.connect(use_item)
	_register_debug_commands()


func _exit_tree() -> void:
	# Members outside the tree (between maps) are not freed with it.
	for m: PartyMember in members:
		if is_instance_valid(m) and not m.is_inside_tree():
			m.free()


func _physics_process(delta: float) -> void:
	_switch_cooldown.tick(delta)


## Discrete actions are event-driven, not polled in _physics_process: during hitstop
## physics ticks are sparse and a quick tap could fall between two ticks and be lost.
func _unhandled_input(event: InputEvent) -> void:
	if leader == null or not InputGate.is_open() or event.is_echo():
		return
	for action: StringName in PlayerController.ACTIONS:
		if event.is_action_pressed(action):
			leader.intent.actions.press(action)
			get_viewport().set_input_as_handled()
			return
	for i: int in 4:
		if event.is_action_pressed(StringName("switch_%d" % (i + 1))):
			switch_to(i)
			return
	if event.is_action_pressed(&"switch_next"):
		switch_next()
	elif event.is_action_pressed(&"use_item"):
		use_item(&"")


# --- Roster ---

func build_from_state() -> void:
	for m: PartyMember in members:
		m.queue_free()
	members.clear()
	leader = null
	for id: StringName in GameState.party_order:
		var def := Registry.character(id)
		if def == null:
			push_error("PartyManager: unknown character '%s'" % id)
			continue
		var m := MEMBER_SCENE.instantiate() as PartyMember
		m.def = def
		m.progression = GameState.progression(id)
		members.append(m)
		m.downed.connect(_on_member_downed.bind(m))
	var list: Array[Node2D] = []
	list.assign(members)
	EventBus.party_roster_changed.emit(list)


## Moves all members into `container` around `at`. Called by MapHost on every map load.
func place_in(container: Node2D, at: Vector2) -> void:
	for i: int in members.size():
		var m := members[i]
		if m.get_parent() != container:
			if m.get_parent() != null:
				m.get_parent().remove_child(m)
			container.add_child(m)
			_apply_saved_vitals(m)
		m.global_position = at + Vector2(-12.0 * i, 10.0 * i)
		m.movement.stop_immediately()
	if leader == null and not members.is_empty():
		_set_leader(members[0])
	else:
		EventBus.party_leader_changed.emit(leader)


## Detach from the current map before it is freed.
func detach() -> void:
	for m: PartyMember in members:
		if m.get_parent() != null:
			m.get_parent().remove_child(m)


func alive_members() -> Array[PartyMember]:
	return members.filter(func(m: PartyMember) -> bool: return not m.is_downed())


func revive_all(hp_ratio: float = 1.0) -> void:
	for m: PartyMember in members:
		if m.is_downed():
			m.revive(hp_ratio)
		else:
			m.health.heal(m.health.pool.maximum * hp_ratio)
		m.energy.fill()


# --- Leader ---

func switch_to(index: int, ignore_cooldown: bool = false) -> bool:
	if index < 0 or index >= members.size():
		return false
	var m := members[index]
	if m == leader or m.is_downed():
		return false
	if not ignore_cooldown and not _switch_cooldown.is_ready():
		return false
	_set_leader(m)
	_switch_cooldown.start()
	AudioService.play_sfx(&"switch", 0.0)
	return true


func switch_next(ignore_cooldown: bool = false) -> bool:
	if members.is_empty():
		return false
	var start := members.find(leader)
	for step: int in range(1, members.size()):
		if switch_to((start + step) % members.size(), ignore_cooldown):
			return true
	return false


func _set_leader(m: PartyMember) -> void:
	leader = m
	var followers := 0
	for other: PartyMember in members:
		other.is_leader = other == m
		if other == m:
			other.set_controller(_player_controller)
		else:
			var ai := AIController.new()
			ai.leader_provider = func() -> PartyMember: return leader
			var side := 1.0 if followers % 2 == 0 else -1.0
			ai.slot_angle = deg_to_rad(35.0) * side * (1.0 + floorf(followers / 2.0))
			other.set_controller(ai)
			followers += 1
	interactor.follow(m)
	leader_changed.emit(m)
	EventBus.party_leader_changed.emit(m)


func _on_member_downed(m: PartyMember) -> void:
	if alive_members().is_empty():
		EventBus.party_wiped.emit()
	elif m == leader:
		switch_next(true)


# --- Items ---

## Uses a consumable on the leader. Empty id picks the smallest heal that is useful.
## Returns true if an item was consumed.
func use_item(item_id: StringName) -> bool:
	if leader == null or leader.is_downed() or not leader.is_inside_tree():
		return false
	var item := Registry.item(item_id) if item_id != &"" else best_healing_item()
	if item == null:
		EventBus.toast_requested.emit(tr("TOAST_NO_CONSUMABLE"))
		return false
	if item.kind != ItemDef.Kind.CONSUMABLE or not GameState.inventory.has(item.id):
		return false
	if leader.health.pool.is_full():
		EventBus.toast_requested.emit(tr("TOAST_HP_FULL"))
		return false
	GameState.inventory.remove(item.id, 1)
	var healed := roundi(leader.health.heal(item.heal_amount))
	AudioService.play_sfx(&"revive", 0.05)
	Fx.heal(leader.get_parent(), leader.global_position)
	EventBus.item_used.emit(item.id, healed)
	EventBus.toast_requested.emit(tr("TOAST_USED_ITEM") % [item.display_name, healed])
	return true


## Cheapest consumable that still heals (avoid wasting big potions), or null.
func best_healing_item() -> ItemDef:
	var best: ItemDef = null
	for id: StringName in GameState.inventory.item_ids():
		var item := Registry.item(id)
		if item == null or item.kind != ItemDef.Kind.CONSUMABLE or item.heal_amount <= 0:
			continue
		if best == null or item.heal_amount < best.heal_amount:
			best = item
	return best


# --- Progress ---

func grant_xp(amount: int) -> void:
	for m: PartyMember in members:
		var gained := m.progression.add_xp(amount)
		if gained > 0:
			m.on_level_changed()
			EventBus.member_leveled_up.emit(m.def.id, m.progression.level)


func _on_enemy_killed(_id: StringName, xp: int, _at: Vector2) -> void:
	grant_xp(xp)


func _on_resource_tuned(res: Resource) -> void:
	for m: PartyMember in members:
		if m.def == res and m.is_inside_tree():
			m.on_stats_tuned()


func _on_before_save() -> void:
	for m: PartyMember in members:
		GameState.vitals[m.def.id] = {"hp": m.health.current(), "energy": m.energy.current}
	if leader != null and leader.is_inside_tree():
		GameState.saved_position = leader.global_position


func _apply_saved_vitals(m: PartyMember) -> void:
	var v: Dictionary = GameState.vitals.get(m.def.id, {})
	if v.is_empty():
		return
	m.health.pool.set_current(maxf(float(v.get("hp", m.health.pool.maximum)), 1.0))
	m.energy.set_current(float(v.get("energy", m.energy.maximum)))
	GameState.vitals.erase(m.def.id)


# --- Debug ---

func _register_debug_commands() -> void:
	DebugService.register("heal", _cmd_heal, "Revive and fully heal the party")
	DebugService.register("xp", _cmd_xp, "Give XP to every member", "<amount>")
	DebugService.register("hurt", _cmd_hurt, "Damage the leader", "<raw damage>")
	DebugService.register("tp", _cmd_tp, "Teleport the party", "<x> <y>")


func _cmd_tp(args: PackedStringArray) -> String:
	if leader == null or args.size() < 2 or not leader.is_inside_tree():
		return "usage: tp <x> <y>"
	var at := Vector2(args[0].to_float(), args[1].to_float())
	for i: int in members.size():
		members[i].global_position = at + Vector2(-12.0 * i, 10.0 * i)
	return "teleported to %s" % at


func _cmd_heal(_args: PackedStringArray) -> String:
	revive_all(1.0)
	return "party healed"


func _cmd_xp(args: PackedStringArray) -> String:
	var n := args[0].to_int() if not args.is_empty() else 100
	grant_xp(n)
	return "granted %d xp" % n


func _cmd_hurt(args: PackedStringArray) -> String:
	if leader == null:
		return "no leader"
	var info := DamageInfo.new()
	info.attacker_atk = args[0].to_float() if not args.is_empty() else 20.0
	info.source_faction = Faction.Id.ENEMY
	info.direction = Vector2.DOWN
	info.knockback = 120.0
	leader.hurtbox.receive_hit(info)
	return "ouch"
