extends CanvasLayer
## Moves the game between maps with a fade. The actual swap is done by a
## registered host (MapHost in the main scene), so the router stays tiny and
## the party can persist across maps.

signal transition_started(map_path: String)
signal transition_finished(map_path: String)

const FADE_TIME := 0.25
const TITLE_SCENE := "res://src/ui/menus/title_screen.tscn"
const GAME_SCENE := "res://src/main.tscn"

var is_busy: bool = false
var _host: Node = null
## [map_path, spawn_id, fade_time] requested while busy.
var _queued: Array = []
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


## Swap the whole scene (title <-> game). Resets transient global state.
func change_scene(scene_path: String, fade_time: float = FADE_TIME) -> void:
	if is_busy:
		return
	is_busy = true
	InputGate.acquire(&"transition")
	await fade_to(1.0, fade_time)
	get_tree().paused = false
	HitstopService.clear()
	_host = null
	_queued = []
	# Locks owned by the old scene (dialogue, console...) die with it.
	for reason: StringName in InputGate.reasons():
		InputGate.release(reason)
	get_tree().change_scene_to_file(scene_path)
	# Free the router before the new scene's _ready so it can start a map transition.
	is_busy = false
	await get_tree().process_frame
	await get_tree().process_frame
	# Fade in, unless the new scene started its own transition (which fades in itself).
	if not is_busy:
		await fade_to(0.0, fade_time)


## Requests made during a transition are not dropped: the latest one runs right after.
func change_map(map_path: String, spawn_id: StringName = &"", fade_time: float = FADE_TIME) -> void:
	if not is_instance_valid(_host):
		return
	if is_busy:
		_queued = [map_path, spawn_id, fade_time]
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
	if not _queued.is_empty():
		var next := _queued
		_queued = []
		change_map(next[0], next[1], next[2])


func fade_to(alpha: float, duration: float) -> void:
	if duration <= 0.0:
		_fade.color.a = alpha
		return
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, duration)
	await tween.finished
