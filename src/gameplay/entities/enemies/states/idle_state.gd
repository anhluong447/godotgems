extends EnemyState
## Wander around home; look for targets. Walks home after losing a chase.

const SCAN_INTERVAL := 0.2
const WANDER_SPEED := 0.4

var _scan_t: float = 0.0
var _wander_t: float = 0.0
var _goal: Vector2
var _returning: bool = false


func enter(msg: Dictionary) -> void:
	var e := enemy
	e.target = null
	_returning = msg.get("return_home", false)
	_goal = e.home
	_wander_t = randf_range(0.5, 1.5)


func physics_update(delta: float) -> void:
	var e := enemy
	if e.def.stationary:
		return
	_scan_t -= delta
	if _scan_t <= 0.0 and not _returning:
		_scan_t = SCAN_INTERVAL
		var found := e.find_target()
		if found != null:
			e.target = found
			transition_to(Enemy.STATE_CHASE)
			return
	var to_goal := _goal - e.global_position
	if to_goal.length() > 6.0:
		e.movement.move(to_goal.normalized(), 1.0 if _returning else WANDER_SPEED)
		e.set_facing(to_goal)
	else:
		_returning = false
		_wander_t -= delta
		if _wander_t <= 0.0:
			_wander_t = randf_range(1.5, 3.0)
			var r := e.def.wander_radius
			_goal = e.home + Vector2(randf_range(-r, r), randf_range(-r, r))
