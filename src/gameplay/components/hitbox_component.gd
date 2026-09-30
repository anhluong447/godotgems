class_name HitboxComponent
extends Area2D
## Deals damage to hostile hurtboxes while active. Each activation hits a target at most once.
## Polls overlaps every physics frame so targets already inside when activated are hit too.

signal hit_landed(hurtbox: HurtboxComponent, info: DamageInfo)

@export var faction: Faction.Id = Faction.Id.ENEMY:
	set(value):
		faction = value
		_apply_layers()
## Knockback is pushed away from this node (usually the attacking actor). Defaults to self.
@export var knockback_origin: Node2D

var active: bool = false
## -1 = unlimited targets per activation.
var max_targets: int = -1

var _info: DamageInfo
var _already_hit: Dictionary[int, bool] = {}
var _hit_count: int = 0
var _shape_node: CollisionShape2D


func _ready() -> void:
	monitoring = false
	monitorable = false
	_apply_layers()
	_shape_node = _find_or_create_shape()
	# Scene sub-resources are shared between instances; resize our own copy only.
	_shape_node.shape = _shape_node.shape.duplicate() if _shape_node.shape != null else RectangleShape2D.new()
	DebugService.hitboxes_toggled.connect(func(_v: bool) -> void: queue_redraw())


func set_rect(size: Vector2) -> void:
	var rect := _shape_node.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		_shape_node.shape = rect
	rect.size = size
	queue_redraw()


func set_circle(radius: float) -> void:
	var circle := _shape_node.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		_shape_node.shape = circle
	circle.radius = radius
	queue_redraw()


func activate(info: DamageInfo, p_max_targets: int = -1) -> void:
	_info = info
	_info.source_faction = faction
	max_targets = p_max_targets
	_already_hit.clear()
	_hit_count = 0
	active = true
	monitoring = true
	queue_redraw()


func deactivate() -> void:
	active = false
	set_deferred("monitoring", false)
	queue_redraw()


## Forget who was hit so the next check can hit them again (multi-tick areas).
func reset_hits() -> void:
	_already_hit.clear()


func _physics_process(_delta: float) -> void:
	if active and monitoring:
		_scan()


func _scan() -> void:
	for area: Area2D in get_overlapping_areas():
		if not active:
			return
		var hurtbox := area as HurtboxComponent
		if hurtbox == null:
			continue
		var id := hurtbox.get_instance_id()
		if _already_hit.has(id):
			continue
		_already_hit[id] = true
		var info := _info.copy()
		if info.direction == Vector2.ZERO:
			var origin := knockback_origin.global_position if is_instance_valid(knockback_origin) else global_position
			info.direction = (hurtbox.global_position - origin).normalized()
			if info.direction == Vector2.ZERO:
				info.direction = Vector2.RIGHT.rotated(global_rotation)
		if hurtbox.receive_hit(info):
			_hit_count += 1
			hit_landed.emit(hurtbox, info)
			if max_targets >= 0 and _hit_count >= max_targets:
				deactivate()


func _apply_layers() -> void:
	collision_layer = 0
	collision_mask = Faction.hitbox_mask(faction)


func _find_or_create_shape() -> CollisionShape2D:
	for child: Node in get_children():
		if child is CollisionShape2D:
			return child
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	add_child(shape)
	return shape


func _draw() -> void:
	if not DebugService.show_hitboxes:
		return
	DebugDraw.draw_shapes(self, Color(1, 0.2, 0.2, 0.5) if active else Color(1, 0.6, 0.2, 0.12))
