class_name CombatConfig
extends Resource
## Global combat tuning. Instance: res://data/config/combat_config.tres

@export var def_scale: float = 20.0
@export_range(0.0, 0.5) var variance: float = 0.1
@export_range(0.0, 1.0) var crit_chance: float = 0.05
@export var crit_multiplier: float = 1.5
@export var min_damage: int = 1
## Seconds of invulnerability after a party member takes a hit.
@export var party_hit_iframes: float = 0.35
## Seconds a downed party member stays down before getting back up.
@export var downed_duration: float = 10.0
@export_range(0.0, 1.0) var revive_hp_ratio: float = 0.3
@export var switch_cooldown: float = 1.0
## Camera shake multiplier when the party is the one getting hit.
@export var shake_scale_when_party_hit: float = 1.6
