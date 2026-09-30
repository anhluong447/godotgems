class_name ProjectileDef
extends Resource

@export var speed: float = 300.0
@export var lifetime: float = 1.2
## How many extra targets it passes through (0 = stops at the first hit).
@export var pierce: int = 0
@export var radius: float = 4.0
@export var length: float = 12.0
@export var color: Color = Color.WHITE
@export var texture: Texture2D
## Destroyed when touching world geometry.
@export var collides_with_world: bool = true
