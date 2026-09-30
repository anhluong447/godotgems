class_name PlayerController
extends MemberController
## Reads movement into the leader's intent, with soft aim assist.
## Discrete actions (attack, skills, dodge) arrive as events via PartyManager._unhandled_input
## so they are never lost between sparse physics ticks during hitstop.

const ACTIONS: Array[StringName] = [ActorIntent.ATTACK, ActorIntent.SKILL_1, ActorIntent.SKILL_2, ActorIntent.DODGE]
const AIM_ASSIST_RANGE := 170.0
const AIM_ASSIST_CONE_DEG := 35.0


func update(member: PartyMember, _delta: float) -> void:
	var intent := member.intent
	if not InputGate.is_open():
		intent.move = Vector2.ZERO
		return
	intent.move = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var base_dir := intent.move.normalized() if intent.move != Vector2.ZERO else member.facing
	intent.aim = aim_assist(member, base_dir)


## Snaps the aim toward the closest enemy inside a cone in front of `dir`.
static func aim_assist(member: Node2D, dir: Vector2) -> Vector2:
	var best: Node2D = null
	var best_score := INF
	var cone := cos(deg_to_rad(AIM_ASSIST_CONE_DEG))
	for node: Node in member.get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy == null or not enemy.is_targetable():
			continue
		var to := enemy.global_position - member.global_position
		var dist := to.length()
		if dist > AIM_ASSIST_RANGE or dist < 1.0:
			continue
		var dot := dir.dot(to / dist)
		if dot < cone:
			continue
		var score := dist * (2.0 - dot)
		if score < best_score:
			best_score = score
			best = enemy
	if best == null:
		return dir
	return (best.global_position - member.global_position).normalized()
