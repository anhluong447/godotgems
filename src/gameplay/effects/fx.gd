class_name Fx
extends RefCounted
## Factory for short-lived visual effects. Everything here frees itself.

const BOLD_FONT := preload("res://assets/fonts/BeVietnamPro-Bold.ttf")

static var _number_settings: Dictionary[String, LabelSettings] = {}


static func spark(parent: Node, at: Vector2, direction: Vector2, color: Color, amount: int = 8) -> void:
	if parent == null:
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 0.25
	p.direction = direction if direction != Vector2.ZERO else Vector2.UP
	p.spread = 55.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 150.0
	p.damping_min = 250.0
	p.damping_max = 350.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = color
	p.z_index = 20
	_attach(parent, p, at)


static func death_puff(parent: Node, at: Vector2, color: Color) -> void:
	if parent == null:
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = 18
	p.lifetime = 0.5
	p.spread = 180.0
	p.gravity = Vector2(0, -30)
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 70.0
	p.damping_min = 60.0
	p.damping_max = 90.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	var ramp := Gradient.new()
	ramp.set_color(0, color)
	ramp.set_color(1, Color(color, 0.0))
	p.color_ramp = ramp
	p.z_index = 20
	_attach(parent, p, at)


static func area_burst(parent: Node, at: Vector2, radius: float, color: Color) -> void:
	if parent == null:
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 14
	p.lifetime = 0.3
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radius * 0.8
	p.direction = Vector2.UP
	p.spread = 25.0
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 60.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color(color, 1.0).lightened(0.4)
	p.z_index = 20
	_attach(parent, p, at)


static func afterimage(visual: ActorVisual) -> void:
	if visual == null or visual.sprite == null or visual.sprite.texture == null:
		return
	var parent := visual.get_parent().get_parent()
	if parent == null:
		return
	var ghost := Sprite2D.new()
	var src := visual.sprite
	ghost.texture = src.texture
	ghost.hframes = src.hframes
	ghost.vframes = src.vframes
	ghost.frame = src.frame
	ghost.offset = src.offset
	ghost.scale = src.scale
	ghost.modulate = Color(0.6, 0.85, 1.0, 0.55)
	ghost.z_index = -1
	parent.add_child(ghost)
	ghost.global_position = src.global_position
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tween.tween_callback(ghost.queue_free)


static func damage_number(parent: Node, at: Vector2, amount: int, is_crit: bool, on_party: bool) -> void:
	if parent == null:
		return
	var label := Label.new()
	label.text = str(amount) + ("!" if is_crit else "")
	var key := "crit" if is_crit else ("party" if on_party else "normal")
	label.label_settings = _settings_for(key)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(40, 12)
	label.pivot_offset = label.size * 0.5
	label.z_index = 30
	parent.add_child(label)
	var drift := randf_range(-8.0, 8.0)
	label.global_position = at + Vector2(-20 + drift, -30)
	label.scale = Vector2(1.6, 1.6) if is_crit else Vector2(1.3, 1.3)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2.ONE, 0.12)
	tween.tween_property(label, "position:y", label.position.y - 16.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.25).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


static func _settings_for(key: String) -> LabelSettings:
	if _number_settings.has(key):
		return _number_settings[key]
	var s := LabelSettings.new()
	s.font = BOLD_FONT
	s.outline_size = 3
	s.outline_color = Color(0.1, 0.05, 0.08)
	match key:
		"crit":
			s.font_size = 12
			s.font_color = Color(1.0, 0.85, 0.25)
		"party":
			s.font_size = 10
			s.font_color = Color(1.0, 0.35, 0.35)
		_:
			s.font_size = 10
			s.font_color = Color.WHITE
	_number_settings[key] = s
	return s


static func _attach(parent: Node, p: CPUParticles2D, at: Vector2) -> void:
	parent.add_child(p)
	p.global_position = at
	p.finished.connect(p.queue_free)
	p.emitting = true
