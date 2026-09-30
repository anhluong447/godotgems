class_name PaletteController
extends CanvasLayer
## Full-screen color grade. Two worlds, two "hand feels" (GDD pillar 2):
## "xuan" = warm and saturated, "thuc" = cold and desaturated.

const PRESETS := {
	&"none": {"saturation": 1.0, "tint": Vector3(1, 1, 1), "contrast": 1.0, "brightness": 0.0, "vignette": 0.0},
	&"xuan": {"saturation": 1.15, "tint": Vector3(1.04, 1.0, 0.93), "contrast": 1.05, "brightness": 0.01, "vignette": 0.15},
	&"thuc": {"saturation": 0.28, "tint": Vector3(0.88, 0.95, 1.08), "contrast": 0.95, "brightness": -0.05, "vignette": 0.4},
}

@export var transition_time: float = 0.6

@onready var rect: ColorRect = $Grade

var current: StringName = &"none"
var _tween: Tween


func _ready() -> void:
	EventBus.palette_requested.connect(apply)
	_set_params(PRESETS[&"none"])


func apply(preset: StringName, instant: bool = false) -> void:
	if not PRESETS.has(preset):
		push_warning("Unknown palette '%s'" % preset)
		return
	current = preset
	var target: Dictionary = PRESETS[preset]
	if _tween != null:
		_tween.kill()
	if instant:
		_set_params(target)
		return
	var mat := rect.material as ShaderMaterial
	_tween = create_tween().set_parallel(true)
	for key: String in target:
		_tween.tween_property(mat, "shader_parameter/%s" % key, target[key], transition_time)


func _set_params(p: Dictionary) -> void:
	var mat := rect.material as ShaderMaterial
	for key: String in p:
		mat.set_shader_parameter(key, p[key])
