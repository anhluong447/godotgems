class_name SlashTrail
extends Node2D
## Swoosh drawn over a melee swing: an arc in front of the actor, or a ring for spins.
## Parented to the actor so it follows dashes; frees itself after `lifetime`.

const SEGMENTS := 14

var inner: float = 8.0
var outer: float = 28.0
## Total arc angle in radians (TAU = full ring).
var span: float = PI * 0.8
## Swing from the other side (alternating combo hits).
var flipped: bool = false
var color: Color = Color(1, 1, 1, 0.9)
var lifetime: float = 0.14

var _t: float = 0.0


## Arc covering a rectangular hitbox of `size` centered `offset` px in front of the actor.
static func for_rect(actor: Node2D, aim: Vector2, size: Vector2, offset: float, p_color: Color, p_flipped: bool) -> SlashTrail:
	var trail := SlashTrail.new()
	trail.inner = maxf(offset - size.x * 0.5, 4.0)
	trail.outer = offset + size.x * 0.5
	var half_width := size.y * 0.5
	trail.span = clampf(2.0 * atan2(half_width + 8.0, maxf(offset, 1.0)), deg_to_rad(70.0), deg_to_rad(170.0))
	trail.rotation = aim.angle()
	trail.color = p_color
	trail.flipped = p_flipped
	_attach(actor, trail)
	return trail


static func ring(actor: Node2D, radius: float, p_color: Color) -> SlashTrail:
	var trail := SlashTrail.new()
	trail.inner = radius * 0.55
	trail.outer = radius
	trail.span = TAU
	trail.color = p_color
	trail.lifetime = 0.22
	_attach(actor, trail)
	return trail


static func _attach(actor: Node2D, trail: SlashTrail) -> void:
	trail.position = Vector2(0, -8)
	trail.z_index = 5
	actor.add_child(trail)


func _process(delta: float) -> void:
	_t += delta
	if _t >= lifetime:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var p := clampf(_t / lifetime, 0.0, 1.0)
	# The swept part grows quickly, then the whole arc fades.
	var sweep := minf(p * 2.5, 1.0)
	var alpha := color.a * (1.0 - p * p)
	var grow := 1.0 + p * 0.15
	var start := -span * 0.5
	var end := start + span * sweep
	if flipped:
		start = span * 0.5
		end = start - span * sweep
	var outer_pts := PackedVector2Array()
	var inner_pts := PackedVector2Array()
	for i: int in SEGMENTS + 1:
		var a := lerpf(start, end, float(i) / SEGMENTS)
		var dir := Vector2.RIGHT.rotated(a)
		# Taper: thin at the start of the swing, full at the leading edge.
		var k := float(i) / SEGMENTS
		var thickness := lerpf(0.25, 1.0, k) if span < TAU else 1.0
		outer_pts.append(dir * outer * grow)
		inner_pts.append(dir * lerpf(outer, inner, thickness) * grow)
	if sweep < 0.02:
		return
	# One quad per segment: robust for full rings and tiny sweeps (no self-intersection).
	var fill := Color(color, alpha * 0.75)
	for i: int in SEGMENTS:
		draw_colored_polygon(PackedVector2Array([outer_pts[i], outer_pts[i + 1], inner_pts[i + 1], inner_pts[i]]), fill)
	draw_polyline(outer_pts, Color(1, 1, 1, alpha), 2.0)
