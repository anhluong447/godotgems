class_name AbilityComponent
extends Node
## Runs an actor's abilities: cost, cooldown and the windup -> active -> recovery
## timeline. Behaviors plug into the phase hooks. Time is advanced by the owner
## via physics_step(), so hitstop and pause freeze abilities naturally.

signal started(def: AbilityDef)
signal phase_changed(def: AbilityDef, phase: Phase)
signal finished(def: AbilityDef, interrupted: bool)

enum Phase { IDLE, WINDUP, ACTIVE, RECOVERY }

const IFRAME_LOCK: StringName = &"ability"

@export var hitbox: HitboxComponent

var actor: Actor
var current: AbilityDef = null
var phase: Phase = Phase.IDLE
var context: AbilityContext = null

var _phase_left: float = 0.0
var _elapsed: float = 0.0
var _cooldowns: Dictionary[StringName, Cooldown] = {}


func setup(p_actor: Actor) -> void:
	actor = p_actor


func is_busy() -> bool:
	return phase != Phase.IDLE


func elapsed() -> float:
	return _elapsed


## True when another action may interrupt the current one.
func can_cancel() -> bool:
	if not is_busy():
		return true
	if phase == Phase.RECOVERY:
		return true
	return current.cancel_from > 0.0 and _elapsed >= current.cancel_from


func is_ready(def: AbilityDef) -> bool:
	if def == null:
		return false
	var cd: Cooldown = _cooldowns.get(def.id)
	if cd != null and not cd.is_ready():
		return false
	return actor.energy.can_afford(def.energy_cost)


func cooldown_ratio(def: AbilityDef) -> float:
	var cd: Cooldown = _cooldowns.get(def.id) if def != null else null
	return cd.ratio() if cd != null else 0.0


## Starts `def`, cancelling the current ability if allowed. Returns success.
func try_use(def: AbilityDef, aim: Vector2, target_position: Vector2) -> bool:
	if not is_ready(def):
		return false
	if is_busy():
		if not can_cancel():
			return false
		_finish(true)
	if def.behavior == null:
		push_error("Ability %s has no behavior" % def.id)
		return false
	actor.energy.spend(def.energy_cost)
	if def.cooldown > 0.0:
		if not _cooldowns.has(def.id):
			_cooldowns[def.id] = Cooldown.new(def.cooldown)
		_cooldowns[def.id].start()
	context = AbilityContext.new()
	context.actor = actor
	context.def = def
	context.aim = aim.normalized() if aim != Vector2.ZERO else actor.facing
	context.target_position = target_position
	context.hitbox = hitbox
	current = def
	_elapsed = 0.0
	started.emit(def)
	AudioService.play_sfx(def.sfx_start)
	_enter(Phase.WINDUP)
	def.behavior.on_windup_start(context)
	_advance_while_expired()
	return true


## Update the aim (enemies tracking their target during windup).
func set_aim(aim: Vector2) -> void:
	if context != null and aim != Vector2.ZERO:
		context.aim = aim.normalized()


func set_target_position(target_position: Vector2) -> void:
	if context != null:
		context.target_position = target_position


func interrupt() -> void:
	if is_busy():
		_finish(true)


func physics_step(delta: float) -> void:
	for cd: Cooldown in _cooldowns.values():
		cd.tick(delta)
	if not is_busy():
		return
	_elapsed += delta
	_phase_left -= delta
	match phase:
		Phase.WINDUP:
			current.behavior.on_windup_tick(context, delta)
		Phase.ACTIVE:
			current.behavior.on_active_tick(context, delta)
	_advance_while_expired()


func _advance_while_expired() -> void:
	while is_busy() and _phase_left <= 0.0:
		match phase:
			Phase.WINDUP:
				_enter(Phase.ACTIVE)
				if current.grants_iframes:
					actor.health.add_lock(IFRAME_LOCK)
				AudioService.play_sfx(current.sfx_active)
				current.behavior.on_active_start(context)
			Phase.ACTIVE:
				current.behavior.on_active_end(context)
				actor.health.remove_lock(IFRAME_LOCK)
				_enter(Phase.RECOVERY)
			Phase.RECOVERY:
				_finish(false)


func _enter(next: Phase) -> void:
	phase = next
	match next:
		Phase.WINDUP:
			_phase_left = current.windup
		# Later phases add to the remainder so frame overshoot carries over.
		Phase.ACTIVE:
			_phase_left += current.active_time
		Phase.RECOVERY:
			_phase_left += current.recovery
	phase_changed.emit(current, next)


func _finish(interrupted: bool) -> void:
	var def := current
	var ctx := context
	if phase == Phase.ACTIVE:
		def.behavior.on_active_end(ctx)
	def.behavior.on_end(ctx, interrupted)
	actor.health.remove_lock(IFRAME_LOCK)
	current = null
	context = null
	phase = Phase.IDLE
	_phase_left = 0.0
	finished.emit(def, interrupted)
