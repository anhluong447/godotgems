extends EnemyState
## Approach (melee) or keep distance (ranged) until an ability is usable.

const STRAFE_SPEED := 0.45

var _strafe_sign: float = 1.0
var _strafe_t: float = 0.0


func enter(_msg: Dictionary) -> void:
	_strafe_sign = 1.0 if randf() < 0.5 else -1.0
	_strafe_t = randf_range(0.8, 1.6)


func physics_update(delta: float) -> void:
	var e := enemy
	if not e.has_valid_target() or e.distance_to_target() > e.def.aggro_range * 1.8 or e.too_far_from_home():
		transition_to(Enemy.STATE_IDLE, {"return_home": true})
		return
	var dir := e.direction_to_target()
	var dist := e.distance_to_target()
	e.set_facing(dir)
	var ability := e.pick_ability()
	if ability != null:
		transition_to(Enemy.STATE_TELEGRAPH, {"ability": ability})
		return
	var preferred := e.def.preferred_distance
	if preferred > 0.0:
		_strafe_t -= delta
		if _strafe_t <= 0.0:
			_strafe_t = randf_range(0.8, 1.6)
			_strafe_sign = -_strafe_sign
		if dist < preferred * 0.75:
			e.movement.move(-dir)
		elif dist > preferred * 1.15:
			e.movement.move(dir)
		else:
			e.movement.move(dir.orthogonal() * _strafe_sign, STRAFE_SPEED)
	else:
		e.movement.move(dir)
