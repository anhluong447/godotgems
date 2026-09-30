class_name AIController
extends MemberController
## Simple companion AI (GDD 6.3): follow the leader, fight enemies near the group.

const FOLLOW_DISTANCE := 26.0
const TELEPORT_DISTANCE := 360.0
const LEASH_FROM_LEADER := 220.0
const RETARGET_INTERVAL := 0.25
const ATTACK_INTERVAL := 0.22

## Returns the current leader (PartyMember) or null.
var leader_provider: Callable
## Spreads followers so they do not stack.
var slot_angle: float = 0.0

var _target: Enemy = null
var _retarget_t: float = 0.0
var _attack_t: float = 0.0


func update(member: PartyMember, delta: float) -> void:
	var intent := member.intent
	intent.move = Vector2.ZERO
	var leader: PartyMember = leader_provider.call() if leader_provider.is_valid() else null
	if leader == null or leader == member:
		return
	_retarget_t -= delta
	_attack_t -= delta
	if _retarget_t <= 0.0:
		_retarget_t = RETARGET_INTERVAL
		_target = _find_target(member, leader)
	var to_leader := leader.global_position - member.global_position
	if to_leader.length() > TELEPORT_DISTANCE:
		member.global_position = leader.global_position - leader.facing * FOLLOW_DISTANCE
		return
	if _target != null and _target.is_targetable():
		_fight(member, intent)
	else:
		_follow(member, leader, intent)


func _fight(member: PartyMember, intent: ActorIntent) -> void:
	var to := _target.global_position - member.global_position
	var dist := to.length()
	var dir := to / maxf(dist, 0.001)
	intent.aim = dir
	var first := member.current_combo_ability()
	var attack_range := first.ai_range if first != null else 30.0
	var preferred := member.def.ai_preferred_distance
	if preferred > 0.0:
		if dist < preferred * 0.6:
			intent.move = -dir
		elif dist > attack_range:
			intent.move = dir
	elif dist > attack_range * 0.85:
		intent.move = dir
	if intent.move != Vector2.ZERO:
		member.set_facing(intent.move)
	if dist <= attack_range and _attack_t <= 0.0:
		_attack_t = ATTACK_INTERVAL
		member.set_facing(dir)
		# Occasionally use a skill when energy is plentiful.
		if member.energy.ratio() > 0.8 and randf() < 0.15 and member.abilities.is_ready(member.def.skill_1):
			intent.actions.press(ActorIntent.SKILL_1)
		else:
			intent.actions.press(ActorIntent.ATTACK)


func _follow(member: PartyMember, leader: PartyMember, intent: ActorIntent) -> void:
	var behind := -leader.facing.rotated(slot_angle) * FOLLOW_DISTANCE
	var goal := leader.global_position + behind
	var to_goal := goal - member.global_position
	var dist := to_goal.length()
	if dist > 6.0:
		intent.move = to_goal / dist * clampf(dist / 40.0, 0.35, 1.0)
		member.set_facing(to_goal)


func _find_target(member: PartyMember, leader: PartyMember) -> Enemy:
	var best: Enemy = null
	var best_dist := member.def.ai_engage_range
	for node: Node in member.get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy == null or not enemy.is_targetable() or enemy.def.stationary:
			continue
		if enemy.global_position.distance_to(leader.global_position) > LEASH_FROM_LEADER:
			continue
		var d := enemy.global_position.distance_to(member.global_position)
		if d < best_dist:
			best_dist = d
			best = enemy
	return best
