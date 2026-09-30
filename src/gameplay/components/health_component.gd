class_name HealthComponent
extends Node
## HP, invulnerability and damage resolution for anything that can be hurt.

signal changed(current: float, maximum: float)
signal damaged(info: DamageInfo)
signal healed(amount: float)
signal died(info: DamageInfo)
signal revived

## Optional. Provides DEF for damage reduction.
@export var stats: StatsComponent
@export var max_hp: float = 10.0
## Invulnerability granted after every accepted hit.
@export var hit_iframes: float = 0.0
## Party members ignore damage while the debug god mode is on.
@export var respects_god_mode: bool = false

var pool: ResourcePool
var last_hit: DamageInfo = null

var _iframe_left: float = 0.0
var _locks: Dictionary[StringName, bool] = {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if pool == null:
		setup(max_hp)


## refill = true: start at full HP. refill = false: keep the current HP ratio (level ups).
func setup(p_max_hp: float, refill: bool = true) -> void:
	max_hp = p_max_hp
	if pool == null:
		pool = ResourcePool.new(max_hp)
		pool.changed.connect(func(c: float, m: float) -> void: changed.emit(c, m))
	else:
		pool.set_maximum(max_hp, not refill)
		if refill:
			pool.fill()
	changed.emit(pool.current, pool.maximum)


func _physics_process(delta: float) -> void:
	if _iframe_left > 0.0:
		_iframe_left = maxf(_iframe_left - delta, 0.0)


func current() -> float:
	return pool.current


func is_dead() -> bool:
	return pool.is_empty()


func is_invulnerable() -> bool:
	if respects_god_mode and DebugService.god_mode:
		return true
	return _iframe_left > 0.0 or not _locks.is_empty()


func grant_iframes(duration: float) -> void:
	_iframe_left = maxf(_iframe_left, duration)


## Named invulnerability (dodge, downed, skill). Remove with the same reason.
func add_lock(reason: StringName) -> void:
	_locks[reason] = true


func remove_lock(reason: StringName) -> void:
	_locks.erase(reason)


## Resolves and applies a hit. Returns false if the hit was ignored.
func apply_damage(info: DamageInfo) -> bool:
	if is_dead() or is_invulnerable():
		return false
	var defense := stats.get_stat(StatBlock.DEF) if stats != null else 0.0
	DamageCalculator.resolve(info, defense, Registry.combat_config, _rng)
	last_hit = info
	pool.drain(info.final_amount)
	damaged.emit(info)
	var target := owner as Node2D
	if target != null:
		EventBus.damage_applied.emit(target, info)
	if is_dead():
		died.emit(info)
	elif hit_iframes > 0.0:
		grant_iframes(hit_iframes)
	return true


func heal(amount: float) -> float:
	if is_dead():
		return 0.0
	var added := pool.restore(amount)
	if added > 0.0:
		healed.emit(added)
	return added


func revive(hp_ratio: float = 1.0) -> void:
	if not is_dead():
		return
	pool.set_current(maxf(pool.maximum * hp_ratio, 1.0))
	revived.emit()


func kill() -> void:
	if is_dead():
		return
	var info := DamageInfo.new()
	info.final_amount = ceili(pool.current)
	pool.drain(pool.current)
	died.emit(info)
