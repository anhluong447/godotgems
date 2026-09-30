class_name AbilityBehavior
extends Resource
## Strategy for what an ability does. AbilityComponent owns the timeline and calls
## these hooks; subclasses only describe the effect. New mechanic = new subclass.


func on_windup_start(_ctx: AbilityContext) -> void:
	pass


func on_windup_tick(_ctx: AbilityContext, _delta: float) -> void:
	pass


func on_active_start(_ctx: AbilityContext) -> void:
	pass


func on_active_tick(_ctx: AbilityContext, _delta: float) -> void:
	pass


func on_active_end(_ctx: AbilityContext) -> void:
	pass


## Always called last, also when interrupted (stagger, dodge cancel). Clean up here.
func on_end(_ctx: AbilityContext, _interrupted: bool) -> void:
	pass
