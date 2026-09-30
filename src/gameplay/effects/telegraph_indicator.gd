class_name TelegraphIndicator
extends Node2D
## Warning shape that fills up over `duration` so the player can read incoming attacks.

enum Shape { RECT, CIRCLE }

var shape: Shape = Shape.RECT
var length: float = 32.0
var width: float = 16.0
## Rect starts this far from the origin along +X.
var start: float = 0.0
var radius: float = 24.0
var duration: float = 0.4
var color: Color = Color(1, 0.2, 0.2, 0.45)

var _t: float = 0.0


static func rect(parent: Node, p_length: float, p_width: float, p_start: float, angle: float, p_duration: float, p_color: Color) -> TelegraphIndicator:
	var t := TelegraphIndicator.new()
	t.shape = Shape.RECT
	t.length = p_length
	t.width = p_width
	t.start = p_start
	t.rotation = angle
	t.duration = p_duration
	t.color = p_color
	parent.add_child(t)
	return t


static func circle(parent: Node, p_radius: float, p_duration: float, p_color: Color) -> TelegraphIndicator:
	var t := TelegraphIndicator.new()
	t.shape = Shape.CIRCLE
	t.radius = p_radius
	t.duration = p_duration
	t.color = p_color
	parent.add_child(t)
	return t


func _ready() -> void:
	z_index = -1
	z_as_relative = true
	show_behind_parent = true


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t > duration + 0.5:
		queue_free()


func _draw() -> void:
	var p := clampf(_t / maxf(duration, 0.01), 0.0, 1.0)
	var outline := Color(color, minf(color.a + 0.3, 1.0))
	var fill := Color(color, color.a * (0.35 + 0.65 * p))
	match shape:
		Shape.RECT:
			var r := Rect2(start, -width * 0.5, length, width)
			draw_rect(r, Color(color, color.a * 0.25))
			draw_rect(Rect2(start, -width * 0.5, length * p, width), fill)
			draw_rect(r, outline, false, 1.0)
		Shape.CIRCLE:
			draw_circle(Vector2.ZERO, radius, Color(color, color.a * 0.25))
			draw_circle(Vector2.ZERO, radius * p, fill)
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, outline, 1.0)
