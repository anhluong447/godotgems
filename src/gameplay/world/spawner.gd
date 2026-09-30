@tool
class_name Spawner
extends Node2D
## Keeps `count` enemies of one type alive around itself, respawning after a delay.
## Place it inside a map's Entities node; enemies are added as siblings (y-sorted).

@export var enemy: EnemyDef
@export_range(1, 20) var count: int = 3
@export var radius: float = 48.0
## Seconds before a dead enemy is replaced. 0 = never respawn.
@export var respawn_delay: float = 8.0

var _alive: Array[Enemy] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_rng.randomize()
	# Wait until the map is fully in the tree before adding siblings.
	_fill.call_deferred()


func _fill() -> void:
	while _alive.size() < count:
		spawn_one()


func spawn_one() -> Enemy:
	if enemy == null or get_parent() == null:
		return null
	var e := Enemy.create(enemy)
	var offset := Vector2.RIGHT.rotated(_rng.randf() * TAU) * _rng.randf_range(0.0, radius)
	e.position = position + offset
	get_parent().add_child(e)
	_alive.append(e)
	e.tree_exited.connect(_on_enemy_gone.bind(e))
	return e


func _on_enemy_gone(e: Enemy) -> void:
	_alive.erase(e)
	if respawn_delay <= 0.0 or not is_inside_tree():
		return
	await get_tree().create_timer(respawn_delay, false).timeout
	if is_inside_tree() and _alive.size() < count:
		spawn_one()


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(1, 0.3, 0.3, 0.8), 1.0)
		draw_circle(Vector2.ZERO, 3.0, Color(1, 0.3, 0.3))
