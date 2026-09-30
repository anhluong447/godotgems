class_name State
extends Node
## Base state. Subclasses override the hooks they need.

var machine: StateMachine
var actor: Node


func enter(_msg: Dictionary) -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func transition_to(state_id: StringName, msg: Dictionary = {}) -> void:
	machine.transition_to(state_id, msg)
