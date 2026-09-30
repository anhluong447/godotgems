class_name AreaBehavior
extends AbilityBehavior
## Strikes a circle at the target point after a warning (arrow rain, ground slam).
## The strike lives on its own, so it resolves even if the caster moves or dies.

const AREA_SCENE := preload("res://src/gameplay/abilities/area_strike.tscn")


func on_active_start(ctx: AbilityContext) -> void:
	var def := ctx.def
	var origin := ctx.actor.global_position
	var offset := (ctx.target_position - origin).limit_length(def.area_range)
	if offset.length() < 8.0:
		offset = ctx.aim * def.area_range * 0.6
	var strike := AREA_SCENE.instantiate() as AreaStrike
	ctx.spawn_parent().add_child(strike)
	strike.global_position = origin + offset
	strike.start(ctx.make_damage(), ctx.actor.faction, def)
