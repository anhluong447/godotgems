class_name HurtboxComponent
extends Area2D
## The part of an entity that can be hit. Hitboxes find it; it forwards to HealthComponent.

signal hit_received(info: DamageInfo)

@export var health: HealthComponent
@export var faction: Faction.Id = Faction.Id.ENEMY:
	set(value):
		faction = value
		_apply_layers()

var enabled: bool = true


func _ready() -> void:
	monitoring = false
	monitorable = true
	_apply_layers()
	DebugService.hitboxes_toggled.connect(func(_v: bool) -> void: queue_redraw())


func set_enabled(value: bool) -> void:
	enabled = value
	set_deferred("monitorable", value)


## Called by a HitboxComponent. Returns true if the hit was accepted.
func receive_hit(info: DamageInfo) -> bool:
	if not enabled or not Faction.is_hostile(info.source_faction as Faction.Id, faction):
		return false
	if health != null and not health.apply_damage(info):
		return false
	hit_received.emit(info)
	return true


func _apply_layers() -> void:
	collision_layer = Faction.hurtbox_layer(faction)
	collision_mask = 0


func _draw() -> void:
	if not DebugService.show_hitboxes:
		return
	DebugDraw.draw_shapes(self, Color(0.2, 0.6, 1.0, 0.35))
