class_name DialogueLine
extends Resource

@export var speaker: String
@export_multiline var text: String
@export var portrait: Texture2D
@export var speaker_color: Color = Color(1, 0.86, 0.55)
## If non-empty the player picks one; the index is reported by EventBus.dialogue_finished.
@export var choices: PackedStringArray = PackedStringArray()
