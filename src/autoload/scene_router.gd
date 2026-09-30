extends CanvasLayer
## Moves the game between maps with a fade. The actual swap is done by a
## registered host (MapHost in the main scene), so the router stays tiny and
## the party can persist across maps.

signal transition_started(map_path: String)
signal transition_finished(map_path: String)

const FADE_TIME := 0.25

var is_busy: bool = false
var _host: Node = null
var _fade: ColorRect


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color(0.02, 0.02, 0.03, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


## `host` must implement: load_map(path: String, spawn_id: StringName) -> void
func register_host(host: Node) -> void:
	assert(host.has_method("load_map"), "Map host must implement load_map()")
	_host = host


func change_map(map_path: String, spawn_id: StringName = &"", fade_time: float = FADE_TIME) -> void:
	if is_busy or _host == null:
		return
	is_busy = true
	InputGate.acquire(&"transition")
	transition_started.emit(map_path)
	await fade_to(1.0, fade_time)
	_host.load_map(map_path, spawn_id)
	await get_tree().process_frame
	await fade_to(0.0, fade_time)
	InputGate.release(&"transition")
	is_busy = false
	transition_finished.emit(map_path)


func fade_to(alpha: float, duration: float) -> void:
	if duration <= 0.0:
		_fade.color.a = alpha
		return
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, duration)
	await tween.finished
