class_name ItemDef
extends Resource

enum Kind { MATERIAL, CONSUMABLE, KEY, INSTANT }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var kind: Kind = Kind.MATERIAL
@export var max_stack: int = 99
## HP restored when used (CONSUMABLE) or picked up (INSTANT).
@export var heal_amount: int = 0
@export var icon: Texture2D
@export var color: Color = Color.WHITE
