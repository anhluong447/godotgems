class_name StateMachine
extends Node
## Finite state machine. States are child nodes; their node name is the state id.
## The owner calls setup() once and physics_update() every physics frame.

signal state_changed(from: StringName, to: StringName)

@export var initial_state: State

var current: State
var _states: Dictionary[StringName, State] = {}


func setup(actor: Node) -> void:
	for child: Node in get_children():
		var state := child as State
		if state == null:
			continue
		state.machine = self
		state.actor = actor
		_states[StringName(state.name)] = state
	if initial_state == null and not _states.is_empty():
		initial_state = _states.values()[0]
	if initial_state != null:
		current = initial_state
		current.enter({})


func physics_update(delta: float) -> void:
	if current != null:
		current.physics_update(delta)


func transition_to(state_id: StringName, msg: Dictionary = {}) -> void:
	var next: State = _states.get(state_id)
	if next == null:
		push_error("%s: unknown state '%s'" % [owner.name if owner else name, state_id])
		return
	var from := current_id()
	if current != null:
		current.exit()
	current = next
	current.enter(msg)
	state_changed.emit(from, state_id)


func current_id() -> StringName:
	return StringName(current.name) if current != null else &""


func is_in(state_id: StringName) -> bool:
	return current_id() == state_id


func has_state(state_id: StringName) -> bool:
	return _states.has(state_id)
