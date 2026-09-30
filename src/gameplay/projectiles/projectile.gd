class_name Projectile
extends HitboxComponent
## A moving hitbox. Stops after hitting `pierce + 1` targets, or on walls.

var def: ProjectileDef
var direction: Vector2 = Vector2.RIGHT
var _life: float = 0.0
var _height: float = 0.0
var _dead: bool = false


func launch(p_def: ProjectileDef, info: DamageInfo, p_faction: Faction.Id, p_direction: Vector2, height: float = 0.0) -> void:
	def = p_def
	direction = p_direction.normalized()
	_height = height
	faction = p_faction
	rotation = direction.angle()
	_life = def.lifetime
	info.direction = direction
	set_circle(def.radius)
	if def.collides_with_world:
		collision_mask |= Faction.bit(Faction.LAYER_WORLD)
	body_entered.connect(_on_body_entered)
	hit_landed.connect(_on_hit_landed)
	activate(info, def.pierce + 1)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _dead or def == null:
		return
	super(delta)
	global_position += direction * def.speed * delta
	_life -= delta
	if _life <= 0.0 or not active:
		_die(false)


func _on_body_entered(body: Node2D) -> void:
	# Only world geometry is in our body mask.
	if body is TileMapLayer or body is StaticBody2D:
		_die(true)


func _on_hit_landed(_hurtbox: HurtboxComponent, _info: DamageInfo) -> void:
	if not active:
		_die(true)


func _die(with_fx: bool) -> void:
	if _dead:
		return
	_dead = true
	deactivate()
	if with_fx and def != null:
		Fx.spark(get_parent(), global_position + Vector2(0, _height), -direction, def.color, 5)
	queue_free()


func _draw() -> void:
	super()
	if def == null:
		return
	var offset := Vector2(0, _height).rotated(-rotation)
	if def.texture != null:
		draw_texture(def.texture, offset - def.texture.get_size() * 0.5)
		return
	var half := def.length * 0.5
	draw_line(offset + Vector2(-half, 0), offset + Vector2(half, 0), def.color, 2.0)
	draw_circle(offset + Vector2(half, 0), 1.5, Color.WHITE)
