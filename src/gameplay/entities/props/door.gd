class_name Door
extends StaticBody2D
## Leads to another map. `target_spawn` is a Marker2D name in the target map's SpawnPoints.

@export_file("*.tscn") var target_map: String
@export var target_spawn: StringName = &"start"

@onready var interactable: InteractableComponent = $Interactable


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)


func _on_interacted(_by: Node2D) -> void:
	if target_map.is_empty():
		push_warning("Door %s has no target map" % name)
		return
	AudioService.play_sfx(&"door", 0.0)
	SceneRouter.change_map(target_map, target_spawn)
