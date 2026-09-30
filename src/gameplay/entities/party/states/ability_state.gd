extends PartyState
## Performing an attack or skill (started by PartyMember.try_start_queued_action).
## Handles cancel windows: combo chaining, dodge-cancel, skill-cancel.


func physics_update(_delta: float) -> void:
	var m := member
	var abilities := m.abilities
	if abilities.phase == AbilityComponent.Phase.WINDUP and abilities.current != null:
		m.movement.move(m.intent.move, abilities.current.windup_move_factor)
	if abilities.can_cancel() and m.try_start_queued_action():
		return
	if not abilities.is_busy():
		transition_to(PartyMember.STATE_LOCOMOTION)
