class_name SignPost
extends StaticBody2D
## Shows text when read. Use `dialogue` for rich content or `lines` for quick text.

@export var title: String = "Biển báo"
@export_multiline var lines: PackedStringArray = PackedStringArray()
@export var dialogue: DialogueData

@onready var interactable: InteractableComponent = $Interactable


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)


func _on_interacted(_by: Node2D) -> void:
	var data := dialogue if dialogue != null else DialogueData.from_text(title, lines)
	EventBus.dialogue_requested.emit(data)
