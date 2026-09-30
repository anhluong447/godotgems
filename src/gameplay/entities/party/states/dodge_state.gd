extends PartyState
## Quick dash with invulnerability frames.

const LOCK: StringName = &"dodge"

var _t: float = 0.0
var _dir: Vector2 = Vector2.DOWN
var _ghost_t: float = 0.0


func enter(_msg: Dictionary) -> void:
	var m := member
	_t = 0.0
	_ghost_t = 0.0
	_dir = m.intent.move.normalized() if m.intent.move != Vector2.ZERO else m.facing
	m.set_facing(_dir)
	m.dodge_cooldown.start()
	m.health.add_lock(LOCK)
	m.movement.set_forced(_dir * m.def.dodge_speed)
	m.visual.pop(Vector2(1.25, 0.8), 0.15)
	AudioService.play_sfx(&"dodge")


func exit() -> void:
	member.health.remove_lock(LOCK)
	member.movement.clear_forced()


func physics_update(delta: float) -> void:
	var m := member
	_t += delta
	_ghost_t -= delta
	if _ghost_t <= 0.0:
		Fx.afterimage(m.visual)
		_ghost_t = 0.04
	if _t >= m.def.dodge_iframes:
		m.health.remove_lock(LOCK)
	if _t >= m.def.dodge_time:
		m.movement.clear_forced()
		# Allow an attack queued during the dodge to come out immediately.
		if not m.try_start_queued_action():
			transition_to(PartyMember.STATE_LOCOMOTION)
