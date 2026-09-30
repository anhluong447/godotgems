class_name EnemyDef
extends Resource
## An enemy type. A new enemy is usually just a new .tres of this.

@export var id: StringName
@export var display_name: String
## Optional custom scene (must have an Enemy root). Defaults to the generic enemy scene.
@export var scene: PackedScene

@export_group("Stats")
@export var max_hp: float = 30.0
@export var atk: float = 6.0
@export var def: float = 1.0
@export var spd: float = 80.0
@export var poise: float = 20.0
@export var stagger_time: float = 0.35
@export_range(0.0, 1.0) var knockback_resist: float = 0.0

@export_group("AI")
@export var abilities: Array[AbilityDef] = []
@export var aggro_range: float = 150.0
## Gives up the chase when this far from its spawn point.
@export var leash_range: float = 320.0
## 0 = close in for melee; > 0 = try to keep this distance (ranged).
@export var preferred_distance: float = 0.0
@export var recover_time: float = 0.5
@export var wander_radius: float = 48.0
## Stationary enemies (training dummy) never move or attack.
@export var stationary: bool = false
## Health regenerates to full after this many seconds without damage (0 = never).
@export var regen_delay: float = 0.0

@export_group("Rewards")
@export var xp_reward: int = 5
@export var loot: LootTable

@export_group("Visual")
@export var sprite_sheet: Texture2D
@export var body_radius: float = 8.0
@export var color: Color = Color.WHITE


func base_stats() -> Dictionary:
	return {
		StatBlock.MAX_HP: max_hp,
		StatBlock.ATK: atk,
		StatBlock.DEF: def,
		StatBlock.SPD: spd,
		StatBlock.MAX_ENERGY: 0.0,
		StatBlock.ENERGY_REGEN: 0.0,
	}
