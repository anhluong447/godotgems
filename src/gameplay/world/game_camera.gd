class_name GameCamera
extends Camera2D
## Follows the party leader, clamps to map bounds, and shakes with "trauma"
## (shake = trauma^2, trauma decays over time).

@export var max_offset: Vector2 = Vector2(6, 5)
@export var max_roll_deg: float = 1.2
@export var trauma_decay: float = 2.2
@export var look_ahead: float = 10.0

var target: Node2D = null
var trauma: float = 0.0

var _noise := FastNoiseLite.new()
var _noise_t: float = 0.0


func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 0.9
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0
	EventBus.party_leader_changed.connect(func(leader: Node2D) -> void: target = leader)
	EventBus.camera_shake_requested.connect(add_trauma)


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount * float(SettingsService.get_value(&"screen_shake")), 0.0, 1.0)


func set_bounds(rect: Rect2) -> void:
	limit_left = int(rect.position.x)
	limit_top = int(rect.position.y)
	limit_right = int(rect.end.x)
	limit_bottom = int(rect.end.y)


## Jump to the target instantly (map load).
func snap() -> void:
	if is_instance_valid(target) and target.is_inside_tree():
		global_position = target.global_position
	reset_smoothing()


func _process(delta: float) -> void:
	if is_instance_valid(target) and target.is_inside_tree():
		var ahead := Vector2.ZERO
		var actor := target as Actor
		if actor != null:
			ahead = actor.facing * look_ahead
		global_position = target.global_position + ahead + Vector2(0, -12)
	_noise_t += delta * 40.0
	trauma = maxf(trauma - trauma_decay * delta, 0.0)
	var shake := trauma * trauma
	offset = Vector2(
		max_offset.x * shake * _noise.get_noise_2d(_noise_t, 0.0),
		max_offset.y * shake * _noise.get_noise_2d(0.0, _noise_t))
	rotation = deg_to_rad(max_roll_deg) * shake * _noise.get_noise_2d(_noise_t, _noise_t)
