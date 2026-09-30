class_name ActorVisual
extends Node2D
## Sprite presentation for actors: 4-direction walk sheet, squash & stretch, shadow.
## Sheet layout: `hframes` walk frames per row; rows = down, left, right, up.
## Origin (0, 0) is the actor's feet.

const WALK_FPS := 8.0
const WALK_CYCLE: Array[int] = [0, 1, 2, 1]

@export var hframes: int = 3
@export var vframes: int = 4
@export var shadow_radius: float = 7.0

@onready var sprite: Sprite2D = $Sprite

var facing_row: int = 0
var _anim_t: float = 0.0
var _pop_tween: Tween


func setup(sheet: Texture2D, tint: Color = Color.WHITE) -> void:
	if sheet == null:
		return
	sprite.texture = sheet
	sprite.hframes = hframes
	sprite.vframes = vframes
	var frame_h := sheet.get_height() / float(vframes)
	sprite.offset = Vector2(0, -frame_h * 0.5)
	sprite.self_modulate = tint
	sprite.frame = 0


func set_facing(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	if absf(dir.x) > absf(dir.y):
		facing_row = 1 if dir.x < 0.0 else 2
	else:
		facing_row = 3 if dir.y < 0.0 else 0


func update_anim(velocity: Vector2, delta: float) -> void:
	if sprite.texture == null:
		return
	var col := 0
	if velocity.length_squared() > 25.0:
		_anim_t += delta * WALK_FPS
		col = WALK_CYCLE[int(_anim_t) % WALK_CYCLE.size()] % hframes
	else:
		_anim_t = 0.0
		col = 1 % hframes
	sprite.frame = facing_row * hframes + col


## Squash & stretch for impact and attacks.
func pop(squash: Vector2 = Vector2(1.2, 0.8), duration: float = 0.12) -> void:
	if _pop_tween != null:
		_pop_tween.kill()
	sprite.scale = squash
	_pop_tween = create_tween()
	_pop_tween.tween_property(sprite, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func shake(strength: float = 2.0, duration: float = 0.2) -> void:
	var tween := create_tween()
	var steps := int(duration / 0.04)
	for i: int in steps:
		tween.tween_property(sprite, "position:x", randf_range(-strength, strength), 0.04)
	tween.tween_property(sprite, "position:x", 0.0, 0.04)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, shadow_radius, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
