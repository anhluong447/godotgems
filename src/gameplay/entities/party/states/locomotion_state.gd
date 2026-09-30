extends PartyState
## Walking / standing. Starts queued actions.


func physics_update(_delta: float) -> void:
	var m := member
	m.movement.move(m.intent.move)
	if m.intent.move != Vector2.ZERO:
		m.set_facing(m.intent.move)
	m.try_start_queued_action()
