class_name CharacterDef
extends Resource
## A playable party member: stats, growth and ability kit.

@export var id: StringName
@export var display_name: String
@export var role: String

@export_group("Base stats")
@export var max_hp: float = 100.0
@export var atk: float = 10.0
@export var def: float = 3.0
@export var spd: float = 100.0
@export var max_energy: float = 100.0
@export var energy_regen: float = 5.0
@export var poise: float = 20.0

@export_group("Growth per level")
@export var growth: Dictionary[StringName, float] = {&"max_hp": 8.0, &"atk": 1.2, &"def": 0.5}

@export_group("Kit")
@export var combo: Array[AbilityDef] = []
## Combo returns to the first hit if no attack follows within this time.
@export var combo_reset_time: float = 0.6
@export var skill_1: AbilityDef
@export var skill_2: AbilityDef

@export_group("Dodge")
@export var dodge_speed: float = 280.0
@export var dodge_time: float = 0.22
@export var dodge_iframes: float = 0.25
@export var dodge_cooldown: float = 0.45

@export_group("AI (when not controlled)")
## Distance kept from enemies when AI-controlled (0 = melee).
@export var ai_preferred_distance: float = 0.0
@export var ai_engage_range: float = 160.0

@export_group("Visual")
@export var sprite_sheet: Texture2D
@export var color: Color = Color.WHITE


func base_stats() -> Dictionary:
	return {
		StatBlock.MAX_HP: max_hp,
		StatBlock.ATK: atk,
		StatBlock.DEF: def,
		StatBlock.SPD: spd,
		StatBlock.MAX_ENERGY: max_energy,
		StatBlock.ENERGY_REGEN: energy_regen,
	}
