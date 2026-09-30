class_name MapHost
extends Node2D
## Holds the current map. Registered with SceneRouter, which calls load_map().

signal map_loaded(map: MapBase)

@export var party: PartyManager
@export var camera: GameCamera

var current_map: MapBase = null


func _ready() -> void:
	SceneRouter.register_host(self)


func load_map(map_path: String, spawn_id: StringName) -> void:
	var scene := load(map_path) as PackedScene
	if scene == null:
		push_error("MapHost: cannot load %s" % map_path)
		return
	HitstopService.clear()
	party.detach()
	if current_map != null:
		remove_child(current_map)
		current_map.queue_free()
	var map := scene.instantiate() as MapBase
	if map == null:
		push_error("MapHost: %s root is not a MapBase" % map_path)
		return
	add_child(map)
	current_map = map
	var spawn := spawn_id if spawn_id != &"" else map.default_spawn
	GameState.map_path = map_path
	GameState.spawn_id = spawn
	GameState.map_display_name = map.display_name
	var at: Vector2 = map.get_spawn_position(spawn)
	if GameState.pending_position is Vector2:
		at = GameState.pending_position
		GameState.pending_position = null
	party.place_in(map.entities, at)
	camera.set_bounds(map.get_bounds())
	camera.snap()
	EventBus.palette_requested.emit(map.palette)
	if map.music != &"":
		AudioService.play_music(map.music)
	map_loaded.emit(map)
	EventBus.map_loaded.emit(map.map_id, map.display_name)
