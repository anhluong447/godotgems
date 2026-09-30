class_name Chest
extends StaticBody2D
## Opens once and gives items. Remembers being opened through GameState flags.

@export var item: ItemDef
@export var count: int = 1
@export var closed_texture: Texture2D
@export var open_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite
@onready var interactable: InteractableComponent = $Interactable

var _flag: StringName = &""


func _ready() -> void:
	var map := owner as MapBase
	_flag = StringName("opened:%s" % (map.persist_key(self) if map != null else String(get_path())))
	interactable.interacted.connect(_on_interacted)
	_set_open(GameState.has_flag(_flag))


func _on_interacted(_by: Node2D) -> void:
	if GameState.has_flag(_flag):
		return
	GameState.set_flag(_flag)
	_set_open(true)
	AudioService.play_sfx(&"chest", 0.0)
	var tween := create_tween()
	sprite.scale = Vector2(1.2, 0.85)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	if item != null:
		GameState.inventory.add(item.id, count, item.max_stack)
		EventBus.item_collected.emit(item.id, count)


func _set_open(open: bool) -> void:
	sprite.texture = open_texture if open else closed_texture
	interactable.enabled = not open
