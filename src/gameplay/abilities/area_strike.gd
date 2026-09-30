class_name AreaStrike
extends Node2D
## A delayed area attack: shows a warning circle, then hits `ticks` times.

@onready var hitbox: HitboxComponent = $Hitbox

var _def: AbilityDef
var _info: DamageInfo
var _t: float = 0.0
var _ticks_done: int = 0
var _next_tick: float = 0.0
var _started: bool = false
var _telegraph: TelegraphIndicator


func start(info: DamageInfo, faction: Faction.Id, def: AbilityDef) -> void:
	_def = def
	_info = info
	hitbox.faction = faction
	hitbox.set_circle(def.area_radius)
	_next_tick = def.area_delay
	_telegraph = TelegraphIndicator.circle(self, def.area_radius, def.area_delay, def.telegraph_color)
	_started = true


func _physics_process(delta: float) -> void:
	if not _started:
		return
	# A hitbox is kept on for one physics frame per tick.
	if hitbox.active:
		hitbox.deactivate()
	_t += delta
	if _ticks_done < _def.area_ticks and _t >= _next_tick:
		_ticks_done += 1
		_next_tick += _def.area_interval
		if is_instance_valid(_telegraph):
			_telegraph.queue_free()
		hitbox.activate(_info.copy())
		AudioService.play_sfx(&"shoot", 0.2, -4.0)
		Fx.area_burst(get_parent(), global_position, _def.area_radius, _def.telegraph_color)
	elif _ticks_done >= _def.area_ticks and not hitbox.active:
		queue_free()
