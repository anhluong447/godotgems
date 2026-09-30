class_name Breakable
extends StaticBody2D
## Pots, crates: can be broken by the party and may drop loot.

@export var hit_points: float = 1.0
@export var debris_color: Color = Color(0.75, 0.5, 0.35)

@onready var sprite: Sprite2D = $Sprite
@onready var health: HealthComponent = $Health
@onready var hurtbox: HurtboxComponent = $Hurtbox
@onready var loot: LootDropper = $LootDropper
@onready var flash: FlashComponent = $Flash


func _ready() -> void:
	health.setup(hit_points)
	hurtbox.faction = Faction.Id.NEUTRAL
	hurtbox.hit_received.connect(_on_hit)
	health.died.connect(_on_broken)


func _on_hit(_info: DamageInfo) -> void:
	flash.flash()
	var tween := create_tween()
	sprite.scale = Vector2(1.15, 0.85)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.12)


func _on_broken(_info: DamageInfo) -> void:
	AudioService.play_sfx(&"break")
	Fx.death_puff(get_parent(), global_position + Vector2(0, -8), debris_color)
	loot.drop(global_position, get_parent())
	queue_free()
