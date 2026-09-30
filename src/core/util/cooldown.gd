class_name Cooldown
extends RefCounted
## Pure countdown timer. Tick it manually so it respects game time (hitstop, pause).

var duration: float
var remaining: float = 0.0


func _init(p_duration: float = 0.0) -> void:
	duration = maxf(p_duration, 0.0)


func start(override_duration: float = -1.0) -> void:
	remaining = duration if override_duration < 0.0 else override_duration


func tick(delta: float) -> void:
	remaining = maxf(remaining - delta, 0.0)


func reset() -> void:
	remaining = 0.0


func is_ready() -> bool:
	return remaining <= 0.0


## 0.0 = ready, 1.0 = just started.
func ratio() -> float:
	if duration <= 0.0:
		return 0.0
	return clampf(remaining / duration, 0.0, 1.0)
