class_name AbilityDef
extends Resource
## One action with a timeline: windup (telegraph) -> active (hits) -> recovery.
## Shared by the party (combos, skills) and enemies. What happens during the
## active phase is decided by `behavior` (strategy pattern).

@export var id: StringName
@export var display_name: String
@export var behavior: AbilityBehavior

@export_group("Cost")
@export var energy_cost: float = 0.0
@export var cooldown: float = 0.0

@export_group("Timeline")
@export var windup: float = 0.1
@export var active_time: float = 0.1
@export var recovery: float = 0.2
## Seconds from start after which another action may cancel this one. 0 = only during recovery.
@export var cancel_from: float = 0.0
## Speed toward aim during the active phase (lunges, dashes, charges).
@export var lunge_speed: float = 0.0
## Movement allowed during windup (0 = rooted, 1 = full speed).
@export_range(0.0, 1.0) var windup_move_factor: float = 0.0
@export var grants_iframes: bool = false
## Keep turning toward the target during windup (enemy tracking).
@export var track_during_windup: bool = true

@export_group("Hit")
@export var power: float = 1.0
@export var knockback: float = 100.0
@export var hitstop: float = 0.04
@export var shake: float = 0.1
@export var poise_damage: float = 10.0
## Rectangle hitbox: x = length along aim, y = width. Ignored when hit_radius > 0.
@export var hit_size: Vector2 = Vector2(24, 20)
## Distance from the actor to the hitbox center along aim.
@export var hit_offset: float = 16.0
## If > 0, the hitbox is a circle of this radius centered on the actor (spin attacks).
@export var hit_radius: float = 0.0

@export_group("Presentation")
@export var show_telegraph: bool = false
@export var telegraph_color: Color = Color(1, 0.2, 0.2, 0.45)
@export var sfx_start: StringName
@export var sfx_active: StringName = &"swing"
@export var afterimages: bool = false
## Melee only: draw a swoosh over the hit area.
@export var trail: bool = false
@export var trail_color: Color = Color(0.85, 0.95, 1.0, 0.9)
## Swing from the other side (alternate combo hits).
@export var trail_flip: bool = false

@export_group("Projectile")
@export var projectile: ProjectileDef
@export var projectile_count: int = 1
@export var spread_degrees: float = 0.0

@export_group("Area")
## Max distance from the actor to the strike point.
@export var area_range: float = 140.0
@export var area_radius: float = 44.0
## Warning time before the first tick.
@export var area_delay: float = 0.4
@export var area_ticks: int = 1
@export var area_interval: float = 0.2

@export_group("AI")
## The AI uses this ability when its target is within this distance.
@export var ai_range: float = 32.0


func total_time() -> float:
	return windup + active_time + recovery
