class_name MapBase
extends Node2D
## Root script for every map scene. Required children:
##   Ground (TileMapLayer)  - defines the camera bounds
##   Entities (Node2D, y-sorted) - props, NPCs, spawners; the party is added here
##   SpawnPoints (Node2D) - Marker2D children; their names are spawn ids

@export var map_id: StringName = &"map"
@export var display_name: String = ""
## Palette preset applied on load: xuan | thuc | none
@export var palette: StringName = &"xuan"
@export var music: StringName = &""
## Used when no spawn id is given (new game, respawn after a party wipe).
@export var default_spawn: StringName = &"start"

@onready var ground: TileMapLayer = $Ground
@onready var entities: Node2D = $Entities
@onready var spawn_points: Node2D = $SpawnPoints


func get_spawn_position(spawn_id: StringName) -> Vector2:
	if spawn_id == &"":
		spawn_id = default_spawn
	var marker := spawn_points.get_node_or_null(NodePath(String(spawn_id))) as Node2D
	if marker == null:
		if spawn_id != &"":
			push_warning("Map %s: no spawn point '%s'" % [map_id, spawn_id])
		marker = spawn_points.get_child(0) as Node2D if spawn_points.get_child_count() > 0 else null
	return marker.global_position if marker != null else global_position


func get_bounds() -> Rect2:
	if ground == null or ground.tile_set == null:
		return Rect2(-10000, -10000, 20000, 20000)
	var used := ground.get_used_rect()
	var tile := Vector2(ground.tile_set.tile_size)
	return Rect2(ground.global_position + Vector2(used.position) * tile, Vector2(used.size) * tile)


## Stable key for things in this map that remember state (opened chests...).
func persist_key(node: Node) -> StringName:
	return StringName("%s:%s" % [map_id, get_path_to(node)])
