class_name Enemy
extends Actor
## Generic enemy driven by an EnemyDef. FSM (GDD 6.5):
##   Idle -> Chase -> Telegraph -> Attack -> Recover (+ Stagger, Dead)

const DEFAULT_SCENE_PATH := "res://src/gameplay/entities/enemies/enemy.tscn"

const STATE_IDLE: StringName = &"Idle"
const STATE_CHASE: StringName = &"Chase"
const STATE_TELEGRAPH: StringName = &"Telegraph"
const STATE_ATTACK: StringName = &"Attack"
const STATE_RECOVER: StringName = &"Recover"
const STATE_STAGGER: StringName = &"Stagger"
const STATE_DEAD: StringName = &"Dead"

@export var def: EnemyDef

@onready var loot: LootDropper = $LootDropper
@onready var body_shape: CollisionShape2D = $BodyShape

var home: Vector2
var target: PartyMember = null


## Factory: instantiates the right scene for `p_def`. Add it to a container afterwards.
static func create(p_def: EnemyDef) -> Enemy:
	var scene: PackedScene = p_def.scene if p_def.scene != null else load(DEFAULT_SCENE_PATH)
	var enemy := scene.instantiate() as Enemy
	enemy.def = p_def
	return enemy


func _ready() -> void:
	faction = Faction.Id.ENEMY
	add_to_group(&"enemies")
	super()
	home = global_position


func _setup_actor() -> void:
	assert(def != null, "Enemy needs an EnemyDef")
	stats.setup(def.base_stats())
	health.setup(def.max_hp)
	poise.set_maximum(def.poise)
	poise.fill()
	knockback_resist = def.knockback_resist
	visual.setup(def.sprite_sheet)
	visual.shadow_radius = def.body_radius
	_size_shapes(def.body_radius)
	loot.table = def.loot


## Shapes come from the shared scene; give each enemy its own sized copies.
func _size_shapes(radius: float) -> void:
	var body := CircleShape2D.new()
	body.radius = radius * 0.75
	body_shape.shape = body
	var hurt_shape := hurtbox.get_child(0) as CollisionShape2D
	var rect := RectangleShape2D.new()
	rect.size = Vector2(radius * 2.0, radius * 2.2)
	hurt_shape.shape = rect
	hurt_shape.position = Vector2(0, -radius * 1.0)


func _physics_process(delta: float) -> void:
	super(delta)
	if def.regen_delay > 0.0 and _since_hit > def.regen_delay and not health.pool.is_full() and is_alive():
		health.heal(health.pool.maximum)


func is_targetable() -> bool:
	return is_alive() and is_inside_tree() and not state_machine.is_in(STATE_DEAD)


# --- AI queries used by states ---

func find_target() -> PartyMember:
	var best: PartyMember = null
	var best_d := def.aggro_range
	for node: Node in get_tree().get_nodes_in_group(&"party"):
		var m := node as PartyMember
		if m == null or m.is_downed():
			continue
		var d := m.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = m
	return best


func has_valid_target() -> bool:
	return is_instance_valid(target) and target.is_inside_tree() and not target.is_downed()


func distance_to_target() -> float:
	return global_position.distance_to(target.global_position) if has_valid_target() else INF


func direction_to_target() -> Vector2:
	return global_position.direction_to(target.global_position) if has_valid_target() else facing


## First ability that is off cooldown and in range of the target.
func pick_ability() -> AbilityDef:
	var dist := distance_to_target()
	for a: AbilityDef in def.abilities:
		if dist <= a.ai_range and abilities.is_ready(a):
			return a
	return null


func too_far_from_home() -> bool:
	return global_position.distance_to(home) > def.leash_range


# --- Reactions ---

func _on_hit_received(info: DamageInfo) -> void:
	super(info)
	# Getting hit wakes the enemy up even outside its aggro range.
	if not has_valid_target() and info.source is PartyMember:
		target = info.source
		if state_machine.is_in(STATE_IDLE):
			state_machine.transition_to(STATE_CHASE)


func _on_poise_broken(_info: DamageInfo) -> void:
	if is_alive():
		state_machine.transition_to(STATE_STAGGER)


func _on_died(_info: DamageInfo) -> void:
	state_machine.transition_to(STATE_DEAD)
	EventBus.enemy_killed.emit(def.id, def.xp_reward, global_position)
	loot.drop(global_position, get_parent())


func _body_mask() -> int:
	return Faction.bit(Faction.LAYER_WORLD) | Faction.bit(Faction.LAYER_PARTY) | Faction.bit(Faction.LAYER_ENEMY)
