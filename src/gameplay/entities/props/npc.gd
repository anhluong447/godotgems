class_name Npc
extends StaticBody2D
## A talkable character. Faces whoever talks to it.

@export var display_name: String = "Dân làng"
@export var sprite_sheet: Texture2D
@export var dialogue: DialogueData
@export_multiline var lines: PackedStringArray = PackedStringArray()
@export var face_direction: Vector2 = Vector2.DOWN

@onready var visual: ActorVisual = $Visual
@onready var interactable: InteractableComponent = $Interactable


func _ready() -> void:
	visual.setup(sprite_sheet)
	visual.set_facing(face_direction)
	visual.update_anim(Vector2.ZERO, 0.0)
	interactable.prompt = "Nói chuyện"
	interactable.interacted.connect(_on_interacted)


func _on_interacted(by: Node2D) -> void:
	visual.set_facing(by.global_position - global_position)
	visual.update_anim(Vector2.ZERO, 0.0)
	visual.pop(Vector2(0.9, 1.1), 0.15)
	var data := dialogue if dialogue != null else DialogueData.from_text(display_name, lines)
	EventBus.dialogue_requested.emit(data)
