class_name MeleeBehavior
extends AbilityBehavior
## Swings, lunges, dashes, charges and spins: enables the actor's hitbox during the
## active phase, optionally moving the actor along the aim.


func on_windup_start(ctx: AbilityContext) -> void:
	var def := ctx.def
	if not def.show_telegraph:
		return
	var indicator: TelegraphIndicator
	if def.hit_radius > 0.0:
		indicator = TelegraphIndicator.circle(ctx.actor, def.hit_radius, def.windup, def.telegraph_color)
	else:
		var travel := def.lunge_speed * def.active_time
		var length := travel + def.hit_size.x
		var start := def.hit_offset - def.hit_size.x * 0.5
		indicator = TelegraphIndicator.rect(ctx.actor, length, def.hit_size.y, start, ctx.aim.angle(), def.windup, def.telegraph_color)
	ctx.data["telegraph"] = indicator


func on_windup_tick(ctx: AbilityContext, _delta: float) -> void:
	var indicator: TelegraphIndicator = ctx.data.get("telegraph")
	if is_instance_valid(indicator) and ctx.def.hit_radius <= 0.0:
		indicator.rotation = ctx.aim.angle()


func on_active_start(ctx: AbilityContext) -> void:
	_free_telegraph(ctx)
	var def := ctx.def
	var hitbox := ctx.hitbox
	if def.hit_radius > 0.0:
		hitbox.set_circle(def.hit_radius)
		hitbox.position = Vector2.ZERO
		hitbox.rotation = 0.0
	else:
		hitbox.set_rect(def.hit_size)
		hitbox.position = ctx.aim * def.hit_offset
		hitbox.rotation = ctx.aim.angle()
	hitbox.activate(ctx.make_damage())
	if def.lunge_speed > 0.0:
		ctx.actor.movement.set_forced(ctx.aim * def.lunge_speed)
	ctx.actor.visual.pop(Vector2(1.15, 0.9), 0.1)
	if def.trail:
		if def.hit_radius > 0.0:
			SlashTrail.ring(ctx.actor, def.hit_radius, def.trail_color)
		else:
			SlashTrail.for_rect(ctx.actor, ctx.aim, def.hit_size, def.hit_offset, def.trail_color, def.trail_flip)
	if def.afterimages:
		ctx.data["afterimage_timer"] = 0.0


func on_active_tick(ctx: AbilityContext, delta: float) -> void:
	if ctx.def.hit_radius <= 0.0:
		ctx.hitbox.position = ctx.aim * ctx.def.hit_offset
	if ctx.def.afterimages:
		var t: float = ctx.data.get("afterimage_timer", 0.0) - delta
		if t <= 0.0:
			Fx.afterimage(ctx.actor.visual)
			t = 0.035
		ctx.data["afterimage_timer"] = t


func on_active_end(ctx: AbilityContext) -> void:
	ctx.hitbox.deactivate()
	ctx.actor.movement.clear_forced()


func on_end(ctx: AbilityContext, _interrupted: bool) -> void:
	_free_telegraph(ctx)
	if ctx.hitbox.active:
		ctx.hitbox.deactivate()
	ctx.actor.movement.clear_forced()


func _free_telegraph(ctx: AbilityContext) -> void:
	var indicator: TelegraphIndicator = ctx.data.get("telegraph")
	if is_instance_valid(indicator):
		indicator.queue_free()
	ctx.data.erase("telegraph")
