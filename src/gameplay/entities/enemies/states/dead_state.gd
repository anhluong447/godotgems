extends EnemyState
## Death: disable interaction, play the effect, free the node.


func enter(_msg: Dictionary) -> void:
	var e := enemy
	e.abilities.interrupt()
	e.movement.stop_immediately()
	e.hurtbox.set_enabled(false)
	e.set_deferred("collision_layer", 0)
	e.set_deferred("collision_mask", 0)
	e.remove_from_group(&"enemies")
	AudioService.play_sfx(&"enemy_die")
	Fx.death_puff(e.get_parent(), e.global_position + Vector2(0, -8), e.def.color)
	var tween := e.create_tween()
	tween.set_parallel(true)
	tween.tween_property(e.visual, "scale", Vector2(1.4, 0.2), 0.25).set_delay(0.08)
	tween.tween_property(e.visual, "modulate:a", 0.0, 0.25).set_delay(0.08)
	tween.chain().tween_callback(e.queue_free)
