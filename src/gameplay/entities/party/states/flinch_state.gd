extends PartyState
## Short stun after poise break. Dodge can still escape it late.

const DURATION := 0.3

var _t: float = 0.0


func enter(_msg: Dictionary) -> void:
	_t = 0.0
	member.abilities.interrupt()
	AudioService.play_sfx(&"hurt")


func physics_update(delta: float) -> void:
	_t += delta
	if _t >= DURATION:
		transition_to(PartyMember.STATE_LOCOMOTION)
