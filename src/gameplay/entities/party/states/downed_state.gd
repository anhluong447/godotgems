extends PartyState
## HP reached 0: lie down, then get back up with part of the HP (GDD 6.3).

const LOCK: StringName = &"downed"

var _t: float = 0.0


func enter(_msg: Dictionary) -> void:
	var m := member
	_t = Registry.combat_config.downed_duration
	m.abilities.interrupt()
	m.movement.stop_immediately()
	m.health.add_lock(LOCK)
	m.hurtbox.set_enabled(false)
	m.visual.rotation = deg_to_rad(90.0)
	m.visual.modulate = Color(0.6, 0.6, 0.7, 0.8)


func exit() -> void:
	var m := member
	m.health.remove_lock(LOCK)
	m.hurtbox.set_enabled(true)
	m.visual.rotation = 0.0
	m.visual.modulate = Color.WHITE
	m.health.grant_iframes(1.0)
	AudioService.play_sfx(&"revive")


func physics_update(delta: float) -> void:
	_t -= delta
	if _t <= 0.0:
		member.revive(Registry.combat_config.revive_hp_ratio)


func time_left() -> float:
	return maxf(_t, 0.0)
