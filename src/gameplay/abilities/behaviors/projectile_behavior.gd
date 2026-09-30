class_name ProjectileBehavior
extends AbilityBehavior
## Fires `projectile_count` projectiles spread over `spread_degrees`.

const PROJECTILE_SCENE := preload("res://src/gameplay/projectiles/projectile.tscn")
const MUZZLE_DISTANCE := 10.0
## Projectiles fly at chest height, not at the feet.
const MUZZLE_HEIGHT := -12.0


func on_windup_start(ctx: AbilityContext) -> void:
	if ctx.def.show_telegraph:
		ctx.actor.flash.flash(Color(1, 0.4, 0.3), maxf(ctx.def.windup, 0.05))


func on_active_start(ctx: AbilityContext) -> void:
	var def := ctx.def
	if def.projectile == null:
		push_error("Ability %s has no projectile" % def.id)
		return
	var count := maxi(def.projectile_count, 1)
	var spread := deg_to_rad(def.spread_degrees)
	for i: int in count:
		var t := 0.0 if count == 1 else float(i) / float(count - 1) - 0.5
		var dir := ctx.aim.rotated(spread * t)
		var projectile := PROJECTILE_SCENE.instantiate() as Projectile
		ctx.spawn_parent().add_child(projectile)
		projectile.global_position = ctx.actor.global_position + dir * MUZZLE_DISTANCE
		projectile.launch(def.projectile, ctx.make_damage(), ctx.actor.faction, dir, MUZZLE_HEIGHT)
	ctx.actor.visual.pop(Vector2(0.9, 1.1), 0.08)
