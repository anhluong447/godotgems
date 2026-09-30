extends EnemyState
## Poise broken: interrupted and helpless for a moment.

var _t: float = 0.0


func enter(_msg: Dictionary) -> void:
	var e := enemy
	_t = e.def.stagger_time
	e.abilities.interrupt()
	e.visual.shake(2.5, _t)
	e.flash.flash(Color(1, 0.9, 0.4), 0.15)


func physics_update(delta: float) -> void:
	_t -= delta
	if _t <= 0.0:
		transition_to(Enemy.STATE_CHASE if enemy.has_valid_target() else Enemy.STATE_IDLE)
