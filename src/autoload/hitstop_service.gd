extends Node
## Freeze-frame on impact. Overlapping requests extend the freeze instead of stacking.
## Runs in real time (process_mode ALWAYS, wall clock) so it can never get stuck slowed.

const FROZEN_SCALE := 0.03

## Normal game speed; the debug `timescale` command changes this.
var base_time_scale: float = 1.0:
	set(value):
		base_time_scale = maxf(value, 0.01)
		if not _frozen:
			Engine.time_scale = base_time_scale
var enabled: bool = true
var _end_usec: int = 0
var _frozen: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func request(duration: float) -> void:
	if not enabled or duration <= 0.0:
		return
	var end := Time.get_ticks_usec() + int(duration * 1_000_000.0)
	if end <= _end_usec:
		return
	_end_usec = end
	_frozen = true
	Engine.time_scale = FROZEN_SCALE * base_time_scale


func is_active() -> bool:
	return _frozen


## Ends any freeze immediately (map transitions, tests).
func clear() -> void:
	_end_usec = 0
	_frozen = false
	Engine.time_scale = base_time_scale


func _process(_delta: float) -> void:
	if _frozen and Time.get_ticks_usec() >= _end_usec:
		_frozen = false
		Engine.time_scale = base_time_scale
