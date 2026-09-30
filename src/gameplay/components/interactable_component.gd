class_name InteractableComponent
extends Area2D
## Something the party leader can interact with. The owning prop connects `interacted`.

signal interacted(by: Node2D)

## Translation key shown in the prompt, e.g. PROMPT_OPEN.
@export var prompt: String = "PROMPT_DEFAULT"
@export var enabled: bool = true
## Where the prompt appears, relative to this node.
@export var prompt_offset: Vector2 = Vector2(0, -28)


func _ready() -> void:
	collision_layer = Faction.bit(Faction.LAYER_INTERACTABLE)
	collision_mask = 0
	monitoring = false
	monitorable = true


func interact(by: Node2D) -> void:
	if enabled:
		interacted.emit(by)


func prompt_position() -> Vector2:
	return global_position + prompt_offset
