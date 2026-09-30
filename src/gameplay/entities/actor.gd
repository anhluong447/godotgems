class_name Actor
extends CharacterBody2D
## Shared base for anything that fights (party members, enemies).
## It only wires components together; behavior lives in states, controllers and abilities.
##
## Frame order (explicit, so results are deterministic):
##   _think -> state machine -> abilities -> movement -> regen -> visuals

signal hurt(info: DamageInfo)
signal poise_broken(info: DamageInfo)

@export var faction: Faction.Id = Faction.Id.ENEMY

@onready var stats: StatsComponent = $Stats
@onready var health: HealthComponent = $Health
@onready var movement: MovementComponent = $Movement
@onready var abilities: AbilityComponent = $Abilities
@onready var hurtbox: HurtboxComponent = $Hurtbox
@onready var hitbox: HitboxComponent = $Hitbox
@onready var visual: ActorVisual = $Visual
@onready var flash: FlashComponent = $Flash
@onready var state_machine: StateMachine = $StateMachine

var facing: Vector2 = Vector2.DOWN
var energy: ResourcePool = ResourcePool.new(0.0)
var poise: ResourcePool = ResourcePool.new(20.0)
var knockback_resist: float = 0.0

var _since_hit: float = 99.0


func _ready() -> void:
	collision_layer = Faction.body_layer(faction)
	collision_mask = _body_mask()
	hurtbox.faction = faction
	hitbox.faction = faction
	hitbox.knockback_origin = self
	hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_died)
	stats.changed.connect(_on_stats_changed)
	abilities.setup(self)
	_setup_actor()
	state_machine.setup(self)


## Subclasses: configure stats, visuals and health from their definition.
func _setup_actor() -> void:
	pass


## Subclasses: fill intent / decide what to do (controller, AI).
func _think(_delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	_think(delta)
	state_machine.physics_update(delta)
	abilities.physics_step(delta)
	movement.physics_step(delta)
	_regen(delta)
	visual.update_anim(velocity, delta)


func get_atk() -> float:
	return stats.get_stat(StatBlock.ATK)


func is_alive() -> bool:
	return not health.is_dead()


func set_facing(dir: Vector2) -> void:
	if dir.length_squared() < 0.0001:
		return
	facing = dir.normalized()
	visual.set_facing(facing)


func _body_mask() -> int:
	return Faction.bit(Faction.LAYER_WORLD)


func _on_stats_changed() -> void:
	movement.max_speed = stats.get_stat(StatBlock.SPD)


func _on_hit_received(info: DamageInfo) -> void:
	_since_hit = 0.0
	movement.impulse(info.direction * info.knockback * (1.0 - knockback_resist))
	flash.flash()
	visual.pop(Vector2(0.8, 1.2), 0.15)
	hurt.emit(info)
	if health.is_dead() or poise.maximum <= 0.0:
		return
	poise.drain(info.poise_damage)
	if poise.is_empty():
		poise.fill()
		poise_broken.emit(info)
		_on_poise_broken(info)


func _on_poise_broken(_info: DamageInfo) -> void:
	pass


func _on_died(_info: DamageInfo) -> void:
	pass


func _regen(delta: float) -> void:
	_since_hit += delta
	var regen := stats.get_stat(StatBlock.ENERGY_REGEN)
	if regen > 0.0 and not abilities.is_busy():
		energy.restore(regen * delta)
	if _since_hit > 1.5 and not poise.is_full():
		poise.restore(poise.maximum * delta)
