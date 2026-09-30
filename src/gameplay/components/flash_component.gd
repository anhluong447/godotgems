class_name FlashComponent
extends Node
## Briefly tints a CanvasItem (hit flash). Uses a ShaderMaterial on the target.

const FLASH_SHADER := preload("res://assets/shaders/flash.gdshader")

@export var target: CanvasItem
@export var default_color: Color = Color.WHITE
@export var default_duration: float = 0.1

var _material: ShaderMaterial
var _tween: Tween


func _ready() -> void:
	if target == null:
		return
	_material = ShaderMaterial.new()
	_material.shader = FLASH_SHADER
	target.material = _material


func flash(color: Color = default_color, duration: float = default_duration) -> void:
	if _material == null:
		return
	if _tween != null:
		_tween.kill()
	_material.set_shader_parameter(&"flash_color", color)
	_material.set_shader_parameter(&"flash_amount", 1.0)
	_tween = create_tween()
	_tween.tween_method(_set_amount, 1.0, 0.0, duration)


func _set_amount(value: float) -> void:
	_material.set_shader_parameter(&"flash_amount", value)
