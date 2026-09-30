class_name ActorIntent
extends RefCounted
## What an actor wants to do this frame. Written by a controller (player input or AI),
## read by the actor's states. The actor never knows who is controlling it.

const ATTACK: StringName = &"attack"
const SKILL_1: StringName = &"skill_1"
const SKILL_2: StringName = &"skill_2"
const DODGE: StringName = &"dodge"

var move: Vector2 = Vector2.ZERO
## Desired aim direction. Zero means "use current facing".
var aim: Vector2 = Vector2.ZERO
var actions: ActionBuffer = ActionBuffer.new(0.18)


func tick(delta: float) -> void:
	actions.tick(delta)


func clear() -> void:
	move = Vector2.ZERO
	aim = Vector2.ZERO
	actions.clear()
