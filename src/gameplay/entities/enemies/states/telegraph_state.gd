extends EnemyState
## Windup of an ability: the readable warning before the hit (>= 0.4s, GDD 6.5).


func enter(msg: Dictionary) -> void:
	var e := enemy
	var ability: AbilityDef = msg.get("ability")
	if ability == null or not e.abilities.try_use(ability, e.direction_to_target(), e.target.global_position):
		transition_to(Enemy.STATE_CHASE)
		return
	e.visual.shake(1.0, ability.windup)
	if ability.show_telegraph:
		AudioService.play_sfx(&"telegraph", 0.0, -6.0)


func physics_update(_delta: float) -> void:
	var e := enemy
	var abilities := e.abilities
	if not abilities.is_busy():
		transition_to(Enemy.STATE_RECOVER)
		return
	var current := abilities.current
	if current.track_during_windup and e.has_valid_target():
		abilities.set_aim(e.direction_to_target())
		abilities.set_target_position(e.target.global_position)
		e.set_facing(e.direction_to_target())
	if current.windup_move_factor > 0.0 and e.has_valid_target():
		e.movement.move(e.direction_to_target(), current.windup_move_factor)
	if abilities.phase != AbilityComponent.Phase.WINDUP:
		transition_to(Enemy.STATE_ATTACK)
