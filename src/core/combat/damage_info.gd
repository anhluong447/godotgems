class_name DamageInfo
extends RefCounted
## Everything a hit carries. Created by the attacker, resolved by the defender.

var attacker_atk: float = 0.0
## Multiplier on attacker ATK (ability power).
var power: float = 1.0
var knockback: float = 0.0
var hitstop: float = 0.0
var shake: float = 0.0
var poise_damage: float = 0.0
var direction: Vector2 = Vector2.ZERO
var tags: Array[StringName] = []
## The attacking object (usually an actor node). May be freed; check is_instance_valid.
var source: Object = null
var source_faction: int = 0

# Filled in by the resolver.
var final_amount: int = 0
var is_crit: bool = false


func raw_damage() -> float:
	return attacker_atk * power


func copy() -> DamageInfo:
	var c := DamageInfo.new()
	c.attacker_atk = attacker_atk
	c.power = power
	c.knockback = knockback
	c.hitstop = hitstop
	c.shake = shake
	c.poise_damage = poise_damage
	c.direction = direction
	c.tags = tags.duplicate()
	c.source = source
	c.source_faction = source_faction
	return c
