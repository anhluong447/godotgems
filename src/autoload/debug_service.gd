extends Node
## Debug command registry + shared debug toggles. Systems register their own
## commands (e.g. PartyManager registers `heal`), so this stays generic.
## A command is a Callable taking PackedStringArray args and returning a String.

signal output(text: String)
signal hitboxes_toggled(visible: bool)

var enabled: bool = OS.is_debug_build()
var show_hitboxes: bool = false:
	set(value):
		show_hitboxes = value
		hitboxes_toggled.emit(value)
var god_mode: bool = false

var _commands: Dictionary[String, Dictionary] = {}
## Scripted automation from the command line (debug builds only), keyed by frame:
##   -- --exec=60:spawn wolf 2;god  --press=120:attack:0.1,140:skill_1
##      --shots=180:user://a.png,240:user://b.png  --quit-at=300
var _timeline: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if enabled:
		_parse_automation(OS.get_cmdline_user_args())
	register("help", _cmd_help, "List commands")
	register("timescale", _cmd_timescale, "Set game speed", "<value>")
	register("hitboxes", _cmd_hitboxes, "Toggle hitbox/hurtbox drawing")
	register("god", _cmd_god, "Toggle party invulnerability")
	register("palette", _cmd_palette, "Switch world palette", "<xuan|thuc|none>")


func register(command_name: String, callable: Callable, help: String = "", usage: String = "") -> void:
	_commands[command_name] = {"callable": callable, "help": help, "usage": usage}


func unregister(command_name: String) -> void:
	_commands.erase(command_name)


func has_command(command_name: String) -> bool:
	return _commands.has(command_name)


func execute(line: String) -> String:
	var tokens := CommandLine.tokenize(line)
	if tokens.is_empty():
		return ""
	var command_name := tokens[0].to_lower()
	if not _commands.has(command_name):
		return _emit("Unknown command '%s'. Type 'help'." % command_name)
	var callable: Callable = _commands[command_name]["callable"]
	if not callable.is_valid():
		_commands.erase(command_name)
		return _emit("Command '%s' is no longer available." % command_name)
	var result: Variant = callable.call(tokens.slice(1))
	return _emit(str(result) if result != null else "")


func log_line(text: String) -> void:
	_emit(text)


func _emit(text: String) -> String:
	if not text.is_empty():
		output.emit(text)
	return text


func _process(_delta: float) -> void:
	if _timeline.is_empty():
		return
	var frame := Engine.get_process_frames()
	while not _timeline.is_empty() and int(_timeline[0]["frame"]) <= frame:
		var ev: Dictionary = _timeline.pop_front()
		match String(ev["type"]):
			"exec":
				for line: String in String(ev["value"]).split(";", false):
					execute(line)
			"press":
				# Real input events, so event-driven handlers see them like a key press.
				var action := StringName(ev["value"])
				_send_action(action, true)
				get_tree().create_timer(float(ev.get("hold", 0.05)), true, false, true).timeout.connect(
					_send_action.bind(action, false))
			"shot":
				var img := get_viewport().get_texture().get_image()
				img.save_png(String(ev["value"]))
				print("screenshot: ", ProjectSettings.globalize_path(String(ev["value"])))
			"quit":
				get_tree().quit()


func _send_action(action: StringName, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)


func _parse_automation(args: PackedStringArray) -> void:
	for arg: String in args:
		var eq := arg.find("=")
		if eq < 0:
			continue
		var key := arg.substr(0, eq)
		var value := arg.substr(eq + 1)
		match key:
			"--exec":
				var sep := value.find(":")
				_timeline.append({"frame": value.substr(0, sep).to_int(), "type": "exec", "value": value.substr(sep + 1)})
			"--press":
				for item: String in value.split(",", false):
					var parts := item.split(":")
					_timeline.append({"frame": parts[0].to_int(), "type": "press", "value": parts[1],
						"hold": parts[2].to_float() if parts.size() > 2 else 0.05})
			"--shots":
				for item: String in value.split(",", false):
					var sep := item.find(":")
					_timeline.append({"frame": item.substr(0, sep).to_int(), "type": "shot", "value": item.substr(sep + 1)})
			"--quit-at":
				_timeline.append({"frame": value.to_int(), "type": "quit"})
	_timeline.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["frame"]) < int(b["frame"]))


func _cmd_help(_args: PackedStringArray) -> String:
	var names: Array[String] = []
	names.assign(_commands.keys())
	names.sort()
	var lines := PackedStringArray()
	for n: String in names:
		lines.append("  %s %s - %s" % [n, _commands[n]["usage"], _commands[n]["help"]])
	return "\n".join(lines)


func _cmd_timescale(args: PackedStringArray) -> String:
	if args.is_empty():
		return "timescale = %.2f" % HitstopService.base_time_scale
	HitstopService.base_time_scale = args[0].to_float()
	return "timescale = %.2f" % HitstopService.base_time_scale


func _cmd_hitboxes(_args: PackedStringArray) -> String:
	show_hitboxes = not show_hitboxes
	return "hitboxes: %s" % ("on" if show_hitboxes else "off")


func _cmd_god(_args: PackedStringArray) -> String:
	god_mode = not god_mode
	return "god mode: %s" % ("on" if god_mode else "off")


func _cmd_palette(args: PackedStringArray) -> String:
	var preset := StringName(args[0] if not args.is_empty() else "xuan")
	EventBus.palette_requested.emit(preset)
	return "palette: %s" % preset
