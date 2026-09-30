class_name Interactor
extends Area2D
## Follows the party leader, focuses the nearest interactable and triggers it.

const REARM_TIME := 0.2

var _leader: Node2D = null
var _focused: InteractableComponent = null
var _rearm: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Faction.bit(Faction.LAYER_INTERACTABLE)
	monitoring = true
	monitorable = false
	EventBus.dialogue_finished.connect(func(_d: DialogueData, _c: int) -> void: _rearm = REARM_TIME)


func follow(leader: Node2D) -> void:
	_leader = leader


func focused() -> InteractableComponent:
	return _focused


func _physics_process(delta: float) -> void:
	_rearm = maxf(_rearm - delta, 0.0)
	if not is_instance_valid(_leader) or not _leader.is_inside_tree():
		_set_focus(null)
		return
	global_position = _leader.global_position
	_set_focus(_nearest())


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"interact") or event.is_echo():
		return
	if _focused != null and _rearm <= 0.0 and InputGate.is_open() and is_instance_valid(_leader):
		_rearm = REARM_TIME
		get_viewport().set_input_as_handled()
		_focused.interact(_leader)


func _nearest() -> InteractableComponent:
	var best: InteractableComponent = null
	var best_d := INF
	for area: Area2D in get_overlapping_areas():
		var it := area as InteractableComponent
		if it == null or not it.enabled:
			continue
		var d := it.global_position.distance_squared_to(global_position)
		if d < best_d:
			best_d = d
			best = it
	return best


func _set_focus(target: InteractableComponent) -> void:
	if target == _focused:
		return
	_focused = target
	EventBus.interaction_focus_changed.emit(target)
