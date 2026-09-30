extends EnemyState
## Active + recovery frames of the ability. Committed: no tracking.


func physics_update(_delta: float) -> void:
	if not enemy.abilities.is_busy():
		transition_to(Enemy.STATE_RECOVER)
