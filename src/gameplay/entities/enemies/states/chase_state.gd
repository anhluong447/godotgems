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
		if e.request_attack_token():
			transition_to(Enemy.STATE_TELEGRAPH, {"ability": ability})
			return
		# Someone else is attacking: circle at a respectful distance and wait.
		var wait_distance := maxf(ability.ai_range * 1.4, 48.0)
		var toward := 1.0 if dist > wait_distance else -0.6
		_move(e, (dir * toward + dir.orthogonal() * _strafe_sign).normalized(), STRAFE_SPEED)
		return
	var preferred := e.def.preferred_distance
	if preferred > 0.0:
		_strafe_t -= delta
		if _strafe_t <= 0.0:
			_strafe_t = randf_range(0.8, 1.6)
			_strafe_sign = -_strafe_sign
		if dist < preferred * 0.75:
			_move(e, -dir)
		elif dist > preferred * 1.15:
			_move(e, dir)
		else:
			_move(e, dir.orthogonal() * _strafe_sign, STRAFE_SPEED)
	else:
		_move(e, dir)


func _move(e: Enemy, dir: Vector2, speed: float = 1.0) -> void:
	e.movement.move((dir + e.separation() * 1.5).limit_length(1.0), speed)
