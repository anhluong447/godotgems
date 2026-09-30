extends EnemyState
## Breather after an attack: the player's punish window.

var _t: float = 0.0


func enter(_msg: Dictionary) -> void:
	_t = enemy.def.recover_time


func physics_update(delta: float) -> void:
	_t -= delta
	if _t <= 0.0:
		transition_to(Enemy.STATE_CHASE if enemy.has_valid_target() else Enemy.STATE_IDLE)
