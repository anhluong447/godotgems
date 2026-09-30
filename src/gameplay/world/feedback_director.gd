class_name FeedbackDirector
extends Node
## Turns combat events into "juice": hitstop, screen shake, damage numbers, sparks, sounds.
## Centralized so every hit in the game feels consistent and is tuned in one place.

@export var fx_layer: Node2D


func _ready() -> void:
	EventBus.damage_applied.connect(_on_damage_applied)
	EventBus.item_collected.connect(_on_item_collected)
	EventBus.member_leveled_up.connect(_on_leveled)


func _on_damage_applied(target: Node2D, info: DamageInfo) -> void:
	var on_party := target is PartyMember
	var cfg := Registry.combat_config
	HitstopService.request(info.hitstop * (1.4 if info.is_crit else 1.0))
	var shake := info.shake * (cfg.shake_scale_when_party_hit if on_party else 1.0)
	if shake > 0.0:
		EventBus.camera_shake_requested.emit(shake)
	var at := target.global_position + Vector2(0, -12)
	Fx.damage_number(fx_layer, at, info.final_amount, info.is_crit, on_party)
	var spark_color := Color(1, 0.4, 0.4) if on_party else Color(1, 0.95, 0.7)
	Fx.spark(fx_layer, at, info.direction, spark_color, 10 if info.is_crit else 6)
	if on_party:
		AudioService.play_sfx(&"hurt")
	elif info.is_crit:
		AudioService.play_sfx(&"crit")
	else:
		AudioService.play_sfx(&"hit_heavy" if info.power >= 1.5 else &"hit")


func _on_item_collected(item_id: StringName, count: int) -> void:
	var item := Registry.item(item_id)
	var item_name := item.display_name if item != null else String(item_id)
	EventBus.toast_requested.emit(tr("TOAST_ITEM") % [count, item_name])


func _on_leveled(character_id: StringName, level: int) -> void:
	var def := Registry.character(character_id)
	var who := def.display_name if def != null else String(character_id)
	AudioService.play_sfx(&"level_up", 0.0)
	EventBus.toast_requested.emit(tr("TOAST_LEVEL_UP") % [who, level])
