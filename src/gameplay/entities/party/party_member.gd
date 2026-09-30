class_name PartyMember
extends Actor
## A playable character. It reads an ActorIntent every frame and does not know
## whether a player or the AI filled it: switching characters = swapping controllers.

signal downed
signal revived
signal leveled_up(level: int)

const STATE_LOCOMOTION: StringName = &"Locomotion"
const STATE_ABILITY: StringName = &"Ability"
const STATE_DODGE: StringName = &"Dodge"
const STATE_FLINCH: StringName = &"Flinch"
const STATE_DOWNED: StringName = &"Downed"

@export var def: CharacterDef

var intent: ActorIntent = ActorIntent.new()
var controller: MemberController = null
var progression: Progression = Progression.new()
var is_leader: bool = false
var dodge_cooldown: Cooldown = Cooldown.new()

var combo_index: int = 0
var _combo_timer: float = 0.0


func _ready() -> void:
	faction = Faction.Id.PARTY
	add_to_group(&"party")
	super()


func _setup_actor() -> void:
	assert(def != null, "PartyMember needs a CharacterDef")
	name = String(def.id).to_pascal_case()
	health.respects_god_mode = true
	health.hit_iframes = Registry.combat_config.party_hit_iframes
	visual.setup(def.sprite_sheet, Color.WHITE)
	dodge_cooldown = Cooldown.new(def.dodge_cooldown)
	poise.set_maximum(def.poise)
	poise.fill()
	_apply_stats(true)


## Recomputes stats for the current level. refill = full HP/energy (spawn), else keep ratios.
func _apply_stats(refill: bool) -> void:
	var base := def.base_stats()
	for stat: StringName in def.growth:
		base[stat] = float(base.get(stat, 0.0)) + def.growth[stat] * (progression.level - 1)
	stats.setup(base)
	health.setup(stats.get_stat(StatBlock.MAX_HP), refill)
	energy.set_maximum(stats.get_stat(StatBlock.MAX_ENERGY), not refill)
	if refill:
		energy.fill()


func on_level_changed() -> void:
	_apply_stats(false)
	health.heal(health.pool.maximum * 0.25)
	leveled_up.emit(progression.level)


func set_controller(c: MemberController) -> void:
	controller = c
	intent.clear()


func _think(delta: float) -> void:
	intent.tick(delta)
	dodge_cooldown.tick(delta)
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			combo_index = 0
	if controller != null and not is_downed():
		controller.update(self, delta)
	else:
		intent.move = Vector2.ZERO


# --- Queries used by states and controllers ---

func is_downed() -> bool:
	return state_machine.is_in(STATE_DOWNED)


func aim_direction() -> Vector2:
	return intent.aim.normalized() if intent.aim != Vector2.ZERO else facing


func aim_target_position() -> Vector2:
	return global_position + aim_direction() * 96.0


func current_combo_ability() -> AbilityDef:
	if def.combo.is_empty():
		return null
	return def.combo[combo_index % def.combo.size()]


func advance_combo() -> void:
	combo_index = (combo_index + 1) % maxi(def.combo.size(), 1)
	_combo_timer = def.combo_reset_time


func skill(index: int) -> AbilityDef:
	return def.skill_1 if index == 1 else def.skill_2


## Tries the first queued action. Returns true if a state transition happened.
## Shared by Locomotion and Ability (for cancels) so priorities are defined once.
func try_start_queued_action() -> bool:
	var actions := intent.actions
	if actions.peek(ActorIntent.DODGE) and dodge_cooldown.is_ready():
		actions.consume(ActorIntent.DODGE)
		abilities.interrupt()
		state_machine.transition_to(STATE_DODGE)
		return true
	for i: int in [1, 2]:
		var action := ActorIntent.SKILL_1 if i == 1 else ActorIntent.SKILL_2
		if actions.peek(action):
			var s := skill(i)
			if abilities.is_ready(s) and abilities.try_use(s, aim_direction(), aim_target_position()):
				actions.consume(action)
				combo_index = 0
				state_machine.transition_to(STATE_ABILITY, {"combo": false})
				return true
			actions.consume(action)
	if actions.peek(ActorIntent.ATTACK):
		var a := current_combo_ability()
		if a != null and abilities.try_use(a, aim_direction(), aim_target_position()):
			actions.consume(ActorIntent.ATTACK)
			advance_combo()
			set_facing(aim_direction())
			state_machine.transition_to(STATE_ABILITY, {"combo": true})
			return true
	return false


# --- Reactions ---

func _on_poise_broken(_info: DamageInfo) -> void:
	if not is_downed():
		state_machine.transition_to(STATE_FLINCH)


func _on_died(_info: DamageInfo) -> void:
	state_machine.transition_to(STATE_DOWNED)
	downed.emit()
	EventBus.party_member_downed.emit(self)


func revive(hp_ratio: float) -> void:
	health.revive(hp_ratio)
	if is_downed():
		state_machine.transition_to(STATE_LOCOMOTION)
	revived.emit()
	EventBus.party_member_revived.emit(self)


func _body_mask() -> int:
	# Party members pass through each other but are blocked by enemies and walls.
	return Faction.bit(Faction.LAYER_WORLD) | Faction.bit(Faction.LAYER_ENEMY)
