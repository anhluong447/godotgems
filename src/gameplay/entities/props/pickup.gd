class_name Pickup
extends Area2D
## An item lying in the world. Pops out, bobs, is pulled toward the party, collected on touch.

const MAGNET_RADIUS := 44.0
const MAGNET_SPEED := 220.0
const ARM_DELAY := 0.35

@export var item: ItemDef
@export var count: int = 1

var _velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0
var _collected: bool = false


func _ready() -> void:
	collision_layer = Faction.bit(Faction.LAYER_PICKUP)
	collision_mask = Faction.bit(Faction.LAYER_PARTY)
	monitoring = true
	body_entered.connect(_on_body_entered)
	queue_redraw()


func pop(velocity: Vector2) -> void:
	_velocity = velocity


func _physics_process(delta: float) -> void:
	_age += delta
	if _velocity != Vector2.ZERO:
		global_position += _velocity * delta
		_velocity = _velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	if _age > ARM_DELAY:
		var nearest := _nearest_member()
		if nearest != null:
			var to := nearest.global_position - global_position
			if to.length() < MAGNET_RADIUS:
				global_position += to.normalized() * MAGNET_SPEED * delta
			for body: Node2D in get_overlapping_bodies():
				_on_body_entered(body)
	queue_redraw()


func _nearest_member() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for node: Node in get_tree().get_nodes_in_group(&"party"):
		var m := node as PartyMember
		if m == null or m.is_downed():
			continue
		var d := m.global_position.distance_squared_to(global_position)
		if d < best_d:
			best_d = d
			best = m
	return best


func _on_body_entered(body: Node2D) -> void:
	var member := body as PartyMember
	if _collected or member == null or member.is_downed() or _age < ARM_DELAY or item == null:
		return
	if item.kind == ItemDef.Kind.INSTANT:
		member.health.heal(item.heal_amount * count)
	else:
		var added := GameState.inventory.add(item.id, count, item.max_stack)
		if added <= 0:
			return
	_collected = true
	AudioService.play_sfx(&"pickup", 0.1)
	EventBus.item_collected.emit(item.id, count)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.08)
	tween.tween_property(self, "modulate:a", 0.0, 0.08)
	tween.tween_callback(queue_free)


func _draw() -> void:
	var bob := sin(_age * 6.0) * 1.5 - 5.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 4.0, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if item != null and item.icon != null:
		draw_texture(item.icon, Vector2(-8, -8 + bob))
	else:
		var c := item.color if item != null else Color.MAGENTA
		draw_circle(Vector2(0, bob), 4.0, c)
		draw_circle(Vector2(-1, bob - 1), 1.5, Color(1, 1, 1, 0.7))
