class_name AbilityContext
extends RefCounted
## Runtime data for one use of an ability.

var actor: Actor
var def: AbilityDef
var aim: Vector2 = Vector2.RIGHT
var target_position: Vector2
var hitbox: HitboxComponent
## Scratch space for behaviors (telegraph nodes, counters...).
var data: Dictionary = {}


func make_damage() -> DamageInfo:
	var info := DamageInfo.new()
	info.attacker_atk = actor.get_atk()
	info.power = def.power
	info.knockback = def.knockback
	info.hitstop = def.hitstop
	info.shake = def.shake
	info.poise_damage = def.poise_damage
	info.source = actor
	info.source_faction = actor.faction
	return info


## Where spawned things (projectiles, areas) go: the actor's container, so they are
## y-sorted with the world and freed with the map.
func spawn_parent() -> Node:
	return actor.get_parent()
